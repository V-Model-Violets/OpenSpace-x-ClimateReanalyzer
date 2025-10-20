const https = require('https');

const [owner, repo] = process.env.GITHUB_REPOSITORY.split('/');
const issueNumber = process.env.ISSUE_NUMBER;
const closer = process.env.CLOSER;
const closedAt = new Date(process.env.CLOSED_AT);
const token = process.env.GITHUB_TOKEN;

function apiRequest(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.github.com',
      path,
      method,
      headers: {
        'Authorization': `token ${token}`,
        'User-Agent': 'GitHub-Actions',
        'Accept': 'application/vnd.github.v3+json'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function main() {
  const comments = await apiRequest(
    `/repos/${owner}/${repo}/issues/${issueNumber}/comments?per_page=10&sort=created&direction=desc`
  );

  const windowMs = 5 * 60 * 1000;
  const hasRequiredComment = comments.some(c => {
    const byCloser = c.user && c.user.login === closer;
    const t = new Date(c.created_at).getTime();
    const closed = closedAt.getTime();
    return byCloser && Math.abs(t - closed) <= windowMs;
  });

  if (!hasRequiredComment) {
    await apiRequest(`/repos/${owner}/${repo}/issues/${issueNumber}`, 'PATCH', { state: 'open' });
    await apiRequest(`/repos/${owner}/${repo}/issues/${issueNumber}/comments`, 'POST', {
      body: 'Reopened: please leave a brief comment explaining the resolution before closing.'
    });
    console.log('Issue reopened - no qualifying comment found');
    process.exit(1);
  } else {
    console.log('Qualifying comment found. Issue remains closed.');
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});