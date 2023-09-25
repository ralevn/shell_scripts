
if [ $# != 2  ]; then
	echo "Usage sumab.sh A B where A and B are numbers"
	exit 1
fi

a=$1
b=$2

resulta=$a+$b
resultb=$(($a+$b))

echo $resulta=$resultb
