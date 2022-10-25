#!/usr/bin/env bash

# Check supplied parameters
if [ $# -lt 2 ]; then
	echo -e "Usage: seek <path> <search_string> [--print | -p]\n \
      --print  -p : will print files found"
	exit
fi

# Assign variables
toprint=False
underlin="================================="

while [ "$1" != "" ]; do
	if [ -d $1  ]; then 
	       FPATH=$1
           elif [ $1 == "--print" -o $1 == "-p"  ]; then
               toprint=True
           else
               FSTRING=$1		
        fi
        shift
done

# Summarise input
printf "%-18s : %s\n%-18s : %s\n%-18s : %s\n$underlin\n" \
       "Search Path" ${FPATH:="Issue"} "Searched string" ${FSTRING:="Issue"} "Print files" ${toprint:="Issue"}

# Produce Output
if [ $toprint == "True" ]; then
	find $FPATH -type f  -exec grep -qI $FSTRING {} \; -exec echo -e "\nFILE: {}:\n$underlin" \; -exec cat {} \;
else
	find $FPATH -type f  -exec grep -qI $FSTRING {} \; -print
fi


