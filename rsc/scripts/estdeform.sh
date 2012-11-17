#!/bin/bash
# Estimates the mean deformation (mean and median) of a fnirt warpfield to have a goodness of fit measure of the preceding affine registration.

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <fnirt-warpfield>"
    echo "Example: `basename $0` t1_2_mni_warp.nii.gz"
    exit 1
}

[ "$1" = "" ] && Usage

wf=$(remove_ext "$1")

# now estimate the mean deformation
fslmaths ${wf} -sqr -Tmean ${wf}_tmp
result=$(fslstats ${wf}_tmp -M -P 50) # > ${wf}_warp.msf
imrm ${wf}_tmp

echo "mean/median deformation of '$wf' : $result" 
#echo "`basename $0`: done."
