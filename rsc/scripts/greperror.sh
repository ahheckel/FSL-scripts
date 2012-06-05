#!/bin/bash

Usage() {
    echo ""
    echo "Usage: `basename $0` <dir>"
    echo ""
    exit 1
}

if [ "$1" = "" ] ; then
  dir="./"
else
  dir="$1"
fi

for i in warn error segfault fault rejected oops denied fail cannot critical panic usage ; do
    grep -i -n -R  $i $dir --color=always | grep -v -i default
done

echo "`basename $0`: done."

