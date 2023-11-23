#!/bin/bash
shopt -s extglob
# Vars
MAX_PAGES=2  # max number of results pages to parse when searching
SEARCH_DIR="$(dirname $(readlink -e $0))"
# Functions
search() {
    # Ask for Torrent query
    killall -q rofi
    # echo "Searching..." 1>&2
    query="$(rofi -l 0 -dmenu -p "Enter Torrent Query")"
    # query="$(dmenu -p "Enter Torrent Query" < /dev/null)"
    [[ -z "$query" ]] && exit 1 # no query
    # echo "$query"
    # Search specific sites for resutls
    results=$(mktemp)
    # results="/home/sidreed/Projects/torrent.sh/results.tmp"
    "$SEARCH_DIR"/search_kickass.sh "$query" "$MAX_PAGES" >> "$results" 
    # echo "Got kickass results" 1>&2
    "$SEARCH_DIR"/search_1337x.sh "$query" "$MAX_PAGES"  >> "$results"  
    # echo "Got 1337x results" 1>&2
    formatted_results="$(mktemp)"
    # formatted_results="/home/sidreed/Projects/torrent.sh/formatted_results.tmp"
    # Get ID and Hash to dedup torrente between sites
    ids="$(seq 001 "$(wc -l "$results" | cut -d' ' -f1)")"  
    hashes="$(cut -f1 $results | sed -e 's/^.*btih:\([A-Z0-9]*\).*$/\1/')" 
    # Allow user to pick which torrents to download
    paste <(echo "$hashes") <(echo "$ids") $results \
            | sort -t$'\t' -k1,1 -u \
            | cut -f 2- \
            | tr -s ' ' \
            | sort -t$'\t' -k5 -gr >| $formatted_results  
    # cat $formatted_results
    # Exit if no torrent Info was fetched
    if [[ "$(wc -l $formatted_results | cut -d' ' -f1)" -lt 2 ]]; then  
        rofi -dmenu -l 1 -width 80 -p "no results for $query"  
        exit 0
    fi
    # Allow to chose torrents
    chosen="$(cut -f1,3- "$formatted_results" \
              | sed 's/ *\(\t\) */\1|/g' \
              | column -s$'\t' -t \
              | rofi -dmenu -multi-select -l 25 -theme-str 'window {width:90%;}' -p "Pick Torrent")"
        # | dmenu -i -l 25 -fn "Ubuntu-18" -p "Pick Torrent")"
    [[ -z "$chosen" ]] && echo "no queries selected, exiting" && exit 0  
    # Print all chosen results to stdout for downloading
    chosen_ids="$(echo "$chosen" \
                  | cut -d'|' -f1 \
                  | tr -d ' ' \
                  | tr '\n' '|' \
                  | sed -E 's/\|$//')"
    # echo "Chosen IDs"
    # echo "$chosen_ids"
    # Print already formated magnet links
    # echo -e "\nFormatted links"
    grep -P "^($chosen_ids)\t" "$formatted_results" | cut -f2  | grep '^magnet'
    # Parse HTML tags to extract magnet links and print
    # echo -e "\nUnformatted links"
    # grep -E "^($chosen_ids)\t" "$formatted_results" | cut -f2  | grep -v '^magnet' 
    # echo -e "\nFormatted Unformatted links"
    grep -P "^($chosen_ids)\t" "$formatted_results" | cut -f2  | grep -v '^magnet' | grep -o -E "href=[\"'](.*)[\"'] " | grep -o -E "magnet\:.*$"
    # send notification of how many torrents downloaded
    total="$(wc -l $formatted_results | cut -d' ' -f1)"
    if [[ $total -eq 1 ]]; then
        name="$(head -1 "$chosen" | rev | cut -f1 | rev | tr -s ' ' '.')"
        notify-send "Found: $name"  # query link was found
    else
        links_added="$(echo "$chosen" | wc -l | cut -d' ' -f1)"
        notify-send "Query: $query, Links added: $links_added"  # how many links found
    fi
}
# Main
search
