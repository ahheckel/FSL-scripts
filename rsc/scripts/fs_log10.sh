#!/bin/bash
# Converts FSL-style significance maps to FREESURFER-style significance maps.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 07/03/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <output4D>"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage

# define vars
input=`remove_ext "$1"`
output=`remove_ext "$2"`
mask=${output}_mask_$$

# define exit trap
trap "imrm $mask ; exit" EXIT

# create mask
fslmaths $input -bin $mask

# execute
cmd="fslmaths $input -mas $mask -mul -1 -add 1 -log -div -2.3025851 $output"
echo "`basename $0` : $cmd"  ; $cmd

# cleanup
imrm $mask

# done
echo "`basename $0` : done."
