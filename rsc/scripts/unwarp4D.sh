#!/bin/bash
# Unwarps 4Ds.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` [--nomc] <input4D> <output4D> <magn img> <dphase img> <dphaseTE(s)> <TE(ms)> <ESP(ms)> <siglossthres(%)> <unwarp direction: x/y/z/x-/y-/z-> <interp (default:trilinear)> <subj_idx> <sess_idx>"
    echo "Options: --nomc        skip motion correction"
    echo "Example: `basename $0` bold uw_bold magn dphase 0.00246 30 0.233 10 y- spline"
    echo ""
    exit 1
}

[ "$9" = "" ] && Usage

moco=1 ; if [ "$1" = "--nomc" ] ; then moco=0 ; echo "`basename $0` : motion correction will be skipped as requested." ; shift ; fi
input=`remove_ext "$1"`
output=`remove_ext "$2"`
magn=`remove_ext "$3"`
dphase=`remove_ext "$4"`
dTE=$5
TE=$6
ESP=$7
siglossthres=$8
uwdir="$9"
interp="${10}"
subj="${11}"
sess="${12}"

if [ x"$interp" = "x" ] ; then interp="trilinear" ; fi
indir=$(dirname $input)
outdir=$(dirname $output) ; mkdir -p $outdir ; mkdir -p $outdir/mc

echo "`basename $0` :  unwarping input 4D '$(basename $input)'..."
nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'`
mid=$(echo "scale=0 ; $nvol / 2" | bc)

cmd="fslroi $input ${output}_example_func $mid 1"
echo $cmd ; $cmd

# motion correction
if [ $moco -eq 1 ] ; then
  if [ -d $outdir/mc/prefiltered_func_data_mcf.mat ] ; then echo "`basename $0` : deleting motion-correction mat-directory from previous run..." ; rm -vrf $outdir/mc/prefiltered_func_data_mcf.mat ; fi
  cmd="mcflirt -in $input -out $outdir/mc/prefiltered_func_data_mcf -mats -plots -refvol $mid -rmsrel -rmsabs"
  echo $cmd ; $cmd
  rm -f $outdir/mc/prefiltered_func_data_mcf.nii.gz
fi

# get fieldmap
cmd="$(dirname $0)/make_fmap.sh $magn $dphase $dTE 0.5 $outdir/fm/fmap_rads_masked $subj $sess"
echo $cmd ; $cmd

# unwarp
cmd="$(dirname $0)/feat_unwarp.sh $input $outdir/fm/fmap_rads_masked $outdir/fm/magn_brain $uwdir $TE $ESP $siglossthres $outdir/unwarp $subj $sess"
echo $cmd ; $cmd

# apply transforms
if [ $moco -eq 1 ] ; then
  cmd="$(dirname $0)/apply_mc+unwarp.sh $input $output $outdir/mc/prefiltered_func_data_mcf.mat $outdir/unwarp/EF_UD_shift.nii.gz $uwdir $interp"
  echo $cmd ; $cmd
else
  cmd="$(dirname $0)/apply_unwarp.sh $input $output $outdir/unwarp/EF_UD_shift.nii.gz $uwdir $interp"
  echo $cmd ; $cmd
fi

echo "`basename $0` : done."
