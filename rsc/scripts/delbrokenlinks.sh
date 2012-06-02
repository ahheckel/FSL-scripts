#!/bin/bash
# Recursively removes broken symlinks.

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo "Recursively removes broken symlinks."
    echo "Usage: `basename $0` <directory>"
    echo ""
    exit 1
}


[ "$1" = "" ] && Usage

echo "`basename $0`: removing all broken symlinks under '$1'..."

if [ ! -d $1 ] ; then echo "`basename $0`: '$1' does not exist." ; exit 1 ; fi

find $1 -type l ! -exec test -e {} \; -exec rm {} \;

echo "`basename $0`: done."

