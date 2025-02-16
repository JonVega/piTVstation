#!/bin/bash

# this script creates txt files with the runtime (in seconds) for each video in ~/piTVstation/videos

sumFilesCreated=0

for dir in /home/$USER/piTVstation/videos/*; do
   if [ ! -f "${dir%.*}.txt" ]; then
	echo "creating: ${dir%.*}.txt"
	sumFilesCreated=$((sumFilesCreated+1))
	touch "${dir%.*}.txt"
	duration=$(mediainfo --Inform="Video;%Duration%" "$dir")
	# convert millisecond value to seconds and add to video txt file
	echo $(( ${duration%.*} / 1000 )) > "${dir%.*}.txt"
   fi
done

echo "$sumFilesCreated .txt files created"
