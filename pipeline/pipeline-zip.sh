#!/bin/bash

if [ ! -d "$1/$2" ]
then
  mkdir "$1/$2"
fi

if [ ! -f "$1/$2/sshkey" ]
then
  cp -p "$1/sshkey" "$1/$2/sshkey" && cp -p "$1/sshkey.pub" "$1/$2/sshkey.pub"
  if [ $? -ne 0 ]
  then
      >&2 echo "No SSH key found. Can not update modules."
      #exit 2
  fi
fi

cp -pf ${path.module}/pipeline/ "$1/$2/"


echo '{"result":"success"}' 
