#!/bin/bash

out_dir="$(pwd)"
out_html_filename="hmc_errs.html"

hmcCmd="sudo ssh hscroot@slphmc73 -i /root/shell/crontab/HMCscanner/id_dsa_hmcauth"

cat <<'EOF' > ${out_dir}/${out_html_filename}
<!doctype html>

<html>
<head>
<style>
table, th, td {
    	border: 1px solid black;
	border-collapse: collapse;
	padding: 5px;
}
</style>

</head>

<body>


<h3>LPAR List</h3>

EOF

#for frame in $($hmcCmd lssyscfg -r sys -F name 2>/dev/null);
#	do
#       cat <<EOF >> ${out_dir}/${out_html_filename}
#        <h4>      ${frame}</h4>
#	<table>
#        <tr><th>LPAR name</th><th>LPAR</th><th>Environment</th><th>State</th><th>OS</th><th>IP</th></tr>
#	
#EOF

cat <<EOF>> ${out_dir}/${out_html_filename}
<table>
<tr><th>Problem #</th><th>hmc</th><th>refcode</th><th>status</th><th>create time</th><th>severity</th><th>text</th></tr>
EOF
i=1
maxn='$hmcCmd lssvcevents -t hardware --filter status=Open -F problem_num" 2>/dev/null|wc -l'

while [$i -le $maxn]
do
		$hmcCmd lssvcevents -t hardware --filter status=Open -F problem_num,analyzing_hmc,refcode,status,created_time,event_severity,text 2>/dev/null|while IFS=, read prb hmc refc status time sev txt
		do
			 cat <<EOF >> ${out_dir}/${out_html_filename}
        	<tr><td>${prb}</td><td>${hmc}</td><td>${refc}</td><td>${status}</td><td>${time}</td><td>${sev}</td><td>txt</td></tr>
EOF
		done
        cat <<EOF >> ${out_dir}/${out_html_filename}
        </table>
EOF
	done

cat <<'EOF' >> ${out_dir}/${out_html_filename}
</div>

</body>
</html>

EOF
