#!/bin/bash
shopt -s extglob
# Vars
BASE_URL="https://1337x.to"
BASE_SEARCH_URL="$BASE_URL/search"
BASE_RESULT_URL="$BASE_URL"
# Functions
help() {
    echo "Usage: ./$(basename $0) query max_pages"
}
get_results() {
    # download the search results for a torrent query from 1337x.to
    query="$1"
    max_pages="$2"
    search_url="$BASE_SEARCH_URL/${query// /+}/1/"
    total_pages="$(curl -Ss "$search_url" | grep 'Last' | sed -s 's/^.*class=.last.><a href=.\/search\/.*\/\([0-9]*\)\/.>.*$/\1/')"
    [[ $max_pages -lt $total_pages ]] && total_pages=$max_pages
    for page_num in $(seq 1 $total_pages); do
        search_url="$BASE_SEARCH_URL/${query// /+}/$page_num/"
        # echo $search_url 1>&2
        curl -Ss "$search_url" 
    done
}
extract_from_page() {
    # extract information about each torrent from the downloaded html results
    grep "$2" "$1" | sed -e "s/^.*>\([^<>]\+\)<$3.*$/\1/"
    # ${$1} is field, $2 is results page, $3 is the ending tag
    # ^.*  # from start
    # >\([^<>]\+\)< # capture everything between ><
    # \(\/td\|\/a\|span\) # patterns that signal end of info
    # .*$ # rest of the line matched
}
get_links(){
    # parse magnet link from chosen result and echo
    magnets=""
    results="$1"
    links="$(grep '/torrent/' "$results" | sed -e 's/^.*href="\/\(torrent.*\)\/">.*$/\1/')"
    while read link; do
        magnet="$(curl -Ss "$BASE_RESULT_URL/$link/" |\
                  grep 'magnet' | head -1 |\
                  sed -e 's/^.*href="\(magnet[^"<>]*\)".*$/\1/')"
        [[ -n "$magnet" ]] && magnets="$magnets$magnet\n"
    done <<< "$(echo $links | tr ' ' '\n')"
    echo -e "$magnets" 
}
parse_results() {
    # parse downloaded torrent results into a tab delimited table for display
    page="$1"
    sed -i '/<\/th>/d' "$page" # filter crap
    links="$(get_links "$page")"
    names="$(extract_from_page $page 'coll-1 name' '\/a')"
    sizes="$(extract_from_page $page 'coll-4 size' 'span')"
    dates="$(extract_from_page $page 'coll-date' '\/td')"
    seeders="$(extract_from_page $page 'coll-2 seeds' '\/td')"
    leechers="$(extract_from_page $page 'coll-3 leeches' '\/td')"
    paste <(echo "$links") <(echo "$sizes") <(echo "$dates") <(echo "$seeders") <(echo "$leechers") <(echo "$names")
}
main() {
    query="$1"
    max_pages="$2"
    results="$(mktemp)"
    get_results "$query" "$max_pages" >| "$results"
    # wc -l $results 1>&2
    parse_results "$results" | grep -vi 'xxx' # filter porn
    # wc -l $results 1>&2
}
# Main
[[ $# -eq 2 ]] || (help  && exit 1)
query="$1"
max_pages="$2"
main "$query" "$max_pages"
