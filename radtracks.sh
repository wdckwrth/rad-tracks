#!/usr/bin/env bash

ARTIST='artist'
ALBUM='album'
GENRE='Rock'
TRACK=0
TITLE='title'
YEAR=1900
TRIM_START=0
TRIM_END=0
COVER='folder.jpg'

URLS=()
FILES=()

#read configuration
while IFS='=' read name value || [[ -n "$line" ]]; do
    #echo $name : $value
    if [ "$name" == "ARTIST" ]; then ARTIST=$value; fi
    if [ "$name" == "ALBUM" ]; then ALBUM=$value; fi
    if [ "$name" == "TITLE" ]; then TITLE=$value; fi
    if [ "$name" == "GENRE" ]; then GENRE=$value; fi
    if [ "$name" == "YEAR" ]; then YEAR=$value; fi
    if [ "$name" == "TRACK" ]; then TRACK=$value; fi
    if [ "$name" == "TRIM_START" ]; then TRIM_START=$value; fi
    if [ "$name" == "TRIM_END" ]; then TRIM_END=$value; fi
    #if [ "$name" == "COVER" ]; then COVER=$value; fi


    if [ "$name" == "FILE" ]; then
        #echo "url: $value"
        URLS+=( "$value" );
    fi
done < "$1"

TEMP3=radtracks$TRACK.mp3
TEMP_COVER=cover$TRACK.jpg

if [ ${#URLS[@]} -eq 0 ]; then
    echo "No URLs to fetch. Exiting."
    exit 1
fi

echo ""
echo "Working on: $ARTIST :: $TITLE"
echo ""

# download files
CURCNT=1
TTLCNT=${#URLS[@]}
for u in "${URLS[@]}"
do
    echo "fetching: $u ($CURCNT / $TTLCNT)"
    wget -nv --show-progress $u
    file=$(echo ${u} | rev | cut -d/ -f1 | rev)
    FILES+=( "$file" )
    let CURCNT++
done

if [ $COVER != "folder.jpg" ]; then
    echo "fetching: $COVER to $TEMP_COVER"
    wget -nv -O $TEMP_COVER $COVER
    COVER=$TEMP_COVER
fi

# flac to mp3
echo ""
echo "converting flac to mp3 ..."
ffmpeg \
    -safe 0 \
    -y \
    -loglevel error \
    -stats \
    -f concat \
    -i <( for f in "${FILES[@]}"; do echo "file '$(pwd)/$f'"; done ) \
    -codec:a libmp3lame \
    -qscale:a 2 \
    $TEMP3

# trim file if indicated ...
if [ $TRIM_START != "0" ] || [ $TRIM_END != "0" ]; then
    if [ $TRIM_END == "0" ]; then TRIM_END=$(ffprobe -i $TEMP3 -show_entries format=duration -v quiet -of csv="p=0"); fi
    echo "trim start: $TRIM_START"
    echo "trim end  : $TRIM_END"
    ffmpeg -loglevel error -stats -i $TEMP3 -ss $TRIM_START -to $TRIM_END -c copy radtracks$TRACK-trimmed.mp3
    rm -fv $TEMP3
    mv radtracks$TRACK-trimmed.mp3 $TEMP3
fi


# add id3 tags
eyeD3 \
    -n $TRACK \
    -t "$TITLE" \
    -Y $YEAR \
    --recording-date $YEAR \
    -G "$GENRE" \
    -A "$ALBUM" \
    -a "$ARTIST" \
    --to-v2.3 \
    --remove-all \
    --add-image $COVER:FRONT_COVER \
    --rename '$track:num $title' \
    $TEMP3

# clean up, clean up, everybody everywhere
for f in "${FILES[@]}"
do
    rm -fv $f
done
rm -fv $TEMP_COVER
