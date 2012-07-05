#!/bin/bash

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

for i in warn error segfault fault rejected oops denied fail cannot critical panic usage exception ; do
    grep -i -I -n -H -R  $i $searchpath | grep -v -i default | grep -i -I -n -H -R  $i $searchpath --color=auto 
done

echo "`basename $0`: done."

