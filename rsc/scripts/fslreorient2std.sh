#!/bin/bash
# This is a wrapper for fslreorient2std (FSL v.5) to ensure compatibility with version 4.1.9.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

set -e

input=$(remove_ext "$1")
output=$(remove_ext "$2")

fslreorient2std $input $output

if [ -f ${output}.nii -a -f ${output}.nii.gz ] ; then rm ${output}.nii.gz ; fi # delete duplicate
if [ -f ${output}.nii ] ; then fslmaths $output $output ; rm ${output}.nii ; fi
