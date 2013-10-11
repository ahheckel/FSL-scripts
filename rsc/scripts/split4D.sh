#!/bin/bash
# i) Splits 4D volume in 4Ds of size n or ii) splits 4D volume according to split-vector and merges the split if requested.

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
    echo "         `basename $0` [-m] <input4D> <vector> <output4D>"
    echo ""
    echo "Options: -m    merge extraction to 4D"
    echo ""
    echo "Example: `basename $0` in 128 out"
    echo "         `basename $0` -m in [1,3,5] out"
    echo "         `basename $0` -m in [0:2:end-1] out"
    echo "         `basename $0` -m in [0,2:2:end-1] out"
    echo ""
    exit 1
}

function row2col()
{
  local dat=`cat $1`
  local i=""
  for i in $dat ; do echo $i ; done
}

merge=0 ; if [ "$1" = "-m" ] ; then  merge=1 ; shift ; fi
[ "$3" = "" ] && Usage

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# assign input arguments
input=$(remove_ext "$1")
n="$2"
output=$(remove_ext "$3")

# declare vars
nvols=`fslinfo $input | grep ^dim4 | awk '{print $2}'`

# check input
if [ $(imtest $input) -eq 0 ] ; then echo "`basename $0`: Cannot read '$input'... exiting." ; exit 1 ; fi

# rem commas & brackets & tags
n="$(echo "$n" | sed 's|,| |g')"
n=$(echo $n | sed "s|end|$[$nvols-1]|g")
n=$(echo $n | sed "s|mid|$(echo "$nvols / 2" | bc)|g")
n=$(echo $n | cut -d ] -f 1)
n=$(echo $n | cut -d [ -f 2)

# vector or scalar ?
_n=""
for i in $(echo $n | row2col) ; do
  if [ $(echo $i | grep : | wc -l) -eq 1 ] ; then
     field1=$(echo $i | cut -d : -f 1); field1=$[$field1]
     field2=$(echo $i | cut -d : -f 2); field2=$[$field2]
     field3=$(echo $i | cut -d : -f 3); field3=$[$field3]
     _n=$_n" "$(seq $field1 $field2 $field3)
  else
    _n=$_n" "$[$i]
  fi
done  
if [ $(echo $_n | wc -w) -gt 1 ] ; then vector=1 ; else vector=0 ; fi

if [ $vector -eq 0 ] ; then
  iter=$(echo "scale=0 ; $nvols / $n" | bc -l)
  if [ $iter -eq 0 ] ; then echo "`basename $0`: ERROR: only $nvols volumes in '$input' (less than $n). Exiting." ; exit 1 ; fi

  # check
  _nvols=$(echo "scale=0; $iter*$n" | bc -l)
  resid=$(echo "scale=0; $nvols - $_nvols" | bc -l)
  if [ $resid -gt 0 ] ; then echo "`basename $0`: WARNING: last 4D ('${output}_$(zeropad $iter 4)') will only have $resid volumes (not $n)." ; fi

  # execute
  echo "`basename $0`:"
  for i in `seq 0 $[$iter-1]` ; do
    tmin=$(echo "scale=0; $i*$n" | bc -l)
    cmd="fslroi $input ${output}_$(zeropad $i 4) $tmin $n"
    echo "    $cmd" ; $cmd
  done
  if [ $resid -gt 0 ] ; then
    i=$[$i+1]
    tmin=$(echo "scale=0; $i*$n" | bc -l)
    cmd="fslroi $input ${output}_$(zeropad $i 4) $tmin $resid"
    echo "    $cmd" ; $cmd
  fi
  
elif [ $vector -eq 1 ] ; then
  if [ $merge -eq 1 ] ; then echo "`basename $0`: will merge extraction." ; fi
  echo "`basename $0`: nvols: $nvols ; split-vector: [$n]"
  # split
  fslsplit $input ${tmpdir}/$(basename $output)_
  full_list=`imglob ${tmpdir}/$(basename $output)_????.*`

  i=0 ; files="" ; err=0
  for i in $_n ; do
    file=${tmpdir}/$(basename $output)_$(zeropad $i 4)
    if [ $(imtest $file) -eq 0 ] ; then echo "`basename $0`: ERROR: Cannot read '$file'..." ; err=1 ; fi
    files=$files" "$file
  done
  if [ $err -eq 1 ] ; then echo "`basename $0`: Exiting..." ; exit 1 ; fi
  if [ $merge -eq 1 ] ; then
    cmd="fslmerge -t $output $files"
    echo "    $cmd" ; $cmd
  else
    for file in $files ; do
      immv $file $(dirname $output)
    done  
  fi
fi

# done
echo "`basename $0`: done."
