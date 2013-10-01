#!/bin/bash
# i) Splits 4D volume in 4Ds of size n or ii) splits 4D volume according to split-vector and merges the split.

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
    echo "         `basename $0` <input4D> <vector> <output4D>"
    echo "Example: `basename $0` in 128 out"
    echo "         `basename $0` in [0:2:end-1] out"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files
#tmpdir=/tmp/$(basename $0)_$$
#mkdir -p $tmpdir

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# assign input arguments
input=$(remove_ext "$1")
n="$2"
output=$(remove_ext "$3")

# check
if [ $(imtest $input) -eq 0 ] ; then echo "`basename $0`: Cannot read '$input'... exiting." ; exit 1 ; fi

# declare vars
nvols=`fslinfo $input | grep ^dim4 | awk '{print $2}'`

# scalar or vector ?
if [ $(echo $n | grep : | wc -l) -eq 1 ] ; then
  vector=1
  n=$(echo $n | sed "s|end|$[$nvols-1]|g")
  field1=$(echo $n | cut -d : -f 1 | cut -c 2-); field1=$[$field1]
  field2=$(echo $n | cut -d : -f 2); field2=$[$field2]
  field3=$(echo $n | cut -d : -f 3 | cut -c 1- | cut -d ] -f 1); field3=$[$field3]
else
  vector=0
fi

if [ $vector -eq 0 ] ; then
  iter=$(echo "scale=0 ; $nvols / $n" | bc -l)
  if [ $iter -eq 0 ] ; then echo "`basename $0`: ERROR: only $nvols voulmes in '$input'. Exiting." ; exit 1 ; fi

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
  
elif [ $vector -eq 1 ] ; then
  echo "`basename $0`: split-vector: [$field1:$field2:$field3] ; nvols: $nvols"
  # split
  fslsplit $input ${tmpdir}/$(basename $output)_tmp
  full_list=`imglob ${tmpdir}/$(basename $output)_tmp????.*`

  i=0 ; files="" ; err=0
  for i in `seq $field1 $field2 $field3` ; do
    file=${tmpdir}/$(basename $output)_tmp$(zeropad $i 4)
    if [ $(imtest $file) -eq 0 ] ; then echo "`basename $0`: ERROR: Cannot read '$file'..." ; err=1 ; fi
    files=$files" "$file
  done
  if [ $err -eq 1 ] ; then echo "`basename $0`: Exiting..." ; exit 1 ; fi
  cmd="fslmerge -t $output $files"
  echo "    $cmd" ; $cmd
fi

# done
echo "`basename $0`: done."
