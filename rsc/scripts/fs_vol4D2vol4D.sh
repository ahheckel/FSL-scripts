#!/bin/bash

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 28/06/2014

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:    `basename $0` <input4D> <output4D> <SUBJECTS_DIR> <source-subject> <register.dat> <target-subject>"
    echo "Example:  `basename $0` fsmc.nii fsmc_fsaverage.nii /usr/local/freesurfer/subjects DIf1a ../register.dat fsaverage"
    echo ""
    exit 1
}

[ "$6" = "" ] && Usage

# parse arguments
input="$1"
output="$2"
SUBJECTS_DIR="$3"
srcsubject="$4"
registerdat="$5"
trgsubject="$6"

# checks
if [ ! -f $registerdat ] ; then echo "`basename $0` : '$registerdat' not found - exiting..." ; exit 1 ; fi
if [ $(imtest "$input") -eq 0 ] ; then echo "`basename $0` : cannot read '$input' - exiting..." ; exit 1 ; fi
if [ ! -d $SUBJECTS_DIR ] ; then echo "`basename $0` : '$SUBJECTS_DIR' not found - exiting..." ; exit 1 ; fi
if [ ! -d $SUBJECTS_DIR/$srcsubject ] ; then echo "`basename $0` : '$SUBJECTS_DIR/$srcsubject' not found - exiting..." ; exit 1 ; fi
if [ ! -d $SUBJECTS_DIR/$trgsubject ] ; then echo "`basename $0` : '$SUBJECTS_DIR/$trgsubject' not found - exiting..." ; exit 1 ; fi

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# split 4D input
nvol=`fslnvols $input`
echo "$(basename $0): splitting '$input' ($nvol volumes)..."
cmd="fslsplit $input $tmpdir/vol_"
echo "    $cmd" ; $cmd

outs=""
# for each timepoint...
for i in $(seq 0 $[$nvol-1]) ; do
  n=$(zeropad $i 4)
  mov=$tmpdir/vol_${n}.nii.gz
  surfval=$tmpdir/bold_${srcsubject}2${trgsubject}.${n}
  outnii=$tmpdir/bold_${srcsubject}2${trgsubject}.${n}
  
  # vol2surf
  for hemi in lh rh ; do
    echo "$(basename $0): "
    cmd="mri_vol2surf --mov $mov --out ${surfval}.${hemi}.mgz --hemi $hemi --trgsubject $trgsubject --reg $registerdat --srcsubject $srcsubject"
    echo "    $cmd" ; $cmd  
  done
  
  # surf2vol
  for hemi in lh rh ; do
    echo "$(basename $0): "
    cmd="mri_surf2vol --surfval ${surfval}.${hemi}.mgz --hemi $hemi --projfrac 0.5 --fillribbon --fill-projfrac 0 1 0.1 --o ${outnii}.${hemi}.nii.gz --identity $trgsubject --template $SUBJECTS_DIR/$trgsubject/mri/T1.mgz"
    echo "    $cmd" ; $cmd
  done

  # merge hemispheres
  echo "$(basename $0): "
  cmd="fslmerge -x $outnii ${outnii}.lh ${outnii}.rh"
  echo "    $cmd" ; $cmd
  
  # gather nifti volumes
  outs=$outs" "$outnii
  
  # cleanup
  imrm ${outnii}.lh ${outnii}.rh $mov
  rm ${surfval}.lh.mgz ${surfval}.rh.mgz

done # end loop

# merge to 4D nifti
echo "$(basename $0): "
cmd="fslmerge -t $output $outs"
echo "    $cmd" ; $cmd

# cleanup
imrm $outs

# done
echo "`basename $0` : done."
