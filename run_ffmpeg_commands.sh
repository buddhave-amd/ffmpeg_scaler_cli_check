#echo "$#"
#echo "$@"
if [ $# != 10 ]
then
  echo "<exe_name> <ffmpeg exe path>  <output_folder_path> <yuv_8bit_path> <yuv_8bit_res> <yuv_8bit_fmt> <yuv_10bit_path> <yuv_10bit_res> <yuv_10bit_fmt> <h264_8bit_path> <h264_10_bit_path>"
  exit
fi


FFMPEG_EXE=$1
OUT_FOLDER=$2
YUV_8BIT_PATH=$3
YUV_8BIT_RES=$4
YUV_8BIT_FMT=$5
YUV_10BIT_PATH=$6
YUV_10BIT_RES=$7
YUV_10BIT_FMT=$8
H264_8BIT_PATH=$9
H264_10BIT_PATH=${10}

FFMPEG="$FFMPEG_EXE -hide_banner -y -init_hw_device ama=dev0:/dev/transcoder0,vpeloglevel=3 -vsync 0"
YUV_INPUT1="-s $YUV_8BIT_RES -pix_fmt $YUV_8BIT_FMT -i $YUV_8BIT_PATH"
h264_INPUT1=$H264_8BIT_PATH
h264_INPUT2_10BIT=$H264_10BIT_PATH
YUV_INPUT2_10BIT="-s $YUV_10BIT_RES -pix_fmt $YUV_10BIT_FMT -i $YUV_10BIT_PATH"

#PRECHECK
#out folder
if  [ ! -d $OUT_FOLDER ]
then
  echo "Output folder $OUT_FOLDER doesnot exist"
  echo "creating out folder"
  mkdir $OUT_FOLDER
  fi
#yuv 8 bit input path
if [ ! -f $YUV_8BIT_PATH ]
then
  echo "8 bit yuv $YUV_8BIT_PATH doesnot exist"
  exit
fi

#yuv 10 bit input path
if [ ! -f $YUV_10BIT_PATH ]
then
  echo "10 bit yuv $YUV_10BIT_PATH doesnot exist"
  exit
fi

#h264 8 bit input path
if [ ! -f $H264_8BIT_PATH ]
then
  echo "8 bit h264 $H264_8BIT_PATH doesnot exist"
  exit
fi

#h264 10 bit input path
if [ ! -f $H264_10BIT_PATH ]
then
  echo "10 bit h264 $H264_10BIT_PATH doesnot exist"
  exit
fi

#yuv 8 bit input fmt
if [ "$YUV_8BIT_FMT" != "nv12" ] && [ "$YUV_8BIT_FMT" != "yuv420p" ] 
then  
  echo " 8 bit yuv input format:"$YUV_8BIT_FMT" should be either yuv420p or nv12"
  exit
fi

#yuv 10 bit input fmt
if [ "$YUV_10BIT_FMT" != "p010le" ] && [ "$YUV_10BIT_FMT" != "yuv420p10le" ]
then
  echo " 10 bit yuv input format:"$YUV_10BIT_FMT" should be either yuv420p10le or p010le"
  exit
fi


set -x

#1. h264 i/p -->(sw decode)--> hwupload-->scaler-->hwdownload-->2 yuv op
${FFMPEG} -i ${h264_INPUT1} -filter_complex "hwupload[in];[in]scaler_ma=outputs=2:out_res=(1280x720|nv12)(1280x720|nv12)[a][b];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=nv12[b1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/01_op1_nv12_BigBukBunny_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/01_op2_nv12_BigBukBunny_1280x720.yuv

#2. h264 -->(hw decode)--> -->scaler(some setting)-->hwdownload-->2 yuv op
${FFMPEG} -c:v h264_ama -i ${h264_INPUT1} -filter_complex "scaler_ma=outputs=2:out_res=(1280x720|nv12)(1280x720|nv12)[a][b];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=nv12[b1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/02_op1_nv12_BigBukBunny_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/02_op2_nv12_BigBukBunny_1280x720.yuv

#3. yuv i/p --> hw upload--> scaler(single nv12 format)--> hwdownload-->4 yuv
${FFMPEG} ${YUV_INPUT1} -filter_complex "hwupload[in];[in]scaler_ma=outputs=4:out_res=(1280x720|nv12)(1280x720|nv12)(1280x720|nv12)(1280x720|nv12)[a][b][c][d];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=nv12[b1];[c]hwdownload,format=nv12[c1];[d]hwdownload,format=nv12[d1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/03_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/03_op2_nv12_people_four_people_1280x720.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/03_op3_nv12_people_four_people_1280x720.yuv -map "[d1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/03_op4_nv12_people_four_people_1280x720.yuv

#4. yuv i/p --> hw upload--> scaler(mixed formats-nv12, nv12, rgbp, yuv420p)--> hwdownload-->4 yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_complex "hwupload[in];[in]scaler_ma=outputs=4:out_res=(1280x720|nv12)(1280x720|nv12)(1280x720|yuv420p)(1280x720|rgbp)[a][b][c][d];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=nv12[b1];[c]hwdownload,format=yuv420p[c1];[d]hwdownload,format=rgbp[d1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/04_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/04_op2_nv12_four_people_1280x720.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt yuv420p ${OUT_FOLDER}/04_op3_yuv420p_four_people_1280x720.yuv -map "[d1]" -vframes 10 -f rawvideo -pix_fmt rgbp ${OUT_FOLDER}/04_op4_rgbp_four_people_1280x720.yuv

#5. yuv i/p --> hw upload--> scaler(mixed formats ,single video standards)--> hwdownload-->4 yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_complex "hwupload[in];[in]scaler_ma=outputs=4:out_res=(1280x720|nv12|bt601)(1280x720|nv12|bt601)(1280x720|yuv420p|bt601)(1280x720|rgbp|bt601)[a][b][c][d];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=nv12[b1];[c]hwdownload,format=yuv420p[c1];[d]hwdownload,format=rgbp[d1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/05_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/05_op2_nv12_four_people_1280x720.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt yuv420p ${OUT_FOLDER}/05_op3_yuv420p_four_people_1280x720.yuv -map "[d1]" -vframes 10 -f rawvideo -pix_fmt rgbp ${OUT_FOLDER}/05_op4_rgbp_four_people_1280x720.yuv

#6. yuv i/p --> hw upload--> scaler(mixed formats ,mixed video standards)--> hwdownload-->4 yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_complex "hwupload[in];[in]scaler_ma=outputs=4:out_res=(1280x720|nv12|bt601)(1280x720|nv12|bt709)(1280x720|yuv420p|bt601)(1280x720|rgbp|bt2020)[a][b][c][d];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=nv12[b1];[c]hwdownload,format=yuv420p[c1];[d]hwdownload,format=rgbp[d1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/06_op1_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/06_op2_four_people_1280x720.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt yuv420p ${OUT_FOLDER}/06_op3_four_people_1280x720.yuv -map "[d1]" -vframes 10 -f rawvideo -pix_fmt rgbp ${OUT_FOLDER}/06_op4_four_people_1280x720.yuv

#7. yuv i/p --> hwdownload-->scaler(mixed res,mixed fmt+mixed rate+crop)--> hwdownload--> 4yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_complex "hwupload[in];[in]scaler_ma=outputs=4:crop=1600|900|100|100:out_res=(1280x720|nv12|full)(960x540|yuv420p|full)(640x360|rgbp|half)(320x180|nv12|half)[a][b][c][d];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=yuv420p[b1];[c]hwdownload,format=rgbp[c1];[d]hwdownload,format=nv12[d1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/07_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt yuv420p ${OUT_FOLDER}/07_op2_yuv420p_four_people_960x540.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt rgbp ${OUT_FOLDER}/07_op3_rgbp_four_people_640x360.yuv -map "[d1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/07_op4_nv12_four_people_320x180.yuv

#8. yuv i/p --> hwdownload-->scaler(mixed res,mixed fmt+crop, no rate)--> hwdownload--> 4yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=4:crop=1600|900|100|100:out_res=(1280x720|nv12)(960x540|yuv420p)(640x360|rgbp)(320x180|nv12)[a][b][c][d];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=yuv420p[b1];[c]hwdownload,format=rgbp[c1];[d]hwdownload,format=nv12[d1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/08_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt yuv420p ${OUT_FOLDER}/08_op2_yuv420p_four_people_960x540.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt rgbp ${OUT_FOLDER}/08_op3_rgbp_four_people_640x360.yuv -map "[d1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/08_op4_nv12_four_people_320x180.yuv

#9. yuv i/p --> hw upload--> scaler(mixed res and format, single rate))--> hwdownload-->4 yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=4:out_res=(1280x720|nv12|full)(960x540|yuv420p|full)(640x360|rgbp|full)(320x180|nv12|full)[a][b][c][d];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=yuv420p[b1];[c]hwdownload,format=rgbp[c1];[d]hwdownload,format=nv12[d1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/09_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt yuv420p ${OUT_FOLDER}/09_op2_yuv420p_four_people_960x540.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt rgbp ${OUT_FOLDER}/09_op3_rgbp_four_people_640x360.yuv -map "[d1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/09_op4_nv12_four_people_320x180.yuv

#10. yuv i/p --> hw upload--> scaler(single res and rate mixed format )--> hwdownload-->4 yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=4:out_res=(1280x720|nv12|full)(1280x720|full|yuv420p)(1280x720|rgbp|full)(1280x720|nv12|full)[a][b][c][d];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=yuv420p[b1];[c]hwdownload,format=rgbp[c1];[d]hwdownload,format=nv12[d1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/10_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt yuv420p ${OUT_FOLDER}/10_op2_yuv420p_four_people_1280x720.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt rgbp ${OUT_FOLDER}/10_op3_rgbp_four_people_1280x720.yuv -map "[d1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/10_op4_nv12_four_people_1280x720.yuv

#11. yuv i/p --> hw upload--> scaler(single res ,rate and format )--> hwdownload-->4 yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=4:out_res=(1280x720|full|nv12)(1280x720|full|nv12)(1280x720|full|nv12)(1280x720|full|nv12)[a][b][c][d];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=nv12[b1];[c]hwdownload,format=nv12[c1];[d]hwdownload,format=nv12[d1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/11_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/11_op2_nv12_four_people_1280x720.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/11_op3_nv12_four_people_1280x720.yuv -map "[d1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/11_op4_nv12_four_people_1280x720.yuv

#12. yuv --> hwupload--> scaler(16 ops-4 *(1280x720)(960x540)(640x360)(320x180)each)-->hwdownlaod-->yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_complex "hwupload[in];[in]scaler_ma=outputs=16:out_res=(1280x720|nv12)(1280x720|nv12)(1280x720|nv12)(1280x720|nv12)(960x540|nv12)(960x540|nv12)(960x540|nv12)(960x540|nv12)(640x360|nv12)(640x360|nv12)(640x360|nv12)(640x360|nv12)(320x180|nv12)(320x180|nv12)(320x180|nv12)(320x180|nv12)[a1][a2][a3][a4][a5][a6][a7][a8][a9][a10][a11][a12][a13][a14][a15][a16];[a1]hwdownload,format=nv12[b1];[a2]hwdownload,format=nv12[b2];[a3]hwdownload,format=nv12[b3];[a4]hwdownload,format=nv12[b4];[a5]hwdownload,format=nv12[b5];[a6]hwdownload,format=nv12[b6];[a7]hwdownload,format=nv12[b7];[a8]hwdownload,format=nv12[b8];[a9]hwdownload,format=nv12[b9];[a10]hwdownload,format=nv12[b10];[a11]hwdownload,format=nv12[b11];[a12]hwdownload,format=nv12[b12];[a13]hwdownload,format=nv12[b13];[a14]hwdownload,format=nv12[b14];[a15]hwdownload,format=nv12[b15];[a16]hwdownload,format=nv12[b16]" -map ""[b1]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op1_nv12_four_people_1280x720.yuv -map ""[b2]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op2_nv12_four_people_1280x720.yuv -map ""[b3]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op3_nv12_four_people_1280x720.yuv -map ""[b4]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op4_nv12_four_people_1280x720.yuv -map ""[b5]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op5_nv12_four_people_960x540.yuv -map ""[b6]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op6_nv12_four_people_960x540.yuv -map ""[b7]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op7_nv12_four_people_960x540.yuv -map ""[b8]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op8_nv12_four_people_960x540.yuv -map ""[b9]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op9_nv12_four_people_640x360.yuv -map ""[b10]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op10_nv12_four__people_640x360.yuv -map ""[b11]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op11_nv12_four_people_640x360.yuv -map ""[b12]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op12_nv12_four_people_640x360.yuv -map ""[b13]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op13_nv12_four_people_320x180.yuv -map ""[b14]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op14_nv12_four_people_320x180.yuv -map ""[b15]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op15_nv12_four_people_320x180.yuv -map ""[b16]"" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/12_op16_nv12_four_people_320x180.yuv

#13 yuv(8 bit)--> hwupload-->scaler1(1 output)-->scaler2(2 outputs-nv12)-->hwdownload-->yuv
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=1:out_res=(1280x720)[a];[a]scaler_ma=outputs=2:out_res=(1280x720|nv12)(1280x720|nv12)[b][c];[b]hwdownload,format=nv12[b1];[c]hwdownload,format=nv12[c1]" -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/13_op1_nv12_four_people_1280x720.yuv -map "[c1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/13_op2_four_people_1280x720.yuv

#14. yuv(8 bit)--> hwupload-->scaler-->hwdownload-->yuv(2 10-bit op p010le)
${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=2:out_res=(1280x720|p010le)(1280x720|p010le)[a][b];[a]hwdownload,format=p010le[a1];[b]hwdownload,format=p010le[b1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt p010le ${OUT_FOLDER}/14_op1_p010le_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt p010le ${OUT_FOLDER}/14_op2_p010le_four_people_1280x720.yuv

#15 yuv(8 bit)--> hwupload-->scaler(packet10)-->av1
#Currently issue with av1
#${FFMPEG} -vsync 0 ${YUV_INPUT1} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=2:out_res=(1280x720|packed10)(1280x720|packed10)[a][b]" -map "[a]" -vframes 10 -c:v snav1enc -xav1-params *qp=35,aq-enable=false -f rawvideo ${OUT_FOLDER}/15_op1_packet10_four_people_1280x720.av1 -map "[b]" -vframes 10 -c:v snav1enc -xav1-params *qp=35,aq-enable=false -f rawvideo ${OUT_FOLDER}/15_op2_packet10_four_people_1280x720.av1

#16. h264(10 bit) i/p -->(sw decode)--> hwupload-->scaler-->hwdownload-->2 yuv op(8 bit nv12)
${FFMPEG} -i ${h264_INPUT2_10BIT} -filter_complex "hwupload[in];[in]scaler_ma=outputs=2:out_res=(1280x720|nv12)(1280x720|nv12)[a][b];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=nv12[b1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/16_op1_nv12_BigBukBunny_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/16_op2_nv12_BigBukBunny_1280x720.yuv

#17. h264(10 bit) i/p -->(sw decode)--> hwupload-->scaler-->hwdownload-->2 yuv op(10 bit p010le)
${FFMPEG} -i ${h264_INPUT2_10BIT} -filter_complex "hwupload[in];[in]scaler_ma=outputs=2:out_res=(1280x720|p010le)(1280x720|p010le)[a][b];[a]hwdownload,format=p010le[a1];[b]hwdownload,format=p010le[b1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt p010le ${OUT_FOLDER}/17_op1_p010le_BigBukBunny_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt p010le ${OUT_FOLDER}/17_op2_p010le_BigBukBunny_1280x720.yuv

#18 yuv(10 bit)--> hwupload-->scaler(p010le with p010le)-->hwdownload-->2 yuv(nv12 8-bit op)
${FFMPEG} -vsync 0 ${YUV_INPUT2_10BIT} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=2:out_res=(1280x720|nv12)(1280x720|nv12)[a][b];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=nv12[b1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/18_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/18_op2_nv12_four_people_1280x720.yuv

#19 yuv(10 bit)--> hwupload-->scaler(p010le with p010le)-->hwdownload-->2 yuv(10-bit p010le op)
${FFMPEG} -vsync 0 ${YUV_INPUT2_10BIT} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=2:out_res=(1280x720|p010le)(1280x720|p010le)[a][b];[a]hwdownload,format=p010le[a1];[b]hwdownload,format=p010le[b1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt p010le ${OUT_FOLDER}/19_op1_p010le_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt p010le ${OUT_FOLDER}/19_op2_p010le_four_people_1280x720.yuv

#20 yuv(10 bit)--> hwupload-->scaler(p010le )-->hwdownload-->2 yuv(8-bit nv12 op)
${FFMPEG} -vsync 0 ${YUV_INPUT2_10BIT} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=2:out_res=(1280x720|nv12)(1280x720|yuv420p)[a][b];[a]hwdownload,format=nv12[a1];[b]hwdownload,format=yuv420p[b1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt nv12 ${OUT_FOLDER}/20_op1_nv12_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt yuv420p ${OUT_FOLDER}/20_op2_yuv420p_four_people_1280x720.yuv

#21 yuv(10 bit p010le)--> hwupload-->scaler -->hwdownload-->2 yuv(10-bit op- yuv420p10le and p010le)
${FFMPEG} -vsync 0 ${YUV_INPUT2_10BIT} -filter_hw_device dev0 -filter_complex "hwupload[in];[in]scaler_ma=outputs=2:out_res=(1280x720|yuv420p10le)(1280x720|p010le)[a][b];[a]hwdownload,format=yuv420p10le[a1];[b]hwdownload,format=p010le[b1]" -map "[a1]" -vframes 10 -f rawvideo -pix_fmt yuv420p10le ${OUT_FOLDER}/21_op1_10bit_yuv420p10le_four_people_1280x720.yuv -map "[b1]" -vframes 10 -f rawvideo -pix_fmt p010le ${OUT_FOLDER}/21_op2_10bit_p010le_four_people_1280x720.yuv

set +x
