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
# Author		: Jonathan Vega
# Dependencies	: cvlc, mediainfo
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variables that you should change to setup how you like  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# How many commercials should play before resuming playback
AMOUNT_COMMERCIALS=0

# Adjust to how your speakers are configure (in my case, my tv is mono, so 0)
# options are :0=mono, 1=stereo, 2=reverse stereo, 3=left, 4=right, 5=dolby surround, 6=headphones
AUDIO_MODE="--stereo-mode=0"

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

# array of videos and subdirectories that ignore .txt files
VIDEO_FILES=("$VIDEO_DIRECTORY"/*[^.txt])
# array of all files in commercial directory
COMMERCIAL_FILES=("$COMMERCIAL_DIRECTORY"/*)

# check to see if any videos and quit if no videos found
if [[ ${#VIDEO_FILES[@]} -eq 0 ]]; then
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
while [ 1 ]
do
	# use octal to read 2 bytes of data as signed integer from urandom without memory address
	# then get the length of the VIDEO_FILES array
	RANDOM_VIDEO_INDEX=$(od -An -N2 -i /dev/urandom | awk -v len=${#VIDEO_FILES[@]} '{print $1 % len}')
	RANDOM_COMMERCIAL_INDEX=$(od -An -N2 -i /dev/urandom | awk -v len=${#COMMERCIAL_FILES[@]} '{print $1 % len}')
	RESUME_TIME=""

	echo "playing: ${VIDEO_FILES[$RANDOM_VIDEO_INDEX]}"

	while IFS= read -r LINE; do
    	if [ ! -z RESUME_TIME ]; then #if resume_time string is not empty - so if I know where to resume at
    		cvlc --play-and-exit --quiet --no-osd --no-spu $AUDIO_COMPRESSOR_GAIN_FILTER $AUDIO_MODE --start-time=$RESUME_TIME --stop-time=$LINE "${VIDEO_FILES[$RANDOM_VIDEO_INDEX]}"
		else
			# resume_time is empty, so play file from the beginning until resume time is found from video txt file
			cvlc --play-and-exit --quiet --no-osd --no-spu $AUDIO_COMPRESSOR_GAIN_FILTER $AUDIO_MODE --run-time=$LINE "${VIDEO_FILES[$RANDOM_VIDEO_INDEX]}"
		fi
		# loop and play n amount of commercials
		for i in $(seq 1 $AMOUNT_COMMERCIALS); do cvlc --play-and-exit --quiet --no-osd --no-spu $AUDIO_COMPRESSOR_GAIN_FILTER $AUDIO_MODE "${COMMERCIAL_FILES[$RANDOM_COMMERCIAL_INDEX]}"; done
    
		RESUME_TIME=$LINE
	# removes the extension for the currently playing video and grabs it txt file
	done < "${VIDEO_FILES[$RANDOM_VIDEO_INDEX]%.*}.txt"
done

# unhide text on the display you're connected to
sudo sh -c "TERM=linux setterm -foreground white -clear all >/dev/tty0"
