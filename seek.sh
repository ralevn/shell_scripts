#!/usr/bin/env bash

if [ $# -lt 2 ]; then
	echo -e "Usage: seek.sh <path> <search_string> [-print]\n \
		 -print: will print files found"
	exit
fi

toprint=False

while [ "$1" != "" ]; do
	if [ -d $1  ]; then 
	       FPATH=$1
           elif [ $1 == "-print" -o $1 == "-p"  ]; then
               toprint=True
           else
               FSTRING=$1		
        fi
        shift
done

echo -e "Search Path: $FPATH \nPrint files: $toprint \nSearched string: $FSTRING\n"

underlin="================================="

if [ $toprint == "True" ]; then
	find $FPATH -type f  -exec grep -qI $FSTRING {} \; -exec echo -e "\nFILE: {}:\n$underlin" \; -exec cat {} \;
else
	find $FPATH -type f  -exec grep -qI $FSTRING {} \; -print
fi


