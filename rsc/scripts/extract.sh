#!/bin/bash
# Extracts images from 4D volume.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 04/29/2013

set -e

trap 'echo "$0 : An ERROR has occured."' ERR
    
Usage() {
    echo ""
    echo "Usage:    `basename $0` <input file> <out-Prefix> <idx>"
    echo "Example:  `basename $0` melodic_IC.nii.gz ./test/melodic 0,1,2,3"
    echo "          `basename $0` \"\$files\" -1 beg,mid,end"
    echo "Note:     -1 : creates extraction in directory of input file."
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage    

inputs="$1"
_pref="$2"
idxs="$(echo "$3" | sed 's|,| |g')"

if [ $(echo $inputs | wc -w) -gt 1 -a "$_pref" != "-1" ] ; then echo "`basename $0`: ERROR: multiple inputs require option '-1' - exiting..." ; exit 1 ; fi

for input in $inputs ; do

  input=$(remove_ext "$input")

  if [ "$_pref" = "-1" ] ; then
    pref=$(dirname $input)/$(basename $input)
  else
    pref=$_pref
    mkdir -p $(dirname $pref)
  fi

  total_volumes=`fslnvols $input 2> /dev/null`

  for idx in $idxs ; do
    #echo "`basename $0`: extracting volume at pos. $idx from '$input'..."
    if [ $idx = "beg" ] ; then
      idx=0
      echo "`basename $0`: start-position: $idx"
    fi
    if [ $idx = "mid" ] ; then
      idx=$(echo "$total_volumes / 2" | bc)
      echo "`basename $0`: mid-position: $idx"
    fi
    if [ $idx = "end" ] ; then
      idx=$(echo "$total_volumes - 1" | bc)
      echo "`basename $0`: end-position: $idx"
    fi
    cmd="fslroi $input ${pref}_$(zeropad $idx 4) $idx 1"
    echo "    $cmd" ; $cmd
  done
  
done

echo "`basename $0`: done."
