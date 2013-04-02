#!/bin/bash
# Converts DICOMS to compressed nifti using dcm2nii (Chris Rorden)

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/30/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo "`basename $0` will recursively parse <input-dir> for DICOMS, which will be converted to nii.gz files in <output-dir>."
    echo "Usage:   `basename $0` <input-dir> <output-dir>"
    echo "Example: `basename $0` dcm-dir out-dir"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage
indir="$1"
outdir="$2"

# remove superfluous slashes
indir=$(echo $indir | sed "s|/\./|/|g" | sed "s|/\+|/|g")
indir=${indir%/}
outdir=$(echo $outdir | sed "s|/\./|/|g" | sed "s|/\+|/|g")
outdir=${outdir%/}

# dcm2nii idiosyncrasy
if [ $indir = "." ] ; then indir=$(pwd) ; fi

# make outdir
mkdir -p $outdir

# delete nii.gz files in outdir
for i in $(ls $outdir/*.nii.gz 2>/dev/null) ; do
  rm -i $i 
done
for i in $(ls $outdir/*.nii 2>/dev/null) ; do
  rm -i $i 
done

# execute
cmd="dcm2nii -d n -e y -g n -i n -p y -n y -r n -x n -o $outdir $indir/*"
echo "    $cmd" ; $cmd

# compress
for i in $(ls $outdir/*.nii) ; do
  cmd="gzip $i"
  echo "    $cmd" ; $cmd
done

# done
echo "`basename $0`: done."
