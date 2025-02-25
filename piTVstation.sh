#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#         _ _______     __   _        _   _             
#   _ __ (_)_   _\ \   / /__| |_ __ _| |_(_) ___  _ __  
#  | '_ \| | | |  \ \ / / __| __/ _` | __| |/ _ \| '_ \ 
#  | |_) | | | |   \ V /\__ \ || (_| | |_| | (_) | | | |
#  | .__/|_| |_|    \_/ |___/\__\__,_|\__|_|\___/|_| |_|
#  |_|
#                                         version 25.2.0
# 
# Author       : Jonathan Vega
# Dependencies : cvlc, mediainfo
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variables that you should change to setup how you like  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# How many commercials should play before resuming playback
amount_commercials=3

# Adjust to how your speakers are configure (in my case, my tv is mono, so 0)
# options are :0=mono, 1=stereo, 2=reverse stereo, 3=left, 4=right, 5=dolby surround, 6=headphones
audio_mode="--stereo-mode=0"

# Leave empty for no cropping or change to 4:3 or 16:9 (--crop=4:3)
crop_video="--crop=4:3"

# -----------------------------------------------------------------------------

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#  !!! ADVANCE - ONLY ALTER BELOW IF YOU KNOW WHAT YOU'RE DOING !!! #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Some videos can be very loud or quiet, so adjust below variable to set desired level
# Value can be number from 1 to 24, put a hash mark (#) to disable
audio_compressor_gain_filter="--audio-filter=compressor --compressor-rms-peak=0.00 --compressor-attack=24.00 --compressor-release=250.00 --compressor-threshold=-25.00 --compressor-ratio=2.00 --compressor-knee=4.50 --compressor-makeup-gain=12.0"

# Grabbing Videos
#---------------------------------------------
video_directory="/home/$USER/piTVstation/videos"
commercial_directory="/home/$USER/piTVstation/commercials"

# check if directory string is empty or if directory exists
if [[ -z "$video_directory" || -z "$commercial_directory" || ! -d "$video_directory" || ! -d "$commercial_directory" ]]; then
	echo "INVALID VIDEO AND COMMERCIAL DIRECTORY STRUCTURE"
	exit 1
fi

# this is needed since glob pattern expands to an empty string and creates *[^.txt] when directory is empty
if [ "$(ls -A "$video_directory")" ]; then
    # array of videos and subdirectories that ignore .txt files
	video_files=("$video_directory"/*[^.txt])
fi

if [ "$(ls -A "$commercial_directory")" ]; then
	# array of all files in commercial directory
	commercial_files=("$commercial_directory"/*)
fi

# check to see if any videos and quit if no videos found
if [ ${#video_files[@]} -eq 0 ]; then
	echo "NO VIDEOS IN DIRECTORY - PLEASE ADD VIDEOS AND TRY AGAIN"
	exit 1
fi

# Generate Stopmarks (run external script)
# --------------------------------------------
bash /home/$USER/piTVstation/scripts/./createStopmarks.sh

# Hide Terminal Text
# --------------------------------------------
sudo sh -c "TERM=linux setterm -foreground black -clear all >/dev/tty0"

# Start Playback
# --------------------------------------------

cvlc_base_command='cvlc --play-and-exit --quiet --no-osd --no-spu'

while [ 1 ]
do
	# use octal to read 2 bytes of data as signed integer from urandom without memory address
	# then get the length of the video_files array
	random_video_index=$(od -An -N2 -i /dev/urandom | awk -v len=${#video_files[@]} '{print $1 % len}')
	resume_time=""

	echo "playing: ${video_files[$random_video_index]}"

	while ifs= read -r line; do
    	if [ ! -z resume_time ]; then #if resume_time string is not empty - so if I know where to resume at
    		$cvlc_base_command $audio_compressor_gain_filter $audio_mode $crop_video --start-time=$resume_time --stop-time=$line "${video_files[$random_video_index]}"
		else
			# resume_time is empty, so play file from the beginning until resume time is found from video txt file
			$cvlc_base_command $audio_compressor_gain_filter $audio_mode $crop_video --run-time=$line "${video_files[$random_video_index]}"
		fi
		
		# check to see if any commercials exist and ignore if no videos found
		if [ ! ${#commercial_files[@]} -eq 0 ]; then
			# loop and play n amount of commercials
			for i in $(seq 1 $amount_commercials); do
				random_commercial_index=$(od -An -N2 -i /dev/urandom | awk -v len=${#commercial_files[@]} '{print $1 % len}')
				$cvlc_base_command $audio_compressor_gain_filter $audio_mode $crop_video "${commercial_files[$random_commercial_index]}";
			done
		fi
    
		resume_time=$line
	# removes the extension for the currently playing video and grabs episode's txt file
	done < "${video_files[$random_video_index]%.*}.txt"
done

# unhide text on the display you're connected to
sudo sh -c "TERM=linux setterm -foreground white -clear all >/dev/tty0"
