#!/bin/bash
# Creates fieldmap.

# Written by Andreas Bartsch & Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/10/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:    `basename $0` <SUBJECTS_DIR> <subject> <hemi> <input> <output> <label1> <label2> ..."
    echo "Example:  `basename $0` $SUBJECT_DIR fsaverage lh lh.concat.mgh roi-table.txt lh.S_calcarine.label lh.G_precentral"
    echo ""
    exit 1
}

[ "$6" = "" ] && Usage
sdir="$1" ; shift
subj="$1" ; shift
hemi=$1 ; shift
input="$1" ; shift
output="$1" ; shift
rois="" ; while [ _$1 != _ ] ; do
  rois="$rois $1"
  shift
done

# checks
if [ "$hemi" != "lh" -a "$hemi" != "rh" ] ; then echo "$(basename $0): ERROR: no hemisphere ('lh' or 'rh') specified - exiting..." ; exit 1 ; fi

# execute mri_segstats in a loop
i=1 ; outlist=""
for roi in $rois ; do
  
  echo "$(basename $0): '$roi' in $hemi (hemisphere)."
  
  heading=$(basename $roi)
  
  cmd="mri_segstats --i $input --slabel $subj $hemi $roi --excludeid 0 --avgwf ${output}_$(zeropad $i 3)"
  echo "$cmd" ; $cmd 1> /dev/null
  
  sed -i "1i $heading" ${output}_$(zeropad $i 3)
  
  echo "${output}_$(zeropad $i 3): "
  cat ${output}_$(zeropad $i 3)
  echo "--------"
  
  outlist="$outlist ${output}_$(zeropad $i 3)"
  
  i=$[$i+1]

done

# concatenate
paste $outlist > $output

# cleanup
rm $outlist

# done
echo "$(basename $0): done."

