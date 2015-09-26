#!/bin/bash
# Synchronizes installation (default ~/FSL-scripts) with zipped download from git-hub.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 25/03/2014

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:    `basename $0` <zipfile|-1(=download from github)> <destination-dir(default: ~/FSL-scripts)>"
    echo "Example:  `basename $0` Downloads/FSL-scripts-from-github.zip ~/FSL-scripts"
    echo "          `basename $0` -1 ~/FSL-scripts"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

if [ $(echo "$1" | grep \( | wc -l) -gt 0 ] ; then # remove parentheses if present
  zipfile=$(dirname "$1")/$(echo $(basename "$1") | sed "s|(.)||g")
  mv -i "$1" $zipfile
else
  zipfile="$1"
fi
destdir="$2"
if [ x"$destdir" = "x" ] ; then destdir="~/FSL-scripts" ; fi
wd=`pwd`

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# download github zipball
if [ "$zipfile" = "-1" ] ; then
  zipfile="FSL-scripts.zip"
  wget -O $zipfile https://github.com/ahheckel/FSL-scripts/zipball/master  
fi

# check
if [ ! -f "$zipfile" ] ; then 
  echo "$(basename $0): ERROR: File '$zipfile' does not exist! Exiting..."
  exit 1
fi

# unzip
cd $(dirname $zipfile)
  folder=${zipfile%.zip}
  if [ -d "$folder" ] ; then
    read -p "$(basename $0): Press key to delete directory '`pwd`/$folder'..."
    rm -r "$folder"
  fi
  unzip $(basename $zipfile)  
cd "$wd"

# display rsync command
if [ ! -d "$folder" ] ; then 
  echo "$(basename $0): ERROR: Folder '$folder' does not exist! Exiting..." ; exit 1
else
  echo "$(basename $0): Execute:"
  echo "rsync -avzb --delete --backup-dir=../backup/$(basename $destdir) $folder/ $destdir/"
fi
