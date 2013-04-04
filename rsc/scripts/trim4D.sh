#!/bin/bash
# Trims 4D volume by removing a specified number of heading and trailing volumes.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/30/2013

set -e

trap 'echo "$0 : An ERROR has occured."' ERR
    
Usage() {
    echo ""
    echo "Usage:   `basename $0` <input4D> <n_head,n_tail> <output4D>"
    echo "Example: `basename $0` in 1,3 out"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# assign input arguments
input=$(remove_ext "$1")
n1=$(echo $2 | cut -d , -f 1)
n2=$(echo $2 | cut -d , -f 2)
output=$(remove_ext "$3")

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files
#tmpdir=/tmp/$(basename $0)_$$
#mkdir -p $tmpdir

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# define temporary file
_tmp=${tmpdir}/$(basename $output)

## check 
#if [ $n1 -eq 0 -a $n2 -eq 0 ] ; then echo "`basename $0`: ERROR: no trimming specified - exiting." ; exit 1 ; fi

# declare vars
nvols=`fslinfo  $input | grep ^dim4 | awk '{print $2}'`
t1=$(echo "scale=0 ; $nvols - $n1" | bc -l)
t2=$(echo "scale=0 ; $nvols - $n1 - $n2" | bc -l)

# execute
echo "`basename $0`:"
if [ $n1 -gt 0 ] ; then
  if [ $n2 -gt 0 ] ; then
    cmd="fslroi $input $_tmp $n1 $t1"
    echo "    $cmd" ; $cmd
    cmd="fslroi $_tmp $output 0 $t2"
    echo "    $cmd" ; $cmd
  elif [ $n2 -eq 0 ] ; then
    cmd="fslroi $input $output $n1 $t1"
    echo "    $cmd" ; $cmd
  fi
elif [ $n1 -eq 0 ] ; then
  cmd="fslroi $input $output 0 $t2"
  echo "    $cmd" ; $cmd
fi

# cleanup
imrm $_tmp 

# done
echo "`basename $0`: done."
