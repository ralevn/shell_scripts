#!/usr/bin/env bash 

RED=$'\e[0;31m'
YELLOW=$'\e[0;33m'
CYAN=$'\e[0;36m'
BLUE=$'\e[0;34m'
WHITE=$'\e[1;37m'
GREY=$'\e[0;37m'
GREEN=$'\e[0;32m'
NC=$'\e[0m'

HOSTS_FILE=$1
CMD_FILE=$2

mapfile -t HOSTS < $HOSTS_FILE
mapfile CMDS < $CMD_FILE

EXECF () {
	host=$1
	while read cmd
	do
		echo "$GREEN$host :$WHITE: $cmd $YELLOW"
		ssh $host 2>/dev/null <<< $cmd
		echo -n "$NC"
	done <<< ${CMDS[*]}
	}

for hst in $HOSTS
do 
	EXECF $hst 2>/dev/null|grep -Ev "^$|cockpit.socket"
done

