#!/bin/bash

# this script creates txt files with the runtime (in seconds) for each video in ~/piTVstation/videos

SUM_FILES_CREATED=0
LIVE_M3U8_SECONDS_DURATION=3600 #1 hour

for dir in /home/$USER/piTVstation/videos/*; do
	if [[ ! -f "${dir%.*}.txt" && "${dir,,}" == *live* ]]; then
		echo "creating live: ${dir%.*}.txt"
		touch "${dir%.*}.txt"
		echo "$LIVE_M3U8_SECONDS_DURATION" > "${dir%.*}.txt" #86400 seconds are in a day
		SUM_FILES_CREATED=$((SUM_FILES_CREATED+1))
	elif [ ! -f "${dir%.*}.txt" ]; then
		duration=$(mediainfo --Inform="Video;%Duration%" "$dir")
		if [ -z "$duration" ]; then  # Check if mediainfo duration is empty
			echo "skipping: $dir"
		else
        	echo "creating file: ${dir%.*}.txt"
        	touch "${dir%.*}.txt"
        	echo $(( ${duration%.*} / 1000 )) > "${dir%.*}.txt"  # Convert ms to seconds
        	SUM_FILES_CREATED=$((SUM_FILES_CREATED+1))
        fi
	fi
done

echo "$SUM_FILES_CREATED .txt files created"
