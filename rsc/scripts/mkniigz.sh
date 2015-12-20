#!/bin/bash
# Converts .nii/.img/.hdr to .nii.gz and deletes original file.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 28/10/2014

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> [<nii.gz-output4D-basename>]"
    echo "Example: `basename $0` input.hdr output.nii.gz"
    echo "         `basename $0` input.hdr input"
    echo "         `basename $0` input.img"
    echo "         `basename $0` input.nii"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

# define vars
input="$1" ; in_ext=${input##*.}
input=`remove_ext "$1"`
output=`remove_ext "$2"`
if [ x"$output" = "x" ] ; then output="$input" ; fi

# check
if [ $(imtest $input) -eq 0 ] ; then echo "`basename $0` : ERROR : cannot read '$input' - exiting." ; exit ; fi

# execute
cmd="fslmaths $input ${output}.nii.gz"
echo "`basename $0` : $cmd" ; $cmd
if [ "${in_ext}" = "hdr" -o "${in_ext}" = "img"  ] ; then
  cmd="rm -f ${input}.hdr"
  echo "`basename $0` : $cmd" ; $cmd
  cmd="rm -f ${input}.img"
  echo "`basename $0` : $cmd" ; $cmd
else
  cmd="rm -f ${input}.${in_ext}"
  echo "`basename $0` : $cmd" ; $cmd
fi

# done
echo "`basename $0` : done."
