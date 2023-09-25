#!/usr/bin/env bash

endless () {
	i=1
	while true
	do echo -en "      #   $i   #\r" 
		((i++))
		sleep 1
	done
}

ctrl_count=0
interrupf () {
	((ctrl_count++))
	echo
	if [[ $ctrl_count == 1 ]]; then
		echo " CTRL+C Pressed Once"
	elif [[ $ctrl_count == 2 ]]; then
		echo " CTRL+C Pressed Twice"
	else echo "Quitting ..."
		exit
	fi
}


trap interrupf SIGINT
endless
