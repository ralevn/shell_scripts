#!/bin/bash

#DEFAULTIFS = $IFS : Only in case Field separator is comma
#IFS = ","           Only in case Field separator is comma

ps -aux|awk '$3 != 0.0 && $4 != 0.0 && NR !=1 {print $1," ",$11}'|while read usr cmd  
do  if [ $usr == "nikira" ]; then  # !!!! IMPORTANT there is space between brackets "[" and content inside
	 printf "%-28s %-40s\n" "You are performing" $cmd 
    else printf "%-28s %-40s\n" "User $usr is performing" $cmd  
    fi
done

#IFS = $DEFAULTIFS   Only in case Field separator is comma
