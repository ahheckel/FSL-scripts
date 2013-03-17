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
    echo "Usage:    `basename $0` <input4D> <output4D> [<target-subject>] [<input2target_register>]"
    echo "Example:  `basename $0` log_tfce_corrp_tstat1.nii.gz sig.mgh fsaverage mni2fsaverage.register.dat"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage

src="$1"
output="$2"
srcreg="$3"
trgsubject="$4"

if [ x"$srcreg" = "x" ] ; then srcreg=$(dirname $0)/mni2fsaverage.register.dat ; fi
if [ x"$trgsubject" = "x" ] ; then trgsubject=fsaverage ; fi

if [ ! -f $srcreg ] ; then echo "`basename $0` : '$srcreg' not found - exiting..." ; exit 1 ; fi

mkdir -p $(dirname $output)

for hemi in rh lh ; do

  out=$(dirname $output)/${hemi}.$(basename $output)

  cmd="mri_vol2surf --src $src --srcreg $srcreg --trgsubject $trgsubject --hemi $hemi --out $out --surf white --interp trilinear"
  echo "    $cmd" ; $cmd

done

echo "`basename $0` : done."
