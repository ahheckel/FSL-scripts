#!/bin/bash
# Applies motion-correction and stereotactic registration to 4D.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 12/25/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <output4D> <mc mat-dir|.ecclog file|matrix file> <func_to_T1 mat> <T1_to_MNI warp> [<interp (default:trilinear)>] [<MNI_ref>]"
    echo "Example: `basename $0` bold mni_bold ./mc/prefiltered_func_data_mcf.mat/ ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz"
    echo "         `basename $0` diff mni_diff ./diff.ecclog none ./reg/highres2standard_warp.nii.gz nn"
    echo "         `basename $0` diff mni_diff ./matrix.mat  none ./reg/highres2standard_warp.nii.gz spline"
    echo "         `basename $0` diff mni_diff none ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz spline"
    echo "         `basename $0` bold mni_bold ./mc/prefiltered_func_data_mcf.mat/ ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz trilinear"
    echo "         `basename $0` bold  T1_bold ./mc/prefiltered_func_data_mcf.mat/ none ./reg/func2highres_warp.nii.gz spline reg/highres.nii.gz"
    echo ""
    exit 1
}

[ "$5" = "" ] && Usage

# define vars
input=`remove_ext "$1"`
output=`remove_ext "$2"`
mcdir="$3"
f2t1_mat="$4"
f2mni_warp="$5"
interp="$6"
if [ x"$interp" = "x" ] ; then interp="trilinear" ; fi
ref="$7"
if [ x"$ref" = "x" ] ; then ref="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz" ; fi

# calling function
cmd="$(dirname $0)/apply_mc+unwarp+reg2MNI.sh $input $output $mcdir none 00 $f2t1_mat $f2mni_warp $interp $ref"

# display info
echo "`basename $0` : executing:"
echo "    $cmd"
$cmd

echo "`basename $0` : done."
