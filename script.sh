#! /bin/sh

function info () {
	echo "Your computer name is (\$hostname)   : $(hostname)"
	echo "You are logged as (\$USER)           : $USER"
	echo "Your process is (\$\$)               : $$"
	echo "Name of the script (\$0)             : $0"
	echo "Your home is (\$HOME)                : $HOME"
	echo "Your shell is (\$SHELL)              : $SHELL"
	echo "Your current dir is (\$PWD)          : $PWD"
	echo "Your previous dir was (\$OLDPWD)     : $OLDPWD"
        echo "this \$BASH_SOURCE[0]                : ${BASH_SOURCE[0]}"
	echo ${BASH_SOURCE[*]}
	echo $(basename $0)
	echo $(dirname $0)
}

info 
