#!/bin/bash
# make fieldmap

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <output4D> <mc mat-dir> <unwarp shiftmap> <unwarp direction: x/y/z/x-/y-/z-> <func_to_T1 mat> <T1_to_MNI warp>"
    echo ""
    exit 1
}

[ "$7" = "" ] && Usage

input=`remove_ext "$1"`
output=`remove_ext "$2"`
mcdir="$3"
shiftmap="$4"
uwdir="$5"
f2t1_mat="$6"
f2mni_warp="$7"

echo "`basename $0` : write func -> standard space w/o intermediary write-outs..."

nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'`
mid=$(echo "scale=0 ; $nvol / 2" | bc)
fslroi $input ${output}_example_func $mid 1

imrm ${output}_tmp_????.*
fslsplit $input ${output}_tmp_
full_list=`imglob ${output}_tmp_????.*`
i=0
for file in $full_list ; do
  i=`zeropad $i 4`
  
  echo "processing $file"
  
  cmd="convertwarp --ref=${output}_example_func --shiftmap=${shiftmap} --shiftdir=${uwdir} --out=${output}_WARP1_${i} --relout"
  echo $cmd
  $cmd
  cmd="convertwarp --ref=${FSL_DIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --warp1=${f2mni_warp} --premat=${f2t1_mat} --out=${output}_WARP2_${i} --relout"
  echo $cmd
  $cmd
  cmd="convertwarp --ref=${FSL_DIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --warp1=${output}_WARP1_${i}  --warp2=${output}_WARP2_${i} --premat=${mcdir}/MAT_${i} --out=${output}_WARP_${i} --relout" 
  echo $cmd
  $cmd  
  cmd="applywarp --ref=${FSL_DIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --in=${file} --warp=${output}_WARP_${i} --rel --out=${file} --interp=trilinear"
  echo $cmd
  $cmd
  
  i=$(scale=0 ; echo "$i + 1" | bc)
done
echo "`basename $0`: merge outputs...."
fslmerge -t $output $full_list
imrm $full_list
imrm ${output}_WARP1_????
imrm ${output}_WARP2_????
imrm ${output}_WARP_????


echo "`basename $0` : done."
