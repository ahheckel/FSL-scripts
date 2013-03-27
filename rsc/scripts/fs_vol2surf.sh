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
    echo "Usage:    `basename $0` <input4D> <output4D> <SUBJECTS_DIR> [<target-subject(default:fsaverage>] [<input2target.dat>]"
    echo "Example:  `basename $0` log_tfce_corrp_tstat1.nii.gz sig.mgh /usr/local/freesurfer/subjects fsaverage mni152-vol_2_fsaverage-surf.register.dat"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

src="$1"
output="$2"
SUBJECTS_DIR="$3"
trgsubject="$4"
srcreg="$5"

if [ x"$trgsubject" = "x" ] ; then trgsubject=fsaverage ; fi
if [ x"$srcreg" = "x" ] ; then srcreg=$(dirname $0)/mni152-vol_2_fsaverage-surf.register.dat ; fi

if [ ! -f $srcreg ] ; then echo "`basename $0` : '$srcreg' not found - exiting..." ; exit 1 ; fi

mkdir -p $(dirname $output)

for hemi in rh lh ; do

  out=$(dirname $output)/${hemi}.$(basename $output)

  cmd="mri_vol2surf --src $src --srcreg $srcreg --trgsubject $trgsubject --hemi $hemi --out $out --surf white --projfrac 0.5 --interp trilinear"
  echo "    $cmd" ; $cmd

done

echo "`basename $0` : done."
