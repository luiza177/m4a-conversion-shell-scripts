#!/bin/bash

MANUAL="m4aconvert script manual:

    Uses Mac built-in afconvert for WAV to M4A conversion. Needs Mac built-in afinfo for default channel number behavior.

    USAGE:

        m4aconvert.sh [options...] [folder or files...]

    OPTIONS:
        { -b | --bitrate } BITRATE
            [kbps] Overrides default bit rate of 128 kbps.

        { -c | --channels } CHANNEL CONFIGURATION
            [1-2] Overrides default channel configuration of input file.

        { -o | --output-folder } OUTPUT FOLDER
            Overrides default output folder name of \"M4A\"

        { -h | --help } MANUAL
            Shows this info.
    
    EXAMPLES:
        m4aconvert.sh . --- to convert whole current folder with default values
        m4aconvert.sh 0.wav 1.wav --- to convert individual files with default values
        m4aconvert.sh --bitrate 256 --channels 1 WAV --- to convert all files inside WAV/ folder at 256kbps mono
        m4aconvert.sh -b 96 -c 2 BiBs --- to convert all files inside BiBs/ folder at 96kbps stereo
        m4aconvert.sh -o converted . --- to convert all files inside the current folder and put the new files into a folder named \"converted/\" 

"

# functions
gather_files(){
    if [ -d "$1" ]; then
        # whole folder
        echo "$(find -E "$1" -maxdepth 1 -type f -regex '.*(.wav|m4a|flac|mp3)$')"
    else
        # specified files
        echo "$(ls "$@" | awk '/\.(wav|m4a|flac|mp3)$/ { print $0 }')"
    fi
}

parse_channels(){
    local CHANNELS=$(afinfo "$1" | grep "Data format:") # Data format:     1 ch,  44100 Hz, 'lpcm' (0x0000000C) 16-bit little-endian signed integer
    echo ${CHANNELS:17:1}
    # awk '{ print $3 }' $CHANNELS
}

convert(){
    echo "converting: " ${1} "..."
    local IFS=$(echo -en "\n\b")

    for FILE in $1; do
        # local extension="${FILE:}" # last 3 or 4 characters

        #! DEAL W/ FOLDER
        base="$(basename "$FILE")"
        dir="$(dirname "$FILE")"
        dir_display=$(basename "$dir")
        
        output_folder=""
        output=""

        if [ -n "$OUTPUT_FOLDER" ]; then
            output_folder="${OUTPUT_FOLDER}/"
            output="${OUTPUT_FOLDER}/${base}"
        else
            output_folder="${dir}/${DEFAULT_OUTPUT_FOLDER}/"
            output="${output_folder}/${base}"
        fi

        if [ ! -d "${output_folder}" ]; then
            mkdir "${output_folder}"
        fi
        #! FOLDER END


        local CUR_CHANNELS="$CHANNELS"
        if [ -z "$CHANNELS" ]; then
            CUR_CHANNELS=$(parse_channels "$FILE")
        fi
        # defaults to ABR without -s 0 for CBR
        afconvert -d aac -f m4af -s 0 -c "$CUR_CHANNELS" -b "$BITRATE" "$FILE" "${output%.*}.m4a"; # remove extension from filename
    done
}

# default variables: 
DEFAULT_OUTPUT_FOLDER="M4A"
BITRATE=128000 # 128kbps

while true; do
    case "$1" in
        -b|--bitrate)
            shift
            BITRATE="$1"
            BITRATE=$(($BITRATE*1000))
            shift
            ;;
        -c|--channels)
            shift
            CHANNELS="$1"
            shift
            ;;
        -o|--output-folder)
            shift
            OUTPUT_FOLDER="$1"
            shift
            ;;
        -h|--help|help)
            echo "$MANUAL"
            exit 1
            ;;
        *)
            break
  esac
done

FILES=$(gather_files "$@")
convert "$FILES" 
echo "done"
