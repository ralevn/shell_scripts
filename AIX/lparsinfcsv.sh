#!/bin/bash

# create MT-M_SN holder for lspartition command from lssyscfg
# create lparid holder for lpar id
# create lparip holder for lpar IP from lspartition command
# create osver holder for lpar OS version from lssyscfg command
##############################################################
# Loop for every frame name:
#    run lssyscfg 
#    echo Frame name 
#    make MT-M_SN
#    lspartition -ix with MT-M_SN
#       Loop for each lparid
#   echo $(hmccmd "lssyscfg -r lpar -m G2-P780.7-01-9179-MHD-SN65B5E1C --filter lpar_ids=$lparid -F name os_version" 2>/dev/null) # name os_version
#    echo $(hmccmd "lspartition -c 9179-MHD_65B5E1C -ix |sed 's/;/\n/g'" 2>/dev/null| awk -F "," '$1 == 2 {print $2}') #  

out_dir="$(pwd)"
out_html_filename="lpar_list.html"

hmcCmd="sudo ssh hscroot@slphmc73 -i /root/shell/crontab/HMCscanner/id_dsa_hmcauth"
prtform="%36-s %-34s %-3s %-10s %-14s %-25s %-16s \n"

##########################################
# create file where second column meets requirement of lspartition command
##########################################

$hmcCmd "lssyscfg -r sys -F name type_model serial_num" 2>/dev/null|sed 's/ /_/2' > frames.lst

##########################################
echo -n "" > lpars1.csv
echo -n "" > lpars2.csv
for frame in $(awk '{print $1}' frames.lst)
do 
	$hmcCmd lssyscfg -r lpar -m $frame -F name,lpar_id,lpar_env,state,os_version,rmc_ipaddr 2>/dev/null|while IFS=, read lname lid lenv lstate los lip
		do
			echo $frame,$lname,$lid,$lenv,$lstate,$los,$lip >> lpars1.csv
		done
done

# awk -F, -v form="$prtform" '{printf form, $1,$2,$3,$4,$5,$6,$7}' lpars1.csv

##########################################
# create csv file with hostnames and IPs
# format: <LParID,IPaddress,active,hostname,OStype,OSlevel;>
##########################################
for mtmsn in $(awk '{print $2}' frames.lst)
do 
	$hmcCmd lspartition -c $mtmsn -ix 2>/dev/null|sed 's/;/\n/g' >> lpars2.csv
done

##########################################
# clear tables and import new data from csv files
# print out joint view
##########################################
sqlite3 lpars.db "delete from lpars2"
sqlite3 lpars.db "delete from lpars1"

sqlite3 lpars.db << _EOF
.mode csv
.import lpars2.csv lpars2
.import lpars1.csv lpars1
_EOF

# sqlite3 -header -column lpars.db "select frame,lpar,hostname,environment,state,osversion,one.lparip from lpars1 as one inner join lpars2 as two on one.lparip=two.lparip;"

