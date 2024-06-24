#!/bin/bash

# Directory to store downloaded wallpapers
walldir="${HOME}/Wallpapers/"
mkdir -p "$walldir"
count=0

# Function to clean up and exit script
cleanup() {
    if [ -n "$filename" ]; then
        rm -f "$walldir/$filename"
        printf "\nPartially downloaded image deleted: %s\n" "$filename"
        printf "Downloading Canceled!\n$count wallpapers downloaded!\n"
    fi
    exit 1
}

# Trap interrupt signal to call cleanup function
trap cleanup INT

# Function to fetch search results from Wallhaven API
get_results() {
    curl -s -G "https://wallhaven.cc/api/v1/search" \
        -d "q=$1" \
        -d "sorting=relevance" \
        -d "atleast=1920x1080" \
        -d "page=$2" |
    jq -r '.data[]? | .path'
}

# Check if query is provided as argument
query="$1"
[ -z "$query" ] && {
    printf "Query Not Specified\n" >&2
    exit 1
}

# Set default value for pages if not provided
pages="${2:-1}"

# Loop through pages to download wallpapers
for ((page = 1; page <= pages; page++)); do
    printf "Page Load %d...\n" "$page"
    # Read results from get_results function and process each URL
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
