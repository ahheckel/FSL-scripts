#!/bin/bash
# Converts Freesurfer-format to FSL-format / normalizes WM-intensity and conforms to 256^3 at 1mm (or another isotropic resolution) if requested.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 10/04/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:    `basename $0` [-n] <input> <output> <fslreorient2std: 0|1> [<resolution(mm)>] [<mri_convert options>]"
    echo "Options:  -n  normalize output"
    echo ""
    echo "Example:  `basename $0` -n T1.mgz T1.nii.gz 1 2 \"-odt float -c -rt cubic\""
    echo ""
    exit 1
}

if [ "$1" = "-n" ] ; then 
  normalize=1
  shift
else 
  normalize=0
fi

[ "$3" = "" ] && Usage

input=$1
out=$2
reor=$3
res=$4
opts="$5"

if [ x"$res" = "x" ] ; then 
  resopt=""
else
  resopt="-applyisoxfm $res"
fi
if [ x"$opts" = "x" ] ; then 
  opts="-odt float"
fi

if [ $normalize -eq 1 ] ; then
  mri_convert $input ${input%%.*}.mnc -odt float
  nu_correct -clobber ${input%%.*}.mnc ${input%%.*}_nu.mnc
  mri_normalize ${input%%.*}_nu.mnc ${input%%.*}_nu_norm.mnc
  mri_convert ${input%%.*}_nu_norm.mnc $out $opts
  rm -f ${input%%.*}.mnc ${input%%.*}_nu.mnc ${input%%.*}_nu_norm.mnc ${input%%.*}_nu.imp
else
  cmd="mri_convert $input $out $opts"
  echo "`basename $0`: executing '$cmd'"
  $cmd 1>/dev/null
fi

if [ $reor -eq 1 ] ; then
  echo "`basename $0`: applying fslreorient2std..."
  fslreorient2std $out $out
fi  

if [ x"$resopt" != "x" ] ; then 
  echo "`basename $0`: resampling to resolution '$resopt'..."
  flirt -in $out -ref $out $resopt -out ${out}
fi  

echo "`basename $0`: done."
