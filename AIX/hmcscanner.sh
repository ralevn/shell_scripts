#!/bin/bash

################################################################
#
# Create soft links to the
# /root/shell/crontab/HMCscanner/HISTO/2017*_hmcscan_Fractale.xls.gz
# files, in order to generate an html page to be able to
# download them
#
################################################################

datetime=$(date +%d%m%Y-%H:%M)
log_file="AIX_hmcscanner_reports_build_html.log"

in_dir="/root/shell/crontab/HMCscanner/HISTO"
in_filenames=$(ls -trh ${in_dir}/2017*_hmcscan_Fractale.xls.gz)
out_dir="/Data/httpd/hmcscanner/reports"
out_html_filename="hmc_reports.html"

# output the beginning of the html page
echo "${datetime} [INFO]: start generating html page ${out_dir}/${out_html_filename}" > $log_file

cat <<'EOF' > ${out_dir}/${out_html_filename}
<!doctype html>

<html>
<head>
        <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" rel="stylesheet">
</head>

<body>

<div id="data" class="container">

<h3><i class="fa fa-line-chart"></i>HMC reports</h3>

<table id="table" class="table table-hover">
<tr id="header"><th>File name</th><th>Download link</th></tr>
EOF

# create symbolic links to the files in input directory
# and then the individual lines of the html table
for filename in $in_filenames; do
        name="${filename##*/}"
	ln -s ${in_dir}/${name} ${out_dir}/${name} &>/dev/null
cat <<EOF >> ${out_dir}/${out_html_filename}
<tr><td>${name}</td><td><a href="./${name}"><i class="fa fa-download"></i></a></td></td>
EOF
done
echo "${datetime} [INFO]: generated symbolic links" >> $log_file
echo "${datetime} [INFO]: generated individual download lines in html table" >> $log_file

# output the rest of the html page
cat <<'EOF' >> ${out_dir}/${out_html_filename}
</table>
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

echo "${datetime} [INFO]: finished generating html page ${out_dir}/${out_html_filename}" >> $log_file

