#!/bin/bash

Usage() {
    echo ""
    echo "Usage: `basename $0` <dir>"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

for i in warn error segfault segmentation rejected oops denied fail cannot critical panic usage ; do
    grep -i -n -R  $i $1 --color=auto
done

echo "`basename $0`: done."

