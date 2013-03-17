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
    echo "Usage:   `basename $0` <input4D> <output4D>"
    echo "Example: `basename $0` log_tfce_corrp_tstat1.nii.gz sig.mgh"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage

src="$1"
output="$2"

srcreg=$(dirname $0)/mni2fsaverage.register.dat
trgsubject=fsaverage

mkdir -p $(dirname $output)

for hemi in rh lh ; do

  out=$(dirname $output)/${hemi}.$(basename $output)

  cmd="mri_vol2surf --src $src --srcreg $srcreg --trgsubject $trgsubject --hemi $hemi --out $out --surf white --interp trilinear"
  echo "    $cmd" ; $cmd

done

echo "`basename $0` : done."
