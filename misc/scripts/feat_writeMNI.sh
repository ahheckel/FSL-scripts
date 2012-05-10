#!/bin/bash
# writes input to MNI space according to given transforms

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <func-input> <T1-native> <MNI-template> <output> <resolution> <affine: input->T1> <warp: T1->MNI> <interp> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}


[ "$8" = "" ] && Usage
input=$(remove_ext "$1")
T1=$(remove_ext "$2")
MNI=$(remove_ext "$3")
output=$(remove_ext "$4")
mni_res=$5
affine=$6
warp=$7
interp="$8"
subj="$9"  # optional
sess="${10}"  # optional

outdir=$(dirname $output)
_mni_res=$(echo $mni_res | sed "s|\.||g") # remove '.'            

echo "`basename $0`: subj $subj , sess $sess : output directory: '$outdir'"

#echo "`basename $0`: subj $subj , sess $sess : resample MNI-template to a resolution of $mni_res ('$MNI' -> '$outdir/$(basename $MNI)_${_mni_res}')..." 
#flirt -ref $MNI -in $MNI -out $outdir/$(basename $MNI)_${_mni_res} -applyisoxfm $mni_res

#echo "`basename $0`: subj $subj , sess $sess : write T1->MNI ('$T1' -> '$outdir/$(basename $T1)${_mni_res}')..." 
#applywarp --ref=$outdir/$(basename $MNI)_${_mni_res} --in=${T1} --out=$outdir/$(basename $T1)_${_mni_res} --warp=${warp}  --interp=sinc

echo "`basename $0`: subj $subj , sess $sess : write Input->MNI ('$input' -> '$output')..." 
imrm ${output}_tmp_????.*
fslsplit $input ${output}_tmp_
full_list=`imglob ${output}_tmp_????.*`
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
