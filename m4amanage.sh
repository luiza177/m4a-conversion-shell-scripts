#!/bin/bash

USAGE="USAGE: 
        m4amanage.sh convert . --- to convert whole folder with default values
        m4amanage.sh convert 0.wav 1.wav --- to convert individual files with default values
        m4amanage.sh convert -b 96 -c 2 WAV --- convert all files inside WAV/ folder at 96kbps stereo
        m4amanage.sh convert -o converted . --- to convert all files inside the current folder and put the new files into a folder named \"converted/\"
        m4amanage.sh info 8.m4a 9.wav --- to show bit rate and channel config, no conversion

        m4amanage.sh help --- to show MANUAL

"
MANUAL="m4amanage script manual:

    m4amanage.sh [domain] [options...] [files...]

    DOMAINS:
    { convert }
        Uses Mac built-in afconvert for WAV to M4A conversion.
        Options:
            { -b | --bitrate } BITRATE
                [kbps] Overrides default bit rate of 128 kbps.
            { -c | --channels } CHANNEL CONFIGURATION
                [1-2] Overrides default channel configuration of input file.
            { -o | --output-folder } OUTPUT FOLDER
                Overrides default output folder name of \"M4A\"
    { info }
        Gets info on file(s)'s BITRATE and CHANNEL CONFIG. Uses Mac built-in afinfo.
    { help | -h | --help }
        Shows this info.
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
    local CHANNELS=$(afinfo "$1" | grep "Data format:") # Data format:     1 ch,  44100 Hz, 'lpcm' (0x0000000C) 16-bit little-endian signed integer
    echo ${CHANNELS:17:1}
}

parse_bitrate(){
    local BITRATE=$(afinfo "$1" | grep "bit rate" | awk '{print $3;}') # bit rate: 125655 bits per second
    echo ${BITRATE}
}

info_cmd(){
    local FILES=$(gather_files "$@")
    local IFS=$(echo -en "\n\b")
    # echo $1
    for FILE in $FILES; do
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

convert(){
    echo "converting: " ${1} "..."
    local IFS=$(echo -en "\n\b")
    for FILE in $1; do
        local CUR_CHANNELS="$CHANNELS"
        if [ -z "$CHANNELS" ]; then
            CUR_CHANNELS=$(parse_channels "$FILE")
        fi
        afconvert -d aac -f m4af -s 0 -c $CUR_CHANNELS -b $BITRATE "$FILE" "${FILE%.wav}.m4a"; # remove .wav from filename
        # get generated *.m4a and move to output folder
        FILE_M4A=$(echo "$FILE" | sed s/.wav/.m4a/g) # replaces .wav with .m4a from $FILE
        mv "$FILE_M4A" "$OUTPUT_FOLDER"
    done
}

convert_cmd() {
    # default variables: 
    local OUTPUT_FOLDER="M4A"
    local BITRATE=128000 # 128kbps

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
            *)
                break
        esac
    done

    # checks for or creates output folder
    if [ ! -d "${OUTPUT_FOLDER}" ]; then
        mkdir "${OUTPUT_FOLDER}"
    fi

    local FILES=$(gather_files "$@")
    convert "$FILES" 
    echo "done"
}

SUBCOMMAND="$1"

case "$SUBCOMMAND" in
    convert)
        shift
        convert_cmd "$@"
        exit 0
        ;;
    info)
        shift
        info_cmd "$@"
        exit 0
        ;;
    -h|--help|help)
        echo "$MANUAL"
        exit 0
        ;;
    *)
        echo  "$USAGE" >&2
        exit 1
        ;;
esac