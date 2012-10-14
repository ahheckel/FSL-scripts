#!/bin/bash
# This is a wrapper for fslreorient2std (FSL v.5) to ensure compatibility with version 4.1.9.
set -e

input=$(remove_ext "$1")
output=$(remove_ext "$2")

fslreorient2std $input $output

if [ -f ${output}.nii ] ; then fslmaths $output $output ; rm ${output}.nii ; fi
