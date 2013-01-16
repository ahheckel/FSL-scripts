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
    echo "Usage:   `basename $0` <input> <resolution(mm)> <output>"
    echo "Example: `basename $0` input_2mm 4 output_4mm"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage
data=`remove_ext "$1"`
res="$2"
out=`remove_ext "$3"`

echo "`basename $0`: resampling '$data' to a resolution of $res mm (output: '$out'):"
cmd="flirt -in $data -ref $data -applyisoxfm $res -out $out" ; echo "    $cmd"
$cmd

echo "`basename $0`: done."
