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
#    echo $(hmccmd "lssyscfg -r lpar -m G2-P780.7-01-9179-MHD-SN65B5E1C --filter lpar_ids=$lparid -F name os_version" 2>/dev/null) # name os_version
#    echo $(hmccmd "lspartition -c 9179-MHD_65B5E1C -ix |sed 's/;/\n/g'" 2>/dev/null| awk -F "," '$1 == 2 {print $2}') #  

out_dir="/Data/httpd"
out_html_filename="lpar_list.html"

hmcCmd="sudo ssh hscroot@slphmc73 -i /root/shell/crontab/HMCscanner/id_dsa_hmcauth"
prtform="%-34s %-3s %-10s %-14s %-25s %-16s \n"

$hmcCmd "lssyscfg -r sys -F name type_model serial_num" 2>/dev/null|sed 's/ /_/2' > frames.lst

##########################################
for frame in $(awk '{print $1}' frames.lst);
do 
	echo -e "\n"$frame
	$hmcCmd lssyscfg -r lpar -m $frame -F name,lpar_id,lpar_env,state,os_version,rmc_ipaddr 2>/dev/null
done > lpars.lst;

awk -F, -v form="$prtform" '{printf form, $1,$2,$3,$4,$5,$6}' lpars.lst
##########################################

cat <<'EOF' > ${out_dir}/${out_html_filename}
<!doctype html>

<html>
<head>
        <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" rel="stylesheet">
</head>

<body>

<div id="data" class="container">

<h2><i class="fa fa-exchange"></i>HMC DLPAR reports</h2>

EOF

for frame in $(awk '{print $1}' frames.lst);
	do
        cat <<EOF >> ${out_dir}/${out_html_filename}
        <h3>Managed system ${frame}</h3>
        <table id="table" class="table table-hover">
        <tr id="header"><th>LPAR name</th><th>LPAR id</th><th>Environment</th><th>State</th><th>OS</th><th>IP</th></tr>

		cat lpars.lst|while IFS=, read name id env state os ip
		do
			 cat <<EOF >> ${out_dir}/${out_html_filename}
        	<tr><td>${name}</td><td>${id}</td><td>${env}</td><td>${state}</td><td>${os}</td><td>${ip}</td></tr>
		EOF
		done
	done

cat <<'EOF' >> ${out_dir}/${out_html_filename}
</div>

</body>
</html>

<style>

.fa-line-chart {
        margin-right: 20px;
}

#data {
        margin-top: 50px;
}

#table {
        margin-top: 50px;
}

#header {
        font-weight: bold;
}

.fa-download {
        color: #333;
}

</style>
EOF
