#!/bin/bash

out_dir="$(pwd)"
out_html_filename="lpar_errlog.htm"

TIMEOUT=10
CMD="errpt|sed -e 's/ \{1,\}/,/1' -e 's/ \{1,\}/,/1' -e 's/ \{1,\}/,/1' -e 's/ \{1,\}/,/1' -e 's/ \{1,\}/,/1'"

# HTML meta info
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

<h3>Server Errors</h3>
<p>date: $(date '+ %B %d, %Y')</p>

<table>

_EOF

### produce csv file with lparsErrpt.csv 

echo -n "" > lparsErrpt.csv
for srv in $(awk -F , '/Running/ {print $2}' lpars1.csv)
	do      
		sudo ssh -o ConnectTimeout=$TIMEOUT ibmssh@$srv $CMD |while IFS=, read errID errTS errTY errCL errRN errDESC
		do 
			if [ $? != 0 ]; then
				echo -e "No Connection to $srv"
			fi
		echo $srv,$errID,$errTS,$errTY,$errCL,$errRN,$errDESC >> lparsErrpt.csv
		done
	done
##########################################
# clear table and import new data from csv file
# print out joint view
##########################################
sqlite3 lpars.db "delete from lparserr"

sqlite3 lpars.db << _EOF
.mode csv
.import lparsErrpt.csv lparserr
_EOF


sqlite3 lpars.db << _EOF >> ${out_dir}/${out_html_filename}
.mode html
.header on
select * from lparserr;
_EOF


# HTML closing data
cat <<'EOF' >> ${out_dir}/${out_html_filename}
</table>

</body>
</html>

EOF

