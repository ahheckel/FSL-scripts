#!/bin/bash
# Resamples Freesurfer label files in different space.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/27/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:    `basename $0` <SUBJECTS_DIR> <source-subject> <hemi> <target-subject> <output-dir> <source-label1 source-label2 ... >"
    echo "Example:  `basename $0` ./FS_subj fsaverage lh mni152.fnirt ./mni-labels/ one.label two.label three.label"
    echo ""
    exit 1
}

#get_hemi() {
  #local i="$1"
  #local lh=0 ; local rh=0 ; local _dir="" ; local _dirname="" ; local _hemi=""

  #lh="$(echo $(basename $i) | grep "\.lh\." | wc -l )"
  #rh="$(echo $(basename $i) | grep "\.rh\." | wc -l )"
  #if [ $lh -eq 0 ] ; then lh="$(echo $(basename $i) | grep "^lh\." | wc -l )" ; fi
  #if [ $rh -eq 0 ] ; then rh="$(echo $(basename $i) | grep "^rh\." | wc -l )" ; fi
  #_dir="$i"
  #while [ $lh -eq 0 -a $rh -eq 0 ] ; do
    #_dir=$(dirname $_dir) ; if [ "$_dir" = "$(dirname $_dir)" ] ; then break ; fi
    #_dirname=$(basename $_dir)
    #_hemi="$(basename $_dirname)"
    #lh=$(echo $_hemi | grep "^lh\."  | wc -l)
    #rh=$(echo $_hemi | grep "^rh\."  | wc -l)
    #if [ $lh -eq 0 ] ; then lh=$(echo $_hemi | grep "\.lh\." | wc -l) ; fi
    #if [ $rh -eq 0 ] ; then rh=$(echo $_hemi | grep "\.rh\." | wc -l) ; fi
    #if [ $lh -eq 0 ] ; then lh=$(echo $_hemi | grep "\-lh\-" | wc -l) ; fi
    #if [ $rh -eq 0 ] ; then rh=$(echo $_hemi | grep "\-rh\-" | wc -l) ; fi
  #done
  #if [ $lh -eq 1 ] ; then echo "lh" ; elif [ $rh -eq 1 ] ; then echo "rh" ; fi
#}

[ "$6" = "" ] && Usage

# define vars
sdir="$1" ; shift
src="$1" ; shift
hemi="$1" ; shift
trg="$1" ; shift
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
for label in $labels ; do
  # check
  touch $outdir/file.$$ ; if [ -f $(dirname $label)/file.$$ ] ; then echo "`basename $0` : ERROR: input dir. and output dir. are identical - exiting..." ; exit 1 ; fi
  # execute
  cmd="mri_label2label --hemi $hemi --srclabel $label --srcsubject $src --trgsubject $trg --trglabel $outdir/$(basename $label) --regmethod surface --sd $sdir"
  echo "    $cmd" ; $cmd
done

# done
echo "`basename $0` : done."
