#!/bin/bash
# This is a wrapper for fslreorient2std (FSL v.5) to ensure compatibility with version 4.1.9.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <input> <output>"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage
input=$(remove_ext "$1")
output=$(remove_ext "$2")

cmd="fslreorient2std $input /tmp/${output}_$$"
echo $cmd
$cmd

# reslice was applied or input is nii.gz
if [ -f /tmp/${output}_$$.nii.gz ] ; then
  cmd="mv /tmp/${output}_$$.nii.gz ${output}.nii.gz"
  echo $cmd;
  $cmd
fi

# no reslice was applied -> convert to .nii.gz via fslmaths, if input was .nii
if [ -f /tmp/${output}_$$.nii ] ; then
  cmd="fslmaths /tmp/${output}_$$ ${output}"
  echo $cmd ; $cmd
  cmd="rm /tmp/${output}_$$.nii"
  echo $cmd ; $cmd
fi 
