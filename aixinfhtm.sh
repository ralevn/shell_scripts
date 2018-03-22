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
#        
#   echo $(hmccmd "lssyscfg -r lpar -m G2-P780.7-01-9179-MHD-SN65B5E1C --filter lpar_ids=$lparid -F name os_version" 2>/dev/null) # name os_version
#    echo $(hmccmd "lspartition -c 9179-MHD_65B5E1C -ix |sed 's/;/\n/g'" 2>/dev/null| awk -F "," '$1 == 2 {print $2}') #  

out_dir="$(pwd)"
out_html_filename="lpar_list.html"

hmcCmd="sudo ssh hscroot@slphmc73 -i /root/shell/crontab/HMCscanner/id_dsa_hmcauth"
# prtform="%-34s %-3s %-10s %-14s %-25s %-16s \n"
# $hmcCmd "lssyscfg -r sys -F name type_model serial_num" 2>/dev/null|sed 's/ /_/2' > frames.lst
##########################################
# for frame in $(awk '{print $1}' frames.lst);
# do 
#	echo -e "\n"$frame
#	$hmcCmd lssyscfg -r lpar -m $frame -F name,lpar_id,lpar_env,state,os_version,rmc_ipaddr 2>/dev/null
# done > lpars.lst;
#
# awk -F, -v form="$prtform" '{printf form, $1,$2,$3,$4,$5,$6}' lpars.lst
##########################################

cat <<_EOF > ${out_dir}/${out_html_filename}
<!doctype html>

<html>
<head>
<style>
table, th, td {
	font-family: courier new;
	font-size: 90%;
    	border: 1px solid grey;
	border-collapse: collapse;
	padding: 4px;
}
p {
	font-family: Verdana;
	font-size: 90%;
h3 {
	font-family: Verdana;
	font-size: 95%;
}
h4 {
	font-family: Verdana;
	font-size: 91%;
}

</style>

</head>

<body>


<h3>LPAR List</h3>

_EOF

cat <<_EOF >> ${out_dir}/${out_html_filename}
<p>date: $(date '+ %B %d, %Y')</p>
<table>
<tr><th>Frame Name</th><th>LPAR name</th><th>LPAR #</th><th>Environment</th><th>State</th><th>OS</th><th>IP</th></tr>
_EOF

for frame in $($hmcCmd lssyscfg -r sys -F name 2>/dev/null);
	do
		$hmcCmd lssyscfg -r lpar -m $frame -F name,lpar_id,lpar_env,state,os_version,rmc_ipaddr 2>/dev/null|while IFS=, read name id env state os ip
		do
		cat <<EOF >> ${out_dir}/${out_html_filename}
        	<tr><td>${frame}</td><td>${name}</td><td>${id}</td><td>${env}</td><td>${state}</td><td>${os}</td><td>${ip}</td></tr>
EOF
		done
        cat <<EOF >> ${out_dir}/${out_html_filename}

EOF
	done

cat <<'EOF' >> ${out_dir}/${out_html_filename}
</table>

</body>
</html>

EOF

