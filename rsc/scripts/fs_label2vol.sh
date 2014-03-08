#!/bin/bash

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/27/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:    `basename $0` <SUBJECTS_DIR> <source-subject> <hemi> <template> <opts|none > <output-dir> <FS-label1 FS-label2 ... >"
    echo "Example:  `basename $0` ./FS_subj subj01 lh ./FS_sess/subj01/bold/001/ftemplate.nii \"--proj frac 0 1 0.1 --fillthresh 0.3 --reg ./FS_sess/subj01/bold/register.dat\" ./nifti-mni-labels one.label two.label three.label"
    echo ""
    echo "NOTE:      If set to \"none\" <opts> defaults to \"--proj frac 0 1 0.1 --fillthresh 0.5 --identity\""
    exit 1
}

[ "$7" = "" ] && Usage

# define vars
sdir="$1" ; shift
src="$1" ; shift
hemi="$1" ; shift
templ="$1" ; shift
opts="$1" ; shift ; if [ x"$opts" = "xnone" ] ; then opts="--fillthresh 0.5 --proj frac 0 1 0.1 --identity" ; fi
outdir="$1" ; shift
labels="" ; while [ _$1 != _ ] ; do
  labels="$labels $1"
  shift
done

# checks
err=0
if [ ! -d $sdir/$src ] ; then echo "`basename $0` : ERROR: '$sdir/$src' not found..." ; err=1  ; fi
if [ ! -d $sdir/$trg ] ; then echo "`basename $0` : ERROR: '$sdir/$trg' not found..." ; err=1  ; fi
for label in $labels ; do
  if [ ! -f $label ] ; then echo "`basename $0` : ERROR: '$label' not found..." ; err=1 ; fi
done
if [ $err -eq 1 ] ; then exit 1 ; fi
label=""

# define exit trap
trap "rm -f $outdir/file.$$ ; exit" EXIT

# create outdir
mkdir -p $outdir

# execute
rm -f $outdir/$(basename $0).cmd
echo "`basename $0` : creating commands in '$outdir/$(basename $0).cmd'..."
for label in $labels ; do
  # check
  touch $outdir/file.$$ ; if [ -f $(dirname $label)/file.$$ ] ; then echo "`basename $0` : ERROR: input dir. and output dir. are identical - exiting..." ; exit 1 ; fi
  # execute
  cmd="SUBJECTS_DIR=$sdir ; mri_label2vol --label $label --hemi $hemi  --subject $src --temp $templ --o $outdir/$(basename $label).nii.gz $opts"
  echo "    $cmd" | tee -a $outdir/$(basename $0).cmd
done
. $outdir/$(basename $0).cmd

# done
echo "`basename $0` : done."
