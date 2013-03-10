#!/bin/bash
# Resamples 4D image to given resolution.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 01/16/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:   `basename $0` <input> <resolution(mm)> <output> [<mni:0(def)|1>]"
    echo "         NOTE: If <mni> is set to 1, FSL's MNI152 template is used as reference."
    echo "Example: `basename $0` input_2mm 4 output_4mm 1"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage
data=`remove_ext "$1"`
res="$2"
out=`remove_ext "$3"`
refflag=$4
if [ x${refflag} = "x" ] ; then refflag=0 ; else refflag=1 ; fi

if [ $refflag -eq 0 ] ; then ref=$data ; fi
if [ $refflag -eq 1 ] ; then 
  mniref=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz
  ref=/tmp/$$_ref_${res}mm
  echo "`basename $0`: resampling '$mniref' to a resolution of $res mm (output: '$ref'):"
  cmd="flirt -in $mniref -ref $mniref -applyisoxfm $res -out $ref" ; echo "    $cmd"
  $cmd
fi

echo "`basename $0`: resampling '$data' to a resolution of $res mm (output: '$out'):"
cmd="flirt -in $data -ref $ref -applyisoxfm $res -out $out" ; echo "    $cmd"
$cmd

# cleanup
imrm $ref

# done
echo "`basename $0`: done."
