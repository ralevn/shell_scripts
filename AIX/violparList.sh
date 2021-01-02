#!/bin/bash

#set -vx

################################################################
#
#  
#
################################################################

SSHKEY='/root/shell/crontab/HMCscanner/id_dsa_hmcauth'
HMCIPADDR='10.55.40.220'

datetime=$(date +%d%m%Y-%H:%M)
log_file="lparlistTmp.html.log"

out_dir="/Data/httpd"
out_html_filename="lparlistTmp.html"

HMCCMD="sudo ssh hscroot@slphmc73 -i /root/shell/crontab/HMCscanner/id_dsa_hmcauth"

##################################################
# output the beginning of the html page
echo "${datetime} [INFO]: start generating html page ${out_dir}/${out_html_filename}" >$log_file

cat <<'_EOF' > ${out_dir}/${out_html_filename}
<html>
<head>
<title>LPAR List on vlpadm01</title>
<p><IMG ALIGN=top SRC=/images/topbar.gif ALT="IBM System Admin Web" TITLE="IBM System Admin Web"><BR></p>
</head>
<body><BR><DIR><FONT FACE="Arial, sans-serif">
<h1>LPAR List on vlpadm01</h1>
<p>This HTML rendition of the /etc/IBMtools/lpars.list file was Created on Thu Jun  1 03:41:08 CEST 2017</p><BR>
<table border="0" cellspacing="1">

_EOF
#################################################

for msg_sys in $($HMCCMD lssyscfg -r sys -F name 2>/dev/null) 
	do
		cat <<'_EOF' >> ${out_dir}/${out_html_filename}
		<tr><td>${msg_sys}</td></tr>
_EOF
	done

cat <<'_EOF' >> ${out_dir}/${out_html_filename}
</table>
<p>If the IP name is "unknown" this means the LPAR does not communicate with the HMC for DLPAR operations
</body></html>
_EOF
