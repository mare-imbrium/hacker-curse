#!/usr/bin/env bash
# ----------------------------------------------------------------------------- #
#         File: hacker.sh
#  Description: download hacker news entries or reddit entries for a subreddit
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2014-07-28 - 11:29
#      License: MIT
#  Last update: 2014-07-30 11:46
# ----------------------------------------------------------------------------- #
#  hacker.sh  Copyright (C) 2012-2014 j kepler
#  Last update: 2014-07-30 11:46


set -euo pipefail

pages=1
today=$(date +"%Y-%m-%d-%H%M")
echo $today
curdir=$( basename $(pwd))

while [[ "$1" = -* ]]; do
case "$1" in
    -H|--hostname)   shift
                     hostname=$1
                     shift
                     ;;
    -p|--pages)   shift
                     pages=$1
                     shift
                     ;;
    -o|--outputfile)   shift
                     outputfile=$1
                     shift
                     ;;
    -h|--help)
cat <<!
$0 Version: 0.0.1 Copyright (C) 2014 jkepler
This program downloads the latest page from Hacker News or reddit news
and parses it into a TSV file.
!
        # no shifting needed here, we'll quit!
        exit
    ;;
    --source)
        echo "this is to edit the source "
        vim $0
        exit
    ;;
    *)
        echo "Error: Unknown option: $1" >&2   # rem _
        echo "Use -h or --help for usage"
        exit 1
        ;;
esac
done

if [ $# -eq 0 ]
then
    echo "I got no filename"
    exit 1
else
    echo "Got $1"
fi
subr=${1:-"news"}
outputfile=${outputfile:-"$subr.tsv"}
outputhtml=${html:-"$subr.html"}
outputhtml=$( echo $outputhtml | sed "s/\//__/g" )
outputfile=$( echo $outputfile | sed "s/\//__/g" )

echo "subreddit is: $subr "

case "$subr" in
    "news")
        hacker-tsv.rb -H hn -p $pages -s news -w news.html > $outputfile
        ;;
    "newest")
        hacker-tsv.rb -H hn -p $pages -s newest -w newest.html > $outputfile
        ;;
    "ruby")
        hacker-tsv.rb -H rn -p $pages -s ruby -w ruby > $outputfile
        ;;
    "programming")
        hacker-tsv.rb -H rn -p $pages -s programming -w $outputhtml > $outputfile
        ;;
    *)
        hostname=${hostname:-"rn"}
        hacker-tsv.rb -H "$hostname" -p $pages -s "$subr" -w $outputhtml > $outputfile
        ;;
esac
ls -ltrh $outputfile
