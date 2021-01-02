#!/bin/bash

out_dir="$(pwd)"
out_html_filename="lpar_ref.html"

hmcCmd="sudo ssh hscroot@slphmc73 -i /root/shell/crontab/HMCscanner/id_dsa_hmcauth"


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
<p>date: $(date '+ %B %d, %Y')</p>

<table>

_EOF

# aixinfcsv.sh produces 3 files frames.lst lpars1.csv (output of lssyscfg) and lpars2.csv (output of lspartition -c mtmsn -ix
# then creates joint tables from lpars2.csv and lpars1.csv in lpras.db 
# /bin/bash lparsinfcsv.sh

sqlite3 lpars.db << _EOF >> ${out_dir}/${out_html_filename}
.mode html
.header on
select frame,lpar,hostname,environment,state,osversion,one.lparip from lpars1 as one inner join lpars2 as two on one.lparip=two.lparip;
_EOF

cat <<'EOF' >> ${out_dir}/${out_html_filename}
</table>

</body>
</html>

EOF

