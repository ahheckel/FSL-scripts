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

for i in warn error segfault fault rejected oops denied fail cannot critical panic usage ; do
    grep -i -I -n -H -R  $i $searchpath --color=always | grep -v -i default
done

echo "`basename $0`: done."
