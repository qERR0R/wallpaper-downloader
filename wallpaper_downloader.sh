#!/bin/bash

walldir="${HOME}/Wallpapers/"
mkdir -p "$walldir"
count=0

cleanup() {
    if [ -n "$filename" ]; then
        rm -f "$walldir/$filename"
        printf "\nPartially downloaded image deleted: %s\n" "$filename"
        printf "Downloading Canceled!\n$count wallpapers downloaded!\n"
    fi
    exit 1
}

trap cleanup INT

get_results() {
    curl -s -G "https://wallhaven.cc/api/v1/search" \
        -d "q=$1" \
        -d "sorting=relevance" \
        -d "atleast=1920x1080" \
        -d "page=$2" |
    jq -r '.data[]? | .path'
}

help() {
    printf "Usage: %s [options] <query> [<pages>]\n" "$0"
    printf "Options:\n"
    printf "  --help        Show this help message\n"
    printf "  --target-file <file>  Specify a custom target file or directory\n"
    printf "  Default target:  ~/Wallpapers"
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --help)
            help
            ;;
        --target-file)
            walldir="$2"
            shift
            ;;
        *)
            break
            ;;
    esac
    shift
done

query="$1"
[ -z "$query" ] && {
    printf "Query Not Specified\n" >&2
    exit 1
}
pages="${2:-1}"

for ((page = 1; page <= pages; page++)); do
    printf "Page Load %d...\n" "$page"
    while read -r url; do
        filename=$(basename "$url")
        if [ -e "$walldir/$filename" ]; then
            printf "Skip: %s (Already downloaded)\n" "$filename"
        else
            cd "$walldir" && wget -q --show-progress -O "$filename" "$url"
            ((count++))
        fi
    done < <(get_results "$query" "$page")
done

printf "Download Complete!\n$count wallpapers downloaded!\n"
