#!/bin/bash

hmcCmd="sudo ssh hscroot@slphmc73 -i /root/shell/crontab/HMCscanner/id_dsa_hmcauth"

function MTMSN {
	local frame_name=$1
	$hmcCmd "lssyscfg -r sys -F type_model serial_num"|sed 's/ /_/g'
}
