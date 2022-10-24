#!/usr/bin/env bash

if [ $# -lt 2 -o ! -d $1 ]; then
	echo -e "Usage: seek.sh <path> <search_string> [-print]\n \
		 -print: will print files found"
	exit
fi


FSTRING=$2
FPATH=$1
underlin="================================="

if [ $3 ]; then
	find $FPATH -type f -name "*.y*ml" -exec grep -qI $FSTRING {} \; -exec echo -e "\n* {}:\n$underlin" \; -exec cat {} \;
else
	find $FPATH -type f -name "*.y*ml" -exec grep -qI $FSTRING {} \; -print
fi


