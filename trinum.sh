#!/usr/bin/env bash
NUM=$1

j=1
k=1

for i in $(seq 1 $NUM)
do
	printf "%5i :: %5i\n" $i $k
	((j++))
	k=$((k+j))
done


