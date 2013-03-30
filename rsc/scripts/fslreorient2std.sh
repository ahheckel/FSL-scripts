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
tmpfile=/tmp/$(basename $output)_$$

cmd="fslreorient2std $input $tmpfile"
echo "    $cmd" ; $cmd

# reslice was applied or input is nii.gz
if [ -f ${tmpfile}.nii.gz ] ; then
  cmd="mv ${tmpfile}.nii.gz ${output}.nii.gz"
  echo "    $cmd" ; $cmd
fi

# no reslice was applied -> convert to .nii.gz via fslmaths, if input was .nii
if [ -f ${tmpfile}.nii ] ; then
  cmd="fslmaths $tmpfile ${output}"
  echo "    $cmd" ; $cmd
  cmd="rm ${tmpfile}.nii"
  echo "    $cmd" ; $cmd
fi
