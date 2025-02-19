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
AMOUNT_COMMERCIALS=3

# Adjust to how your speakers are configure (in my case, my tv is mono, so 0)
# options are :0=mono, 1=stereo, 2=reverse stereo, 3=left, 4=right, 5=dolby surround, 6=headphones
AUDIO_MODE="--stereo-mode=0"

# Leave empty for no cropping or change to 4:3 or 16:9 (--crop=4:3)
CROP_VIDEO="--crop=4:3"

# -----------------------------------------------------------------------------

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#  !!! ADVANCE - ONLY ALTER BELOW IF YOU KNOW WHAT YOU'RE DOING !!! #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Some videos can be very loud or quiet, so adjust below variable to set desired level
# Value can be number from 1 to 24, put a hash mark (#) to disable
AUDIO_COMPRESSOR_GAIN_FILTER="--audio-filter=compressor --compressor-rms-peak=0.00 --compressor-attack=24.00 --compressor-release=250.00 --compressor-threshold=-25.00 --compressor-ratio=2.00 --compressor-knee=4.50 --compressor-makeup-gain=12.0"

# Grabbing Videos
#---------------------------------------------
VIDEO_DIRECTORY="/home/$USER/piTVstation/videos"
COMMERCIAL_DIRECTORY="/home/$USER/piTVstation/commercials"

# check if directory string is empty or if directory exists
if [[ -z "$VIDEO_DIRECTORY" || -z "$COMMERCIAL_DIRECTORY" || ! -d "$VIDEO_DIRECTORY" || ! -d "$COMMERCIAL_DIRECTORY" ]]; then
	echo "INVALID VIDEO AND COMMERCIAL DIRECTORY STRUCTURE"
	exit 1
fi

# this is needed since glob pattern expands to an empty string and creates *[^.txt] when directory is empty
if [ "$(ls -A "$VIDEO_DIRECTORY")" ]; then
    # array of videos and subdirectories that ignore .txt files
	VIDEO_FILES=("$VIDEO_DIRECTORY"/*[^.txt])
fi

if [ "$(ls -A "$COMMERCIAL_DIRECTORY")" ]; then
	# array of all files in commercial directory
	COMMERCIAL_FILES=("$COMMERCIAL_DIRECTORY"/*)
fi

# check to see if any videos and quit if no videos found
if [ ${#VIDEO_FILES[@]} -eq 0 ]; then
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

CVLC_BASE_COMMAND='cvlc --play-and-exit --quiet --no-osd --no-spu'

while [ 1 ]
do
	# use octal to read 2 bytes of data as signed integer from urandom without memory address
	# then get the length of the VIDEO_FILES array
	RANDOM_VIDEO_INDEX=$(od -An -N2 -i /dev/urandom | awk -v len=${#VIDEO_FILES[@]} '{print $1 % len}')
	RESUME_TIME=""

	echo "playing: ${VIDEO_FILES[$RANDOM_VIDEO_INDEX]}"

	while IFS= read -r LINE; do
    	if [ ! -z RESUME_TIME ]; then #if resume_time string is not empty - so if I know where to resume at
    		$CVLC_BASE_COMMAND $AUDIO_COMPRESSOR_GAIN_FILTER $AUDIO_MODE $CROP_VIDEO --start-time=$RESUME_TIME --stop-time=$LINE "${VIDEO_FILES[$RANDOM_VIDEO_INDEX]}"
		else
			# resume_time is empty, so play file from the beginning until resume time is found from video txt file
			$CVLC_BASE_COMMAND $AUDIO_COMPRESSOR_GAIN_FILTER $AUDIO_MODE $CROP_VIDEO --run-time=$LINE "${VIDEO_FILES[$RANDOM_VIDEO_INDEX]}"
		fi
		
		# check to see if any commercials exist and ignore if no videos found
		if [ ! ${#COMMERCIAL_FILES[@]} -eq 0 ]; then
			# loop and play n amount of commercials
			for i in $(seq 1 $AMOUNT_COMMERCIALS); do
				RANDOM_COMMERCIAL_INDEX=$(od -An -N2 -i /dev/urandom | awk -v len=${#COMMERCIAL_FILES[@]} '{print $1 % len}')
				$CVLC_BASE_COMMAND $AUDIO_COMPRESSOR_GAIN_FILTER $AUDIO_MODE $CROP_VIDEO "${COMMERCIAL_FILES[$RANDOM_COMMERCIAL_INDEX]}";
			done
		fi
    
		RESUME_TIME=$LINE
	# removes the extension for the currently playing video and grabs episode's txt file
	done < "${VIDEO_FILES[$RANDOM_VIDEO_INDEX]%.*}.txt"
done

# unhide text on the display you're connected to
sudo sh -c "TERM=linux setterm -foreground white -clear all >/dev/tty0"
