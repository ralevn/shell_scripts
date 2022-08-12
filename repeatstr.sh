#!/usr/bin/env bash 

error="syntax repeatstr.sh \"string\" number \n
string - the string to be repeated \n
number - times to be repeated"

if [[ $# -ne 2  ]]; then
	echo -e $error
fi

str=$1
count=1
limit=$2


while [[ $count -le ${limit} ]]
	do echo -en "$str"
		((count ++))
	done
echo
