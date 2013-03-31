#!/bin/bash
# Estimates the deformation (mean and median) of a fnirt warpfield to have a goodness of fit measure of the preceding affine registration.

# Based on FSL's fsl_reg (v. 4.1.9).
# Adapted by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

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

# estimate the mean deformation
fslmaths ${wf} -sqr -Tmean ${wf}_tmp
result=$(fslstats ${wf}_tmp -M -P 50)
imrm ${wf}_tmp

echo "`basename $0`: mean/median deformation of '$wf' : $result" 
#echo "`basename $0`: done."
