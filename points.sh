#!/bin/bash

while true;do echo $(date) >/tmp/dates;sleep 10;done

pid=$!

while [ kill -0 $pid ] ;do echo -n ".";sleep 2;done
