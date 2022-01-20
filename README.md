```
$ transmission.sh -h
    -u) {Ki|Mi|Gi|Ti}
        - specify unit for display

    -m) $mode
        - display modes are {$(echo ${MODES[*]} | tr ' ' '|')}
        Modes   | Description
        --------|---------------------------------------------
        display | display torrent data using default mode
        next    | cycle defualt display mode forward
        prev    | cycle defualt display mode backward
        $mode   | set defualt display mode to $mode
        current | display current default mode
        --------|---------------------------------------------
        search  | search online for a torrent query
        start   | start transmission daemon
        pause   | pause all torrents
        resume  | resume all torrents
        stats   | update up/download stats csv file
        table   | print formatted table of torrents 
        filter  | print table of torrents filtered
                | by criteria i.e. {ratio|done|undone|error}
        del     | deleted torrents by criteria (same as table)
```
