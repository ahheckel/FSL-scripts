#!/bin/bash

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/07/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:    `basename $0` <input4D> <output4D> <SUBJECTS_DIR> <target-subject> <input2target.dat|T1-reference>"
    echo "Example:  `basename $0` log_tfce_corrp_tstat1.nii.gz sig.mgh /usr/local/freesurfer/subjects fsaverage mni152-vol_2_fsaverage-surf.register.dat"
    echo "          `basename $0` log_tfce_corrp_tstat1.nii.gz sig.mgh /usr/local/freesurfer/subjects fsaverage MNI152_T1_1mm.nii.gz"
    echo ""
    exit 1
}

[ "$5" = "" ] && Usage

src="$1"
output="$2"
SUBJECTS_DIR="$3"
trgsubject="$4"
srcreg="$5"

if [ ! -f $srcreg ] ; then echo "`basename $0` : '$srcreg' not found - exiting..." ; exit 1 ; fi

mkdir -p $(dirname $output)

# execute bbregister if applicable
if [ $(imtest "$srcreg") -eq 1 ] ; then
  cmd="bbregister --s $trgsubject --mov $srcreg --init-fsl --reg ${output}_bbr.dat --t1 --fslmat ${output}_bbr.fslmat"
  echo "    $cmd" ; $cmd 1>/dev/null
  srcreg="${output}_bbr.dat"
fi

for hemi in rh lh ; do
  out=$(dirname $output)/${hemi}.$(basename $output)
  cmd="mri_vol2surf --src $src --srcreg $srcreg --trgsubject $trgsubject --hemi $hemi --out $out --surf white --projfrac 0.5 --interp trilinear"
  echo "    $cmd" ; $cmd 1>/dev/null
done

echo "`basename $0` : done."
