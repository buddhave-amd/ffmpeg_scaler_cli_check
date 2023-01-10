#Script to generate a fixed set of ffmpeg command outputs for scaler in new format and compare the bit exactness of these new outputs with already existing outputs with scaler commands in old format(Base outputs)
#It is assumed that docker is running during te execution of the script and the folder(scaler_cli_options) is outside the ma35 repo directory 

NEW_COMMANDS_FILE="NewCommands.sh"
CURRENT_TIMESTAMP=$(date "+%Y%m%d%H%M%S")
LOG_FILE="log_${CURRENT_TIMESTAMP}.txt"
touch ${LOG_FILE}

./${NEW_COMMANDS_FILE} 2>&1 | tee -a ${LOG_FILE}

#create md5 crc text logs for new and old folders
echo -e "\ncreating md5 sum for New Outputs..." | tee -a ${LOG_FILE}
find NewOptions_output -type f -exec md5sum {} + | sort -k 2 > NewOptions_md5sum.txt
echo -e "\nmd5 sum created for New Options Outputs and are as follows:" | tee -a ${LOG_FILE}
cat NewOptions_md5sum.txt | tee -a ${LOG_FILE}

echo -e "\ncreating md5 sum for Base Outputs..." | tee -a ${LOG_FILE}
find BaseOptions_output -type f -exec md5sum {} + | sort -k 2 > BaseOptions_md5sum.txt
echo -e "\nmd5 sum created for Base Options Outputs and are as follows:" | tee -a ${LOG_FILE}
cat BaseOptions_md5sum.txt | tee -a ${LOG_FILE}

#Remove the file paths and find diff between files & their md5 sums
echo -e "\nProcessing the md5 sum files for comparision...\n" | tee -a ${LOG_FILE}

sed -i 's#BaseOptions_output/# #g' BaseOptions_md5sum.txt
sed -i 's#NewOptions_output/# #g' NewOptions_md5sum.txt

echo -e "\nmd5 sums for New Vs Base outputs are as follows...\n" | tee -a ${LOG_FILE}

diff -y -w NewOptions_md5sum.txt BaseOptions_md5sum.txt | tee -a ${LOG_FILE}

#check if the md5 sums of base and new outputs are matching
touch intermediate_log.txt
grep -A 5000 "md5 sums for New Vs Base outputs are as follows..." ${LOG_FILE} >> intermediate_log.txt

echo -e "\nChecking for bit exactness of outputs..." | tee -a ${LOG_FILE}
if  grep -e "|" -e ">" -e "<" intermediate_log.txt ; then 
	echo -e "\nResults or md5 sums not matching for new and base outputs" | tee -a ${LOG_FILE}
	echo -e "\nRetaining New outputs, md5 sum and intermediate logs for reference " | tee -a ${LOG_FILE}
else
	echo -e "\nAll ok. md5 sums are matching" | tee -a ${LOG_FILE}
	echo -e "\nDeleting new outputs..."
	#remove intermediate files and outputs from new commands since they match with base outputs
	rm -rf NewOptions_output
	rm intermediate_log.txt
	rm *md5sum.txt
fi


echo "completed" | tee -a ${LOG_FILE}
