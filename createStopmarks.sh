#!/bin/bash

# this script creates txt files with the runtime (in seconds) for each video in ~/piTVstation/videos

# User Changeable Variables
# -------------------------------------------

live_m3u8_seconds_duration=3600 #1 hour
backup_stopmarks_directory="/home/$USER/piTVstation/backups"

# Script Variables
# -------------------------------------------

sum_files_created=0
video_folder_location="/home/$USER/piTVstation/videos"
stopmarks_backup_file="stopmarks_backup_$(date +'%Y-%m-%d_%H_%M_%S').zip"
available_sd_size=$(df /dev/mmcblk0p2 | tail -1 | awk '{print $4}')
estimated_sd_size=$(du -sb "$backup_stopmarks_directory" | awk '{print $1}')

# Delete Dot Files (usually cause by macOS)
# -------------------------------------------

rm /home/$USER/piTVstation/.*
rm /home/$USER/piTVstation/videos/.*
rm /home/$USER/piTVstation/scripts/.*
rm /home/$USER/piTVstation/commercials/.*

# Backup Stopmarks
# -------------------------------------------

echo "$available_sd_size"
echo "$estimated_sd_size"

# Check if there is enough space
if [ "$available_sd_size" -gt "$estimated_sd_size" ]; then
	# if the video folder has .txt already, then back them all up
    if ls -A "$video_folder_location"/*.txt &> /dev/null; then
    	zip -rj $backup_stopmarks_directory/$stopmarks_backup_file $video_folder_location -i \*.txt
	else
    	echo "no .txt files found - skipping backup."
	fi
else
    echo "ERROR - INSUFFICIENT SPACE TO CREATE BACKUP"
fi

# Stopmark Creation
# -------------------------------------------

for video_dir in $video_folder_location/*; do
	if [[ ! -f "${video_dir%.*}.txt" && "${video_dir,,}" == *live* ]]; then
		
		echo "creating live: ${video_dir%.*}.txt"
		touch "${video_dir%.*}.txt"
		echo "$live_m3u8_seconds_duration" > "${video_dir%.*}.txt" #86400 seconds are in a day
		sum_files_created=$((sum_files_created+1))
	elif [ ! -f "${video_dir%.*}.txt" ]; then
		duration=$(mediainfo --Inform="Video;%Duration%" "$video_dir")
		if [ -z "$duration" ]; then  # Check if mediainfo duration is empty
			echo "skipping: $video_dir"
		else
        	echo "creating: ${video_dir%.*}.txt"
        	touch "${video_dir%.*}.txt"
        	echo $(( ${duration%.*} / 1000 )) > "${video_dir%.*}.txt"  # Convert ms to seconds
        	sum_files_created=$((sum_files_created+1))
        fi
	fi
done

echo "$sum_files_created .txt files created"
