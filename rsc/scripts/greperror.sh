#!/bin/bash
# Recursively searches directory tree for error related keywords.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

Usage() {
    echo ""
    echo "Usage: `basename $0` <path>"
    echo ""
    exit 1
}

searchpath=""
if [ "$1" = "" ] ; then
  searchpath="./"
else
  for i in $@ ; do
    searchpath=$searchpath" "$i
  done
fi

for i in warn error segfault fault rejected oops denied fail cannot critical panic usage exception bad_alloc ; do
    grep -i -I -n -H -R  $i $searchpath --color=auto 
done

echo "`basename $0`: done."

