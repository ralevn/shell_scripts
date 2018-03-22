#!/bin/bash

SSHKEY='/root/shell/crontab/HMCscanner/id_dsa_hmcauth'
HMCIPADDR='10.55.40.220'

datetime=$(date +%d%m%Y-%H:%M)
log_file="lparlistTmp.html.log"

#  out_dir="/Data/httpd"
out_dir="."
out_html_filename="lparlistTmp.html"
hmcCmd="sudo ssh hscroot@slphmc73 -i /root/shell/crontab/HMCscanner/id_dsa_hmcauth"

function vioINfo  {
local machf=$1
local lparf=$2
local fields="lpar_name,slot_num,remote_lpar_name,remote_slot_num,wwpns"
local format="%-10s %4i %-29s %4i %12s : %12s\n"

#$hmcCmd "viosvrcmd -m $machf -p $lparf -c 'lsmap -all -npiv -fmt ,'" 2>/dev/null

$hmcCmd "lshwres -r virtualio --rsubtype fc --level lpar -m $machf -F $fields" 2>/dev/null|awk -F, -v arg=$lparf -v form="$format" '$3==arg {printf form,$3,$4,$1,$2,$5,$6}'
}

mach=
lpar=
until [ "$mach" = "0" ]; do
	echo "
List of Machines:
----------------
$($hmcCmd lssyscfg -r sys -F name 2>/dev/null)

0 - Exit "
	echo -n "Choose a machine (use Copy/Paste): "
	read mach
	case $mach in
		0 ) exit
		;;
		* ) until [ "$lpar" = "0" ]; do
        		echo "
List of VIO Servers in $mach:
-----------------------------
$($hmcCmd lssyscfg -r lpar -m $mach -F name lpar_env 2>/dev/null|awk '/vio/ {print $1}')
0 - Return back to List of systems "
			echo -n "Choose a VIO Server (use Copy/Paste): "
			read lpar
			case $lpar in
				0 ) export lpar=;break 
				;;
				* ) vioINfo $mach $lpar
				;;
			esac
		done
	;;
	esac
done

