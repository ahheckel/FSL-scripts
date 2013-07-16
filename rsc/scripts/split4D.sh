#!/bin/bash
# Splits 4D volume in 4Ds of size n.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/31/2013

set -e

trap 'echo "$0 : An ERROR has occured."' ERR
    
Usage() {
    echo ""
    echo "Usage:   `basename $0` <input4D> <size> <output4D>"
    echo "Example: `basename $0` in 128 out"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# assign input arguments
input=$(remove_ext "$1")
n=$2
output=$(remove_ext "$3")

# declare vars
nvols=`fslinfo $input | grep ^dim4 | awk '{print $2}'`
iter=$(echo "scale=0 ; $nvols / $n" | bc -l)

# check
_nvols=$(echo "scale=0; $iter*$n" | bc -l)
resid=$(echo "scale=0; $nvols - $_nvols" | bc -l)
if [ $resid -gt 0 ] ; then echo "`basename $0`: WARNING: last 4D ('${output}_$(zeropad $iter 3)') will only have $resid volumes (not $n)." ; fi

# execute
echo "`basename $0`:"
for i in `seq 0 $[$iter-1]` ; do
  tmin=$(echo "scale=0; $i*$n" | bc -l)
  cmd="fslroi $input ${output}_$(zeropad $i 3) $tmin $n"
  echo "    $cmd" ; $cmd
done
if [ $resid -gt 0 ] ; then
  i=$[$i+1]
  tmin=$(echo "scale=0; $i*$n" | bc -l)
  cmd="fslroi $input ${output}_$(zeropad $i 3) $tmin $resid"
  echo "    $cmd" ; $cmd
fi

# done
echo "`basename $0`: done."
