#!/bin/bash
# Recursively removes broken symlinks.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo "Recursively removes broken symlinks."
    echo "Usage:     `basename $0` <directory> <depth>"
    echo "Examples:  `basename $0` ./ 0"
    echo "              ...will remove all broken symlinks recursively in whole dir-tree."
    echo "           `basename $0` ./ 2"
    echo "              ...will remove all broken symlinks up to dir-level 2."
    echo ""
    exit 1
}


[ "$2" = "" ] && Usage

dir="$1"
depth="$2"

echo -n "`basename $0`: removing all broken symlinks under '$dir' ... "

if [ ! -d $dir ] ; then echo "`basename $0`: '$dir' does not exist." ; exit 1 ; fi
if [ $depth -gt 0 ] ; then 
  maxdepth="-maxdepth $depth"
  echo "up to level $depth."
elif [ $depth -eq 0 ] ; then
  maxdepth=""
  echo ""
fi

find $dir -mindepth 1 $maxdepth -type l ! -exec test -e {} \; -exec echo deleting {} \; -exec rm {} \;

echo "`basename $0`: done."

