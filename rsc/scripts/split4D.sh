#!/bin/bash
# i) Splits 4D volume along given dimension in volumes/slices of size n
# ii) Splits 4D volume according to split-vector along given dimension and merges the split if requested.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 10/11/2013

set -e

trap 'echo "$0 : An ERROR has occured."' ERR
    
Usage() {
    echo ""
    echo "Usage:   `basename $0` [option] <dim> <input4D> <size|vector> <output4D>"
    echo ""
    echo "Options: -m    merge extraction to 4D"
    echo ""
    echo "Example: `basename $0` t in 128 out"
    echo "         `basename $0` t in [128] out"
    echo "         `basename $0` -m t in [2:1:end-2] out"
    echo "         `basename $0` -m x in [1,mid,end] out"
    echo "         `basename $0` -m y in [0:2:end-1] out"
    echo "         `basename $0` -m z in [0,2:2:end-1] out"
    echo "         `basename $0` -m t in [0,2:2:end-1] out"
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
[ "$4" = "" ] && Usage

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# assign input arguments
dim=$1
input=$(remove_ext "$2")
n="$3"
output=$(remove_ext "$4")

# declare vars
nslices_x=`fslinfo $input | grep ^dim1 | awk '{print $2}'`
nslices_y=`fslinfo $input | grep ^dim2 | awk '{print $2}'`
nslices_z=`fslinfo $input | grep ^dim3 | awk '{print $2}'`
nvols=`fslinfo $input | grep ^dim4 | awk '{print $2}'`
if [ "$dim" = x ] ; then tag="_slice"  ; ntotal=$nslices_x ; fi
if [ "$dim" = y ] ; then tag="_slice"  ; ntotal=$nslices_y ; fi
if [ "$dim" = z ] ; then tag="_slice"  ; ntotal=$nslices_z ; fi
if [ "$dim" = t ] ; then tag=""        ; ntotal=$nvols ; fi
split_all=0 # if set to 1, fslslice (z-dim) or fslsplit (t-dim) is used, which might give a performance benefit.

# check input
if [ $(imtest $input) -eq 0 ] ; then echo "`basename $0`: Cannot read '$input'... exiting." ; exit 1 ; fi

# rem commas & brackets & tags
n="$(echo "$n" | sed 's|,| |g')"
n=$(echo $n | sed "s|end|$[$ntotal-1]|g")
n=$(echo $n | sed "s|mid|$(echo "$ntotal / 2" | bc)|g")
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
if [ $(echo $_n | wc -w) -gt 1 -o $(echo "$3" | grep ] | wc -l) -eq 1  ] ; then vector=1 ; else vector=0 ; fi

echo -n "`basename $0`: number of elements in ${dim}-dimension: $ntotal ; "
if [ $vector -eq 0 ] ; then
  echo "split-size: $n"
  iter=$(echo "scale=0 ; $ntotal/ $n" | bc -l)
  if [ $iter -eq 0 ] ; then echo "`basename $0`: ERROR: only $ntotal elements (${dim}-dimensiony) in '$input' (less than $n). Exiting." ; exit 1 ; fi

  # check
  _ntotal=$(echo "scale=0; $iter*$n" | bc -l)
  resid=$(echo "scale=0; $ntotal - $_ntotal" | bc -l)
  if [ $resid -gt 0 ] ; then echo "`basename $0`: WARNING: last 4D ('${output}_$(zeropad $iter 4)') will only have $resid slices (not $n)." ; fi

  # execute
  echo "`basename $0`:"
  for i in `seq 0 $[$iter-1]` ; do
    tmin=$(echo "scale=0; $i*$n" | bc -l)
    if [ "$dim" = "x" ] ; then  cmd="fslroi $input ${output}_$(zeropad $i 4) $tmin $n 0 -1 0 -1" ; fi
    if [ "$dim" = "y" ] ; then  cmd="fslroi $input ${output}_$(zeropad $i 4) 0 -1 $tmin $n 0 -1" ; fi
    if [ "$dim" = "z" ] ; then  cmd="fslroi $input ${output}_$(zeropad $i 4) 0 -1 0 -1 $tmin $n" ; fi
    if [ "$dim" = "t" ] ; then  cmd="fslroi $input ${output}_$(zeropad $i 4) $tmin $n" ; fi
    echo "    $cmd" ; $cmd
  done
  if [ $resid -gt 0 ] ; then
    i=$[$i+1]
    tmin=$(echo "scale=0; $i*$n" | bc -l)
    if [ "$dim" = "x" ] ; then  cmd="fslroi $input ${output}_$(zeropad $i 4) $tmin $resid 0 -1 0 -1" ; fi
    if [ "$dim" = "y" ] ; then  cmd="fslroi $input ${output}_$(zeropad $i 4) 0 -1 $tmin $resid 0 -1" ; fi
    if [ "$dim" = "z" ] ; then  cmd="fslroi $input ${output}_$(zeropad $i 4) 0 -1 0 -1 $tmin $resid" ; fi
    if [ "$dim" = "t" ] ; then  cmd="fslroi $input ${output}_$(zeropad $i 4) $tmin $resid" ; fi
    echo "    $cmd" ; $cmd
  fi
  
elif [ $vector -eq 1 ] ; then
  echo "split-vector: [$n]"
  if [ $merge -eq 1 ] ; then echo "`basename $0`: will merge extraction." ; fi

  i=0 ; files="" ; err=0
  if [ $split_all -eq 1 ] ; then
    if [ "$dim" = "t" ] ; then
      fslsplit $input ${tmpdir}/$(basename $output)${tag}_ # fslsplit adds 0000 to output
    elif [ "$dim" = "z" ] ; then
      fslslice $input ${tmpdir}/$(basename $output) # fslslice adds _slice_0000 to output
    fi
  fi
  for i in $_n ; do
    if [ $i -lt 0 -o $i -gt $[$ntotal-1] ] ; then echo "`basename $0`: WARNING: '$i' is not a valid index (valid index range: 0-$[$ntotal-1]). Continuing..." ; continue ; fi
    file=${tmpdir}/$(basename $output)${tag}_$(zeropad $i 4)
    if [ "$dim" = "x" ] ; then  cmd="fslroi $input $file $i 1 0 -1 0 -1" ; echo "    $cmd" ; $cmd ; fi
    if [ "$dim" = "y" ] ; then  cmd="fslroi $input $file 0 -1 $i 1 0 -1" ; echo "    $cmd" ; $cmd ; fi
    if [ $split_all -eq 0 ] ; then
      if [ "$dim" = "z" ] ; then  cmd="fslroi $input $file 0 -1 0 -1 $i 1" ; echo "    $cmd" ; $cmd ; fi
      if [ "$dim" = "t" ] ; then  cmd="fslroi $input $file $i 1" ; echo "    $cmd" ; $cmd ;  fi
    fi
    files=$files" "$file
  done
  if [ $err -eq 1 ] ; then echo "`basename $0`: Exiting..." ; exit 1 ; fi
  if [ $merge -eq 1 ] ; then
    cmd="fslmerge -${dim} $output $files"
    echo "    $cmd" ; $cmd
  else
    for file in $files ; do
      immv $file $(dirname $output)
    done  
  fi
fi

# done
echo "`basename $0`: done."
