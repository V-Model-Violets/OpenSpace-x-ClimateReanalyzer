#!/bin/bash
search_folder_recurse() {
	for i in "$1"/*;do
		filename=$(basename -- "$i")
		extension="${filename##*.}"
		filename="${filename%.*}"
		if [ -d "$i" ];then
			echo "check: $i"

			current_dir=$i
			search_folder_recurse "$i"
		elif [ -f "$i" ] && [ "$extension" == 'webconf' ]; then
			#check to see if we have data file.
			map_path=`echo $current_dir | sed 's:.*/::'`
			data_file_path=$DATA_FOLDER/
			data_file_path+=$map_path/
			data_file_name=`grep DataFile $i | sed 's:.*/::'`
			index_file_name=`grep IndexFile $i | sed 's:.*/::'`
			full_data_file=$data_file_path$filename/$data_file_name

			if test -f "$data_file_path$filename/$data_file_name"; then
				#update webconf for local paths
				sed -i "s,DataFile.*.,DataFile $full_data_file,g" $i
				sed -i "s,IndexFile.*.,IndexFile $data_file_path$filename/$index_file_name,g" $i
				#create apache directive
				echo "<Directory $data_file_path$filename>" >> ahtse.conf;
				echo "Options -Indexes -FollowSymLinks -ExecCGI" >> ahtse.conf
				echo "MRF_RegExp */tile/.*" >> ahtse.conf
				echo "MRF_ConfigurationFile $i" >> ahtse.conf
				echo "</Directory>" >> ahtse.conf		    
				echo "Data file found: $data_file_path$data_file_name"
			else
				echo "No data file found for: $data_file_path$data_file_name"
			fi
	    fi
	done
}

#data folder
DATA_FOLDER=/workspaces/OpenSpace-x-ClimateReanalyzer/data;
#reset conf if exists
echo "#ahtse.conf" > ahtse.conf;
#search webconfs and find matches in data folder
SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

echo "search : $SCRIPTPATH/webconf"

search_folder_recurse "$SCRIPTPATH/webconf"
