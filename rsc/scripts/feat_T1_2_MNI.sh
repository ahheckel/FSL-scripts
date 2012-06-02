
#!/bin/bash
# The FEAT way of T1->MNI registration.

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <T1-head> <T1-brain> <out> <init-affine|none> <[<affine-cost> <affine-init>] <MNI-template-head> <MNI-template-brain> <MNI-brainmask> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage

T1head=$(remove_ext $1)
T1=$(remove_ext $2)
out=$(remove_ext $3)
aff=$4
if [ $aff = "none" ] ; then
  if [ x$5 = "x" ] ; then
    costf="corratio"
  else
    costf="$5"
    shift
  fi
  if [ x$5 = "x" ] ; then
    initmat=""
  else
    initmat="-init $5"
    shift
  fi
fi
if [ x$5 = "x" ] ; then
  MNIhead=$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz
  MNI=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz
  MNI_mask=$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz
else
  MNIhead=$(remove_ext $5)
  MNI=$(remove_ext $6)
  MNI_mask=$(remove_ext $7)
fi
subj="$8"  # optional
sess="$9"  # optional

outdir=$(dirname $out)


if [ $aff = "none" ] ; then
  echo "`basename $0`: subj $subj , sess $sess : flirting brain '${T1}' -> '${MNI}'..."
  cmd="flirt -ref ${MNI}  -in $T1 -out $outdir/$(basename $T1)2$(basename $MNI) $initmat -omat $outdir/$(basename $T1)2$(basename $MNI).mat -cost $costf -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear" #-usesqform"
  echo $cmd ; $cmd
  aff=${outdir}/$(basename $T1)2$(basename $MNI).mat
fi

echo "`basename $0`: subj $subj , sess $sess : fnirting head '${T1head}' -> '${MNIhead}'..."
cmd="fnirt --in=${T1head} --aff=${aff} --cout=${out}_warp --iout=${out} --jout=${out}_jac --config=T1_2_MNI152_2mm  --ref=${MNIhead} --refmask=${MNI_mask} --warpres=10,10,10"
echo $cmd ; $cmd

echo "`basename $0`: subj $subj , sess $sess : '${out}' created."
echo "`basename $0`: subj $subj , sess $sess : done."
