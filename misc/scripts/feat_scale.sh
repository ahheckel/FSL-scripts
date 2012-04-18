#!/bin/bash
# The FEAT way of scaling.

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <4dinput> <output> <global|prop> <normmean> <median> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage
data=`remove_ext "$1"`
out=`remove_ext "$2"`
mode="$3"
normmean="$4"
median_intensity="$5"
subj="$6"  # optional
sess="$7"  # optional

if [ $mode = "global" ] ; then
  if [ x"$median_intensity" = x ] ; then Usage ; fi
  scaling=$(echo "scale=10; $normmean / $median_intensity"  | bc -l)
  echo "`basename $0`: subj $subj , sess $sess : global-mean scaling of ${data} with factor $scaling..."
  fslmaths ${data} -mul $scaling ${out}
elif [ $mode = "prop" ] ; then
  echo "`basename $0`: subj $subj , sess $sess : multiplicative mean intensity normalization of ${data} at each timepoint..."
  fslmaths ${data} -inm $normmean ${out}
else
  echo "`basename $0`: subj $subj , sess $sess : ERROR : mode '$mode' not recognised..."
  exit 1
fi
  
