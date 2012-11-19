#!/bin/bash
# Cycler.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <'cmd'> <'01 02 03...'> <'A B C...'< <'a b c...'>"
    echo "example: `basename $0` 'ls @^/@^^' '01 02 03' 'a b c'"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage

cmd="$1" ; shift

nlev=$# 
if [ $nlev -gt 4 ] ; then echo "`basename $0` : Sorry, `basename $0` does not support more than 4 levels." ; exit 1 ; fi

a1="$1"
a2="$2"
a3="$3"
a4="$4"

if [ "$a2" = "" ] ; then a2="1" ; fi
if [ "$a3" = "" ] ; then a3="1" ; fi
if [ "$a4" = "" ] ; then a4="1" ; fi


cmd=`echo $cmd | sed 's|@^^^^|\${LLL}|g'`
cmd=`echo $cmd | sed 's|@^^^|\${KKK}|g'`
cmd=`echo $cmd | sed 's|@^^|\${JJJ}|g'`
cmd=`echo $cmd | sed 's|@^|\${III}|g'`

export III JJJ KKK LLL

for III in $a1 ; do
for JJJ in $a2 ; do
for KKK in $a3 ; do
for LLL in $a4 ; do

  sh -c "echo $cmd"
  
done
done
done
done

unset III JJJ KKK LLL

