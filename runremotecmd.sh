#!/usr/bin/env bash 

# Runs with the owner of script user and assumes ssh keys are exchanged

RED=$'\e[0;31m'
CYAN=$'\e[0;36m'
BLUE=$'\e[0;34m'
WHITE=$'\e[1;37m'
GREY=$'\e[0;37m'
YELLOW=$'\e[0;33m'
GREEN=$'\e[1;32m'
NC=$'\e[0m'

HOSTS_FILE=$1
CMD_FILE=$2

EXECF () {
	host=$1
	while read cmd
	do
		echo "($GREEN$host :$WHITE: $cmd$NC)$YELLOW"
		ssh $host 2>/dev/null <<< "$cmd"
		echo "$NC"
	done < <(grep -Ev "^$|^#" $CMD_FILE)
	}

while read hst
do
	if (nc -z $hst 22)
	then
		EXECF $hst|grep -v "cockpit.socket"
	else
		echo "Host $WHITE$hst$NC is$RED DOWN$NC"
	fi
done < <(grep -Ev "^$|^#" $HOSTS_FILE)
# echo "$NC"

