#!/bin/bash
# Writes input to MNI space according to given transforms. For internal use only.

# Based on FSL's featlib.tcl (v. 4.1.9). 
# Adapted by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <func-input> <MNI-template> <output> <resolution> <affine: input->T1> <warp: T1->MNI> <interp> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$7" = "" ] && Usage
input=$(remove_ext "$1")
MNI=$(remove_ext "$2")
output=$(remove_ext "$3")
mni_res=$4
affine=$5
warp=$6
interp="$7"
subj="$8"  # optional
sess="${9}"  # optional

outdir=$(dirname $output)
_mni_res=$(echo $mni_res | sed "s|\.||g") # remove '.'    

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

echo "`basename $0`: subj $subj , sess $sess : output directory: '$outdir'"

echo "`basename $0`: subj $subj , sess $sess : write Input->MNI ('$input' -> '$output')..."

imrm ${tmpdir}/$(basename $output)_tmp_????.*
fslsplit $input ${tmpdir}/$(basename $output)_tmp_
full_list=`imglob ${tmpdir}/$(basename $output)_tmp_????.*`
for i in $full_list ; do
  echo "processing $i"
  cmd="applywarp --ref=$outdir/$(basename $MNI)_${_mni_res} --in=$i --out=$i --warp=${warp} --premat=${affine} --interp=${interp}"
  #echo $cmd
  $cmd
done
echo "`basename $0`: subj $subj , sess $sess : merge outputs...."
fslmerge -t $output $full_list
imrm $full_list

echo "`basename $0`: subj $subj , sess $sess : done."
