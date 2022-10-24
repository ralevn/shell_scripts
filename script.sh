#! /bin/sh

function info () {
echo "Your computer name is  : $(hostname)"
echo "You are logged as      : $USER"
echo "Your process is        : $$"
echo "Your home is           : $HOME"
echo "Your shell is          : $SHELL"
echo "Your current dir is    : $PWD"
echo "Your previous dir was  : $OLDPWD"
}

info 
