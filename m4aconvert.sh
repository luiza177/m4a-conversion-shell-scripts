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
parse_channels(){
    CHANNELS=$(afinfo "$1" | grep "Data format:") # Data format:     1 ch,  44100 Hz, 'lpcm' (0x0000000C) 16-bit little-endian signed integer
    echo ${CHANNELS:17:1}
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


convert(){
    local BASE="$1"
    local FILES="$2"
    echo "converting: ${FILES}..."
    for FILE in $FILES; do
        if [ -d "$BASE" ]; then
            FILE="$BASE/$FILE"
        fi
        local CUR_CHANNELS="$CHANNELS"
        if [ -z "$CHANNELS" ]; then
            CUR_CHANNELS=$(parse_channels "$FILE")
        fi
        afconvert -d aac -f m4af -c $CUR_CHANNELS -b $BITRATE "$FILE" "${FILE%.wav}.m4a"; 
        # get generated *.m4a and move to output folder
        FILE_M4A=$(echo "$FILE" | sed s/.wav/.m4a/g)
        mv "$FILE_M4A" "$OUTPUT_FOLDER"
    done
}

# default variables: 
OUTPUT_FOLDER="M4A"
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

# # checks for or creates output folder
if [ ! -d "${OUTPUT_FOLDER}" ]; then
    mkdir "${OUTPUT_FOLDER}"
fi

FILES=$(gather_files $@)
convert "$1" "$FILES" 
echo "done"