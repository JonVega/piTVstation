#!/bin/bash

# this script creates txt files with the runtime (in seconds) for each video in ~/piTVstation/videos

# User Changeable Variables
# -------------------------------------------

live_m3u8_seconds_duration=3600 #1 hour
piTVstation_Directory_Location="$HOME/piTVstation"

# Script Variables
# -------------------------------------------

sum_files_created=0
backup_stopmarks_directory="$piTVstation_Directory_Location/backups"
video_folder_location="$piTVstation_Directory_Location/videos"
stopmarks_backup_file="stopmarks_backup_$(date +'%Y-%m-%d_%H_%M_%S').zip"
available_sd_size=$(df /dev/mmcblk0p2 | tail -1 | awk '{print $4}')
estimated_sd_size=$(du -sb "$backup_stopmarks_directory" | awk '{print $1}')

# Delete Dot Files (usually cause by macOS)
# -------------------------------------------

# From Video Folder
if [ $(find $video_folder_location -maxdepth 1 -type f -name ".*" | wc -l) -gt 0 ]; then
	echo "Removing hidden dot files from $video_folder_location"
	rm $video_folder_location/.*
fi

# From Backups Folder
if [ $(find $backup_stopmarks_directory -maxdepth 1 -type f -name ".*" | wc -l) -gt 0 ]; then
	echo "Removing hidden dot files from $backup_stopmarks_directory"
	rm $backup_stopmarks_directory/.*
fi

# From Scripts Folder
if [ $(find /home/$USER/piTVstation/scripts -maxdepth 1 -type f -name ".*" | wc -l) -gt 0 ]; then
	echo "Removing hidden dot files from /home/$USER/piTVstation/scripts"
	rm /home/$USER/piTVstation/scripts/.*
fi

# From Video Folder
if [ $(find /home/$USER/piTVstation/commercials -maxdepth 1 -type f -name ".*" | wc -l) -gt 0 ]; then
	echo "Removing hidden dot files from /home/$USER/piTVstation/commercials"
	rm /home/$USER/piTVstation/commercials/.*
fi

# From piTVstation Folder
if [ $(find /home/$USER/piTVstation -maxdepth 1 -type f -name ".*" | wc -l) -gt 0 ]; then
	echo "Removing hidden dot files from /home/$USER/piTVstation"
	rm /home/$USER/piTVstation/.*
fi

# Backup Stopmarks
# -------------------------------------------

echo "Avaiable  SD Card Space: $available_sd_size"
echo "Estimated SD Card Space: $estimated_sd_size"

# Check if there is enough space
if [ "$available_sd_size" -gt "$estimated_sd_size" ]; then
	# if the video folder has .txt already, then back them all up
    if ls -A "$video_folder_location"/*.txt &> /dev/null; then
    	echo "Zipping Stopmarks"
    	zip -rj $backup_stopmarks_directory/$stopmarks_backup_file $video_folder_location -i \*.txt
    	echo "Zipping DONE"
	else
    	echo "no .txt stopmark files found - skipping backup."
	fi
else
    echo "INSUFFICIENT SPACE TO CREATE BACKUP - TRY TO FREE UP SOME SPACE"
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
