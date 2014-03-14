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
    echo "Usage:     `basename $0` <directory> <depth> <reportonly:0|1>"
    echo "Examples:  `basename $0` ./ 0"
    echo "              ...removes all broken symlinks in whole dir-tree."
    echo "           `basename $0` ./ 2"
    echo "              ...removes all broken symlinks up to dir-level 2."
    echo "           `basename $0` ./ 2 1"
    echo "              ...reports all broken symlinks up to dir-level 2 (no deletions)."
    echo ""
    exit 1
}


[ "$2" = "" ] && Usage

dir="$1"
depth="$2"
reportonly="$3"
if [ x"$3" = "x" ] ; then
  reportonly=0
fi

if [ $reportonly -eq 1 ] ; then
  echo -n "`basename $0`: reporting all broken symlinks under '$dir' ... "
else
  echo -n "`basename $0`: removing all broken symlinks under '$dir' ... "
fi

if [ ! -d $dir ] ; then echo "`basename $0`: '$dir' does not exist." ; exit 1 ; fi
if [ $depth -gt 0 ] ; then 
  maxdepth="-maxdepth $depth"
  echo "up to level $depth."
elif [ $depth -eq 0 ] ; then
  maxdepth=""
  echo ""
fi

if [ $reportonly -eq 1 ] ; then
  find $dir -mindepth 1 $maxdepth -type l ! -exec test -e {} \; -exec echo {} \;
else
  find $dir -mindepth 1 $maxdepth -type l ! -exec test -e {} \; -exec echo deleting {} \; -exec rm {} \;
fi

echo "`basename $0`: done."

