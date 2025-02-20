#!/bin/bash

# this script creates txt files with the runtime (in seconds) for each video in ~/piTVstation/videos

# User Changeable Variables
# ----------------------------------

LIVE_M3U8_SECONDS_DURATION=3600 #1 hour
BACKUP_STOPMARKS_DIRECTORY="/home/$USER/piTVstation/backups"

# Script Variables
# ----------------------------------

SUM_FILES_CREATED=0
VIDEO_FOLDER_LOCATION="/home/$USER/piTVstation/videos"
STOPMARKS_BACKUP_FILE="stopmarks_backup_$(date +'%Y-%m-%d_%H_%M_%S').zip"
AVAILABLE_SD_SIZE=$(df /dev/mmcblk0p2 | tail -1 | awk '{print $4}')
ESTIMATED_SD_SIZE=$(du -sb "$BACKUP_STOPMARKS_DIRECTORY" | awk '{print $1}')

# Backup Stopmarks
# ----------------------------------

echo "$AVAILABLE_SD_SIZE"
echo "$ESTIMATED_SD_SIZE"

# Check if there is enough space
if [ "$AVAILABLE_SD_SIZE" -gt "$ESTIMATED_SD_SIZE" ]; then
	# if the video folder has .txt already, then back them all up
    if ls -A "$VIDEO_FOLDER_LOCATION"/*.txt &> /dev/null; then
    	zip -rj $BACKUP_STOPMARKS_DIRECTORY/$STOPMARKS_BACKUP_FILE $VIDEO_FOLDER_LOCATION -i \*.txt
	else
    	echo "no .txt files found - skipping backup."
	fi
else
    echo "ERROR - INSUFFICIENT SPACE TO CREATE BACKUP"
fi

# Stopmark Creation
# ----------------------------------

for video_dir in $VIDEO_FOLDER_LOCATION/*; do
	if [[ ! -f "${video_dir%.*}.txt" && "${video_dir,,}" == *live* ]]; then
		
		echo "creating live: ${video_dir%.*}.txt"
		touch "${video_dir%.*}.txt"
		echo "$LIVE_M3U8_SECONDS_DURATION" > "${video_dir%.*}.txt" #86400 seconds are in a day
		SUM_FILES_CREATED=$((SUM_FILES_CREATED+1))
	elif [ ! -f "${video_dir%.*}.txt" ]; then
		duration=$(mediainfo --Inform="Video;%Duration%" "$video_dir")
		if [ -z "$duration" ]; then  # Check if mediainfo duration is empty
			echo "skipping: $video_dir"
		else
        	echo "creating file: ${video_dir%.*}.txt"
        	touch "${video_dir%.*}.txt"
        	echo $(( ${duration%.*} / 1000 )) > "${video_dir%.*}.txt"  # Convert ms to seconds
        	SUM_FILES_CREATED=$((SUM_FILES_CREATED+1))
        fi
	fi
done

echo "$SUM_FILES_CREATED .txt files created"
