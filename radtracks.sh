#!/usr/bin/env bash

ARTIST='artist'
ALBUM='album'
GENRE='Rock'
TRACK=0
TITLE='title'
YEAR=1900
TRIM_START=0
TRIM_END=0

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

    if [ "$name" == "FILE" ]; then
        URLS+=$value;
    fi
done < "$1"

TEMP3=radtracks$TRACK.mp3

#download files
for u in "${URLS[@]}"
do
    wget $u
    FILES+=$(echo ${u} | cut -d/ -f6)
done

# flac to mp3
ffmpeg \
    -safe 0 \
    -y \
    -f concat \
    -i <( for f in "${FILES[@]}"; do echo "file '$(pwd)/$f'"; done ) \
    -codec:a libmp3lame \
    -qscale:a 2 \
    $TEMP3

# trim start and end here ...

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
    --to-v1.1 \
    --remove-all \
    --add-image folder.jpg:FRONT_COVER \
    --rename '$track:num $title' \
    $TEMP3

for f in "${FILES[@]}"
do
    rm -fv $f
done

