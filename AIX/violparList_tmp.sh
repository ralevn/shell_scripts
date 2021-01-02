#!/bin/bash

hmcCmd="sudo ssh hscroot@slphmc73 -i /root/shell/crontab/HMCscanner/id_dsa_hmcauth"

machf=$1
lparf=$2
fields="lpar_name,slot_num,remote_lpar_name,remote_slot_num,wwpns"
fmt1="%-10s%4i %-30s %4i %12s : %12s\n"

function prtForm {

awk -F, -v arg=$1 -v form="$2" '
        $3==arg {
        printf form, $3, $4, $1, $2, $5, $6
        }'
}


$hmcCmd "lshwres -r virtualio --rsubtype fc --level lpar -m $machf -F $fields" 2>/dev/null|prtForm $lparf "$fmt1"
