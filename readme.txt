Prerequisites:
1. The user needs to be inside docker
2. The folder structure needs to be similar to the following
> PARENT FOLDER
        >>BUILD 1
        >>BUILD 2
        >>ffmpeg_scaler_cli_check

The script "autoscript.sh" takes in the following inputs:
./<script_name>  <ffmpeg_old_env_exe_Path > <ffmpeg_new_env_exe-path> <yuv_8bit_path> <yuv_8bit_res> <yuv_8bit_fmt> <yuv_10bit_path> <yuv_10bit_res> <yuv_10bit_fmt> <h264_8bit_path> <h264_10bit_path>

It calls the script "run_ffmpeg_commands.sh"  with ffmpeg_old_env_exe_Path  and ffmpeg_new_env_exe-path that are passed and generates outputs for each and compares the md5sums

Example command:
./autoscript.sh /home/mapped/git/ma35/build/_deps/ffmpeg-build/ffmpeg /home/mapped/git/ma35_2/build/_deps/ffmpeg-build/ffmpeg /home/mapped/git/sources/bbb_sunflower_144p_30fps_normal_10frames.yuv 192x144 yuv420p /home/mapped/git/sources/bbb_sunflower_1080p_30fps_normal_10frames.yuv 1920x1080 yuv420p10le bbb_sunflower_1440p_60fps_normal.mp4 bbb_sunflower_2160p_60fps_normal_10bit.mp4 
