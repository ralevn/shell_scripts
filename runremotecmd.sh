#!/usr/bin/env bash 

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

mapfile -t HOSTS < $HOSTS_FILE


EXECF () {
	host=$1
	while read cmd
	do
		echo "($GREEN$host :$WHITE: $cmd$NC)$YELLOW"
		ssh $host 2>/dev/null <<< "$cmd"
		echo "$NC"
	done < <(grep -Ev "^$|^#" $CMD_FILE)
	}

for hst in $HOSTS
do 
	EXECF $hst 2>/dev/null|grep -v "cockpit.socket"
done

