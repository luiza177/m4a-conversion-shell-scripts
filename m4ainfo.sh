#!/bin/bash

MANUAL="m4ainfo script manual:

    Gets info on file(s)'s BITRATE and CHANNEL CONFIG. Uses Mac built-in afinfo.
    
    USAGE:
        
        m4ainfo.sh [options...] [folder or files...]

    OPTIONS:
        { help | -h | --help }
            Shows this info.
    
    EXAMPLES:
    Usage: 
        m4ainfo.sh . --- to show bit rate and channel config of all files in current folder
        m4ainfo.sh 8.m4a 9.wav --- to show bit rate and channel config of specific files
        m4ainfo.sh help --- to show this info

"

# functions
parse_channels(){
    local CHANNELS=$(afinfo "$1" | grep "Data format:") # Data format:     1 ch,  44100 Hz, 'lpcm' (0x0000000C) 16-bit little-endian signed integer
    echo ${CHANNELS:17:1}
}

parse_bitrate(){
    local BITRATE=$(afinfo "$1" | grep "bit rate" | awk '{print $3;}') # bit rate: 125655 bits per second
    echo ${BITRATE}
}

gather_files(){
    if [ -d "$1" ]; then
        # whole folder
        echo $(ls "$1" | grep -E '.m4a|.wav')
    else
        # specified files   
        echo "$*"
    fi
}

info(){
    local BASE="$1"
    local FILES="$2"
    for FILE in $FILES; do
        if [ -d "$BASE" ]; then
            FILE="$BASE/$FILE"
        fi
        echo "${FILE}:"
        local BITRATE=$(parse_bitrate "$FILE")        
        local BITRATE_KBPS=$(echo "scale=0; $BITRATE/1000" | bc)
        local CHANNELS=$(parse_channels "$FILE")
        echo "  Bitrate: $BITRATE_KBPS kbps"
        echo "  Channels: $CHANNELS"
    done
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
    echo "$MANUAL"
    exit 1
fi

FILES=$(gather_files "$@")
info "$1" "$FILES"