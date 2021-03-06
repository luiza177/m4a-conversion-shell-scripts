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
gather_files(){
    if [ -d "$1" ]; then
        # whole folder
        echo "$(find -E "$1" -maxdepth 1 -type f -regex '.*(.wav|m4a)$')"
    else
        # specified files
        echo "$(ls "$@" | awk '/.wav|.m4a$/ { print $0 }')"
    fi
}

parse_channels(){
    # TODO: convert to ffprobe
    local CHANNELS=$(afinfo "$1" | grep "Data format:") # Data format:     1 ch,  44100 Hz, 'lpcm' (0x0000000C) 16-bit little-endian signed integer
    echo ${CHANNELS:17:1}
}

parse_bitrate(){
    # TODO: convert to ffprobe
    local BITRATE=$(afinfo "$1" | grep "bit rate" | awk '{print $3;}') # bit rate: 125655 bits per second
    # local BITRATE=$(afinfo "$1" | awk '/bit rate/ {print $3;}') # bit rate: 125655 bits per second
    echo ${BITRATE}
}

info(){
    local IFS=$(echo -en "\n\b")
    echo $1
    for FILE in $1; do
        echo "${FILE}:"
        if [ ${FILE:(-4)} = ".m4a" ]; then
            echo "  [$(afinfo ${FILE} | grep optimized)]"
        fi
        local BITRATE=$(parse_bitrate "$FILE")        
        local BITRATE_KBPS=$(echo "scale=0; $BITRATE/1000" | bc)
        local CHANNELS=$(parse_channels "$FILE")
        echo "  Bitrate: $BITRATE_KBPS kbps"
        echo "  Channels: $CHANNELS"
    done
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
    echo "$MANUAL"
    exit 0
fi

FILES=$(gather_files "$@")
info "$FILES"