#!/bin/bash

# this script creates txt files with the runtime (in seconds) for each video in ~/piTVstation/videos

sumFilesCreated=0

for dir in /home/$USER/piTVstation/videos/*; do
	if [[ ! -f "${dir%.*}.txt" && "${dir,,}" == *live* ]]; then
		echo "creating live: ${dir%.*}.txt"
		touch "${dir%.*}.txt"
		echo "86400" > "${dir%.*}.txt" #86400 seconds are in a day
		sumFilesCreated=$((sumFilesCreated+1))
	elif [ ! -f "${dir%.*}.txt" ]; then
		duration=$(mediainfo --Inform="Video;%Duration%" "$dir")
		if [ -z "$duration" ]; then  # Check if mediainfo duration is empty
			echo "skipping: $dir"
        else
        	echo "creating file: ${dir%.*}.txt"
        	touch "${dir%.*}.txt"
        	echo $(( ${duration%.*} / 1000 )) > "${dir%.*}.txt"  # Convert ms to seconds
        	sumFilesCreated=$((sumFilesCreated+1))
        fi
	fi
done

echo "$sumFilesCreated .txt files created"
