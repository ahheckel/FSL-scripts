#!/bin/bash

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 25/03/2014

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:    `basename $0` <zipfile> <destination-dir(default: ~/FSL-scripts)>"
    echo "Example:  `basename $0` Downloads/FSL-scripts-from-github.zip ~/FSL-scripts"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

if [ $(echo "$1" | grep \( | wc -l) -gt 0 ] ; then
  zipfile=$(dirname "$1")/$(echo $(basename "$1") | sed "s|(.)||g")
  mv "$1" $zipfile
else
  zipfile="$1"
fi
destdir="$2"

wd=`pwd`

if [ x"$destdir" = "x" ] ; then destdir="~/FSL-scripts" ; fi

if [ ! -f "$zipfile" ] ; then 
  echo "$(basename $0): ERROR: File '$zipfile' does not exist! Exiting..."
  exit 1
fi

cd $(dirname $zipfile)
  folder=${zipfile%.zip}
  if [ -d "$folder" ] ; then
    read -p "Press key to delete directory '`pwd`/$folder'..."
    rm -r "$folder"
  fi
  unzip $(basename $zipfile)
cd "$wd"

if [ ! -d "$folder" ] ; then 
  echo "$(basename $0): ERROR: Folder '$folder' does not exist! Exiting..." ; exit 1
else
  echo "Execute:"
  echo "rsync -avzb --delete --backup-dir=../backup/$(basename $destdir) $folder/ $destdir/"
fi
