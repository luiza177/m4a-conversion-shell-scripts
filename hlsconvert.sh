#!/bin/bash

SAVEIFS="${IFS}"
IFS=$(echo -en "\n\b")
if [ -d "$1" ]; then
  echo "$1:"
  FILES=$(find -E "$1" -maxdepth 1 -type f -regex '.*(.wav|m4a)$')
else
  FILES="$(ls "$@" | awk '/.wav|.m4a$/ { print $0 }')"
fi

echo "converting: " ${1} "..."
SAVEIFS="${IFS}"
IFS=$(echo -en "\n\b")

for FILE in $FILES; do
    base="$(basename "$FILE")"
    dir="$(dirname "$FILE")"
    extension="${base:(-4)}"
    
    output_folder="${dir}/${base%${extension}}-HLS"

    if [ ! -d "${output_folder}" ]; then
        mkdir "${output_folder}"
    fi

    temp_file="$(mktemp)"
    ffmpeg \
        -i "$FILE" \
        -hide_banner \
        -af loudnorm=I=-16:TP=-3.0:dual_mono=true:print_format=summary \
        -f null - \
        2> "$temp_file"

    integrated="$(awk '/Input Integrated:/ { print $3 }' "$temp_file")"
    lra="$(awk '/Input LRA:/ { print $3 }' "$temp_file")"
    truepeak="$(awk '/Input True Peak:/ { print $4 }' "$temp_file")"
    thresh="$(awk '/Input Threshold:/ { print $3 }' "$temp_file")"

    # ffmpeg \
    #     -hide_banner \
    #     -loglevel fatal \
    #     -i "$FILE" \
    #     -af loudnorm=I=-16:TP=-3.0:dual_mono=true:measured_I=${integrated}:measured_TP=${truepeak}:measured_LRA=${lra}:measured_thresh=${thresh}:linear=true:print_format=summary \
    #     -ar 44100 \
    #     -c:a aac \
    #     -movflags +faststart \
    #     -map 0:a \
    #     -map 0:a \
    #     -map 0:a \
    #     -b:a:0 128000 \
    #     -b:a:1 96000 \
    #     -b:a:2 64000 \
    #     -var_stream_map "a:0 a:1 a:2" \
    #     -master_pl_name main.m3u8 \
    #     -f HLS \
    #     -start_number 0 \
    #     -hls_time 10 \
    #     -hls_list_size 0 \
    #     -hls_segment_filename "${output_folder}/v%v/seq%d.ts" \
    #     "${output_folder}/v%v/br.m3u8"

    COMMAND="ffmpeg -hide_banner -loglevel fatal -i \"$FILE\" "
    if [ $(echo "$integrated > -15.2" | bc -l) -eq 1 ] || [ $(echo  "$integrated < -16.8" | bc -l) -eq 1 ] || [ $(echo  "$truepeak > -2.5" | bc -l) -eq 1 ]; then
        echo "normalizing ${base}"
        COMMAND+="-af loudnorm=I=-16:TP=-3.0:dual_mono=true:measured_I=${integrated}:measured_TP=${truepeak}:measured_LRA=${lra}:measured_thresh=${thresh}:linear=true:print_format=summary "
    else
        echo "${base} is within tolerance"
    fi
    COMMAND+="-ar 44100 -c:a aac -movflags +faststart -map 0:a -map 0:a -map 0:a -b:a:0 128000 -b:a:1 96000 -b:a:2 64000 -var_stream_map \"a:0 a:1 a:2\" -master_pl_name main.m3u8 -f HLS -start_number 0 -hls_time 10 -hls_list_size 0 -hls_segment_filename \"${output_folder}/v%v/seq%d.ts\" \"${output_folder}/v%v/br.m3u8\""
    eval "$COMMAND"
    rm "$temp_file"
done

echo "done"
