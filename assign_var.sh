#!/usr/bin/env bash

for i in $@
do
 echo -n "$i "
done
echo
VAR=
while [ "$1" != ""  ]; do
	VAR="$VAR $1"
	echo $#, $VAR
	shift
done

