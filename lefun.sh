#!/bin/bash
le() {

if [ $# -eq 0 ];  then
       stat -c "%a %h %U %G %s %n" ${PWD}/*|column -t
fi
if [ $# -eq 1 ]; then path=$1
       if [ -d $path  ]; then
              stat -c "%a %h %U %G %s %n" ${path}|column -t
              stat -c "%a %h %U %G %s %n" "${path}"/*|column -t
       fi
       if [ -f $path  ]; then
              stat -c "%a %h %U %G %s %n" "${path}"|column -t
       fi
fi
}

#You can put le function in
#/etc/profile.d/ as a shell script and thus have a le command


le $1
