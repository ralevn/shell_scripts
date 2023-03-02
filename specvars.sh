#! /bin/sh

echo "Number of supplied arguments (\$#):  $#"
echo "List of provided arguments (\$@):    $@"
echo "List of provided arguments (\$*):    $*"   


for var in pattern, before, after, file; do
	var=$1
	echo "== $var =="
        shift
done
