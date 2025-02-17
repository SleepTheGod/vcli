#!/bin/bash

# Function to install the vcli script
function install_vcli() {
    # Determine install path for different distros
    local install_path="/usr/local/bin/vcli"
    
    if [[ $(uname -s) == "Darwin" ]]; then
        install_path="/usr/local/bin/vcli"
    fi
    
    sudo cp "$0" "$install_path"
    sudo chmod +x "$install_path"
    echo "[+] vcli installed successfully. You can now use 'vcli' from anywhere."
}

# Function to show help message
function show_help() {
    echo "Usage: vcli -s <source> -k <stream_key> [-b <bitrate>] [-r <resolution>] [-c <codec>] [-o <overlay>] [--debug] [--install]"
    echo "Options:"
    echo "  -s <source>       Path to video source file or webcam"
    echo "  -k <stream_key>   Your Vaughn.Live stream key"
    echo "  -b <bitrate>      Video bitrate (default: 2500k)"
    echo "  -r <resolution>   Video resolution (default: 1280x720)"
    echo "  -c <codec>        Video codec (default: libx264)"
    echo "  -o <overlay>      Text overlay on stream"
    echo "  --debug           Enable debug mode to log stream details"
    echo "  -h, --help        Show this help menu"
    echo "  --install         Install this script as 'vcli' command"
}

# Function to start the stream using FFmpeg
function start_stream() {
    local source="$1"
    local stream_key="$2"
    local bitrate="$3"
    local resolution="$4"
    local codec="$5"
    local overlay="$6"
    local log_file="vaughn_live_stream.log"
    local debug="$7"

    if ! command -v ffmpeg &> /dev/null; then
        echo "Error: FFmpeg is not installed or not in PATH." | tee -a "$log_file"
        exit 1
    fi

    RTMP_URL="rtmp://ingest.vaughnsoft.net/live"
    STREAM_URL="$RTMP_URL/$stream_key"

    if [[ "$debug" == "true" ]]; then
        echo "[DEBUG] Starting stream..." | tee -a "$log_file"
        echo "[DEBUG] Source: $source" | tee -a "$log_file"
        echo "[DEBUG] Stream Key: $stream_key" | tee -a "$log_file"
        echo "[DEBUG] Bitrate: $bitrate" | tee -a "$log_file"
        echo "[DEBUG] Resolution: $resolution" | tee -a "$log_file"
        echo "[DEBUG] Codec: $codec" | tee -a "$log_file"
        echo "[DEBUG] Overlay: ${overlay:-None}" | tee -a "$log_file"
    else
        echo "[+] Starting stream..." | tee -a "$log_file"
        echo "    Source: $source" | tee -a "$log_file"
        echo "    Stream Key: $stream_key" | tee -a "$log_file"
        echo "    Bitrate: $bitrate" | tee -a "$log_file"
        echo "    Resolution: $resolution" | tee -a "$log_file"
        echo "    Codec: $codec" | tee -a "$log_file"
        echo "    Overlay: ${overlay:-None}" | tee -a "$log_file"
    fi

    ffmpeg_cmd=( 
        ffmpeg -re -i "$source" \
        -c:v "$codec" -b:v "$bitrate" \
        -s "$resolution" \
        -c:a aac -b:a 128k -ar 44100 \
        -f flv "$STREAM_URL"
    )

    if [ -n "$overlay" ]; then
        ffmpeg_cmd+=( -vf "drawtext=text='$overlay':fontcolor=white:x=10:y=10" )
    fi

    "${ffmpeg_cmd[@]}" 2>&1 | tee -a "$log_file"
}

# Main function to handle user input and start the stream
function main() {
    if [[ "$1" == "--install" ]]; then
        install_vcli
        exit 0
    fi

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi

    # Default values for stream settings
    bitrate="2500k"
    resolution="1280x720"
    codec="libx264"
    overlay=""
    debug="false"

    echo -e "\e[1;32m"
    echo "██╗   ██╗ █████╗ ██╗   ██╗ ██████╗ ██╗  ██╗███╗   ██╗"
    echo "██║   ██║██╔══██╗██║   ██║██╔════╝ ██║  ██║████╗  ██║"
    echo "██║   ██║███████║██║   ██║██║  ███╗███████║██╔██╗ ██║"
    echo "╚██╗ ██╔╝██╔══██║██║   ██║██║   ██║██╔══██║██║╚██╗██║"
    echo " ╚████╔╝ ██║  ██║╚██████╔╝╚██████╔╝██║  ██║██║ ╚████║"
    echo "  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝"
    echo -e "\e[0m"
    echo "[Vaughn Live CLI] Vaughn.Live Advanced CLI Broadcaster" | lolcat
    echo "---------------------------------------------------" | lolcat

    while [[ $# -gt 0 ]]; do
        case $1 in
            -s) source="$2"; shift 2 ;;
            -k) stream_key="$2"; shift 2 ;;
            -b) bitrate="$2"; shift 2 ;;
            -r) resolution="$2"; shift 2 ;;
            -c) codec="$2"; shift 2 ;;
            -o) overlay="$2"; shift 2 ;;
            --debug) debug="true"; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) echo "Invalid option"; show_help; exit 1 ;;
        esac
    done

    if [[ -z "$source" || -z "$stream_key" ]]; then
        show_help
        exit 1
    fi

    start_stream "$source" "$stream_key" "$bitrate" "$resolution" "$codec" "$overlay" "$debug"
}

# Run the main function
main "$@"
