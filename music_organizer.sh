#!/bin/bash

DIR=$1
cd $DIR

for song in *.m4a *.mp3 *.FLAC
do
	# There are no songs in this directory
	if [[ "$?" -ne 0 ]]
	then
		continue
	fi

	# Extract metadata
	#exiftool "$MUSIC"
	metadata=$(exiftool -Artist -Album  -j "$song" | jq ".[]" )

	ARTIST=$( echo "$metadata" | jq -r  ".Artist" )
	ALBUM=$( echo "$metadata" | jq -r ".Album" )
	SONG_TITLE=$( echo "$metadata" | jq -r ".SourceFile" )

	# ALBUM is empty
	if [[ -z "$ALBUM" ]]
	then
		ALBUM="UNKNOWN"
	fi

	# check for artist and song title

	if [[ ! -d "${ARTIST}/${ALBUM}" ]]
	then
		mkdir -p "${ARTIST}/${ALBUM}"
	fi

	if [[ ! -e "${ARTIST}/${ALBUM}/${SONG_TITLE}" ]]
	then
		echo "Moving $SONG_TITLE to ${ARTIST}/${ALBUM}"
		mv "$SONG_TITLE"  "${ARTIST}/${ALBUM}/"
	else 
		echo "Skipping $SONG_TITLE, already exists."
	fi 
done

echo ">> ALL DONE"
