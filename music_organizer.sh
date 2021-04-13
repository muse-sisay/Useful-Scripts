#!/bin/bash

# USAGE
#   $ tidal-organizer SEARCH_DIR OUTPUT_DIR

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ "$1" == "" ]] 
then 
    echo "Error : Missing SEARCH DIR"
    exit 1
fi

SEARCH_DIR=$1

if [[ "$2" != "" ]]
then
    OUTPUT_DIR="$2"  
else 
    OUTPUT_DIR="$(pwd)"
fi

echo -e "${GREEN}LOOKING SONGS IN :${NC} $SEARCH_DIR" # DEBUG OUTPUT
echo -e "${GREEN}OUTPUT TO :${NC} $OUTPUT_DIR" # DEBUG OUTPUT
echo 

cd "$SEARCH_DIR"


shopt -s nullglob
# for song in *.flac *.m4a
find . -not -path '*/\.*'  -type f -a \( -name '*.flac' -o -name "*.mp3" \) | while read song
do 
    IS_UNKOWN=0
    echo "> $song"

	metadata=$(exiftool -Albumartist -Artist -Album  -Title -TrackNumber -FileTypeExtension -j "$song" | jq ".[]" )

    # echo "$metadata" # DEBUG OUTPUT

    FILE=$( echo "$metadata" | jq -r ".SourceFile" )

    # extract ARTIST field
    if [[ $( echo "$metadata" | jq -r ".Albumartist" ) != "null" ]]
    then 
        ARTIST=$( echo "$metadata" | jq -r  ".Albumartist" )
    else 

        if [[ $( echo "$metadata" | jq -r  ".Artist | type") == "array" ]]
        then 
        ARTIST=$( echo "$metadata" | jq -r  ".Artist[0]" )
        
        elif [[ $(echo "$metadata" | jq -r  ".Artist | type") == "string" ]]
        then
            ARTIST=$( echo "$metadata" | jq -r  ".Artist" )
        else 
            # file contains no artist field
            ARTIST="unkown"
            IS_UNKOWN=1
        fi

    fi

    # extract ALBUM field
    if [[ $( echo "$metadata" | jq -r ".Album" ) != "null" ]]
    then
        ALBUM=$( echo "$metadata" | jq -r ".Album" )
    else 
        # file contains no artist field
        ALBUM="unknown" 
        IS_UNKOWN=1
    fi

     # extract TITLE field
    if [[ $( echo "$metadata" | jq -r ".Title" ) != "null" ]]
    then
        TRACK_NUMBER=$( echo "$metadata" | jq -r ".TrackNumber" )
        SONG_TITLE=$( echo "$metadata" | jq -r ".Title" )
        FILE_TYPE=$( echo "$metadata" | jq -r ".FileTypeExtension" )
        
        SONG_TITLE="${TRACK_NUMBER} - ${ARTIST} - ${SONG_TITLE}.${FILE_TYPE}"
   
    else 
       SONG_TITLE=$(basename "$( echo "$metadata" | jq -r ".SourceFile" )")
    fi
    
    # SANITIZE FILE NAME
    ALBUM=${ALBUM//[^a-zA-Z0-9 \._\-]/-}
    SONG_TITLE=${SONG_TITLE//[^a-zA-Z0-9 \._\-]/-}

    # echo -e "${GREEN}$ARTIST" # DEBUG OUTPUT
    # echo $ALBUM # DEBUG OUTPUT
    # echo $SONG_TITLE # DEBUG OUTPUT
    # echo -e "$NC" # DEBUG OUTPUT

    
    if [[ $IS_UNKOWN -eq 0 ]]
    then

        if [[ ! -d "${OUTPUT_DIR}/${ARTIST}/${ALBUM}" ]]
        then 
            mkdir -p "${OUTPUT_DIR}/${ARTIST}/${ALBUM}"
        fi

        if [[ ! -e "${OUTPUT_DIR}/${ARTIST}/${ALBUM}/${SONG_TITLE}" ]]
        then 
            echo -e "Moving $GREEN $SONG_TITLE $NC to $GREEN ${ARTIST}/${ALBUM} $NC \n"
            mv "$FILE"  "${OUTPUT_DIR}/${ARTIST}/${ALBUM}/${SONG_TITLE}"
            
        else 
            echo -e "${RED}Skipping${NC} $SONG_TITLE ${RED}already exists in${NC} ${OUTPUT_DIR}/${ARTIST}/${ALBUM}/ \n"
        fi
    else 
        if [[ ! -d "${OUTPUT_DIR}/unkown" ]]
        then 
            mkdir -p "${OUTPUT_DIR}/unkown"
        fi

        if [[ ! -e "${OUTPUT_DIR}/unkown/${SONG_TITLE}" ]]
        then 
            echo -e "Moving $GREEN $SONG_TITLE $NC to $RED unknown/ $NC \n"
            mv "$FILE"  "${OUTPUT_DIR}/unkown/${SONG_TITLE}"
        else 
            echo -e "${RED}Skipping${NC} $SONG_TITLE ${RED} already exists in${NC} ${OUTPUT_DIR}/unkown/ \n"
        fi
    fi

done    
