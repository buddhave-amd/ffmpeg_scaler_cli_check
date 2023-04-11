#echo $#
#echo $@
if [ $# != 10 ]
then
  echo "Please enter in the following format:"
  echo "<./script_name> <ffmpeg_old_env_exe_Path > <ffmpeg_new_env_exe-path> <yuv_8bit_path> <yuv_8bit_res> <yuv_8bit_fmt> <yuv_10bit_path> <yuv_10bit_res> <yuv_10bit_fmt> <h264_8bit_path> <h264_10bit_path> "
  exit
fi	

OLD_FFMPEG_EXE=$1
NEW_FFMPEG_EXE=$2
YUV_8BIT_PATH=$3
YUV_8BIT_RES=$4
YUV_8BIT_FMT=$5
YUV_10BIT_PATH=$6
YUV_10BIT_RES=$7
YUV_10BIT_FMT=$8
H264_8BIT_PATH=$9
H264_10BIT_PATH=${10}

FFMPEG_COMMANDS_SCRIPT="run_ffmpeg_commands.sh"
CURRENT_TIMESTAMP=$(date "+%Y%m%d%H%M%S")
RESULT_FOLDER="results_${CURRENT_TIMESTAMP}"
mkdir ${RESULT_FOLDER}
NEW_ENV_OUTPUT_FOLDER="$RESULT_FOLDER/NEW_ENV_FFMPEG_OUTPUTS"
OLD_ENV_OUTPUT_FOLDER="$RESULT_FOLDER/OLD_ENV_FFMPEG_OUTPUTS"
LOG_FILE=$RESULT_FOLDER/terminal_logs.txt
NEW_ENV_md5=${RESULT_FOLDER}/new_env_md5sum.txt
OLD_ENV_md5=${RESULT_FOLDER}/old_env_md5sum.txt
intermediate_compare_file=${RESULT_FOLDER}/intermediate_log.txt
mkdir $NEW_ENV_OUTPUT_FOLDER
mkdir $OLD_ENV_OUTPUT_FOLDER
touch $LOG_FILE

echo "Running commands with ffmpeg in old environment:" | tee -a ${LOG_FILE} 
./${FFMPEG_COMMANDS_SCRIPT} ${OLD_FFMPEG_EXE} "$OLD_ENV_OUTPUT_FOLDER" ${@:3:${#}-1} 2>&1 | tee -a ${LOG_FILE}
echo "Running commands with ffmpeg in new environment:"  | tee -a ${LOG_FILE}
./${FFMPEG_COMMANDS_SCRIPT} ${NEW_FFMPEG_EXE} "$NEW_ENV_OUTPUT_FOLDER" ${@:3:${#}-1} 2>&1 | tee -a ${LOG_FILE}

#create md5 crc text logs for new and old folders
if [ -z "$(ls -A ${NEW_ENV_OUTPUT_FOLDER})"  ]
then
  echo "No outputs in new environment ffmpeg outputs folder" | tee -a ${LOG_FILE}
  echo "Exiting..." | tee -a ${LOG_FILE} 
  exit
else  
  echo -e "\ncreating md5 sum for New environment ffmpeg Outputs..." | tee -a ${LOG_FILE}
  find ${NEW_ENV_OUTPUT_FOLDER} -type f -exec md5sum {} + | sort -k 2 > ${NEW_ENV_md5}
  echo -e "\nmd5 sum created for New environment Outputs and are as follows:" | tee -a ${LOG_FILE}
  cat ${NEW_ENV_md5} | tee -a ${LOG_FILE}
fi

if [ -z "$(ls -A ${OLD_ENV_OUTPUT_FOLDER})"  ]
then
  echo "No outputs in old environment ffmpeg outputs folder" | tee -a ${LOG_FILE}
  echo "Exiting..." | tee -a ${LOG_FILE}
  exit
else
  echo -e "\ncreating md5 sum for Old Outputs..." | tee -a ${LOG_FILE}
  find ${OLD_ENV_OUTPUT_FOLDER} -type f -exec md5sum {} + | sort -k 2 > ${OLD_ENV_md5}
  echo -e "\nmd5 sum created for Old environment Outputs and are as follows:" | tee -a ${LOG_FILE}
  cat ${OLD_ENV_md5} | tee -a ${LOG_FILE}
fi

#Remove the file paths and find diff between files & their md5 sums
echo -e "\nProcessing the md5 sum files for comparision...\n" | tee -a ${LOG_FILE}

sed -i "s#${NEW_ENV_OUTPUT_FOLDER}/# #g" ${NEW_ENV_md5}
sed -i "s#${OLD_ENV_OUTPUT_FOLDER}/# #g" ${OLD_ENV_md5}

echo -e "md5 sums for New Vs Old environment outputs are as follows..." | tee -a ${LOG_FILE}

diff -y -w ${NEW_ENV_md5} ${OLD_ENV_md5} | tee -a ${LOG_FILE}

#check if the md5 sums of base and new outputs are matching
touch ${intermediate_compare_file}
grep -A 5000 "md5 sums for New Vs Old environment outputs are as follows..." ${LOG_FILE} >> ${intermediate_compare_file}

echo -e "\nChecking for bit exactness of outputs..." | tee -a ${LOG_FILE}
if [ -z $(grep -e "|" -e ">" -e "<" ${intermediate_compare_file}) ] ; then 
	echo -e "\nAll ok. md5 sums are matching" | tee -a ${LOG_FILE}
	echo -e "\nDeleting new outputs..."
	#remove intermediate files and outputs since the new and old results are matching
	rm ${intermediate_compare_file}
	rm ${NEW_ENV_md5}
	rm ${OLD_ENV_md5}
	rm -r ${NEW_ENV_OUTPUT_FOLDER}
	rm -r ${OLD_ENV_OUTPUT_FOLDER}
else
	echo -e "\nResults or md5 sums not matching for new and base outputs" | tee -a ${LOG_FILE}
	echo -e "\nRetaining  outputs, md5 sum and intermediate logs for reference " | tee -a ${LOG_FILE}
fi


echo "completed" | tee -a ${LOG_FILE}
