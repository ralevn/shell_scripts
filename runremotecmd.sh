#!/usr/bin/env bash 

RED=$'\e[0;31m'
CYAN=$'\e[0;36m'
BLUE=$'\e[0;34m'
WHITE=$'\e[1;37m'
GREY=$'\e[0;37m'
NC=$'\e[0m'

HOSTS_FILE=$1
CMD_FILE=$2

mapfile -t HOSTS < $HOSTS_FILE
mapfile CMDS < $CMD_FILE


EXECF () {
	host=$1
	while read cmd
	do
		echo "COMMAND: $WHITE$cmd $GREY"
		ssh $host 2>/dev/null <<< $cmd
		echo "$NC"
	done <<< ${CMDS[*]}
	}

for hst in $HOSTS
do 
	EXECF $hst 2>/dev/null|grep -v "cockpit.socket"
done

