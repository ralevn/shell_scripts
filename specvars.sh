#! /bin/sh

echo "Number of supplied arguments (\$#):  $#"
echo "List of provided arguments (\$@):    $@"
echo "List of provided arguments (\$*):    $*"   
n=$#

while [ "$1" != "" ]; do
	var=$1
	echo "== $var =="
        shift
done
