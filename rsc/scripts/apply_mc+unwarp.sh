#!/bin/bash
# apply motion correction and unwarp shiftmap to 4Ds

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <output4D> <mc mat-dir> <unwarp shiftmap> <unwarp direction: x/y/z/x-/y-/z-> <interp (default:trilinear)>"
    echo "Example: `basename $0` bold uw_bold ./mc/prefiltered_func_data_mcf.mat/ ./unwarp/EF_UD_shift.nii.gz y spline"
    echo ""
    exit 1
}

[ "$5" = "" ] && Usage

input=`remove_ext "$1"`
output=`remove_ext "$2"`
mcdir="$3"
shiftmap="$4"
uwdir="$5"
interp="$6"
if [ x"$interp" = "x" ] ; then interp="trilinear" ; fi

echo "`basename $0` : applying motion-correction and shiftmap..."

nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'`
mid=$(echo "scale=0 ; $nvol / 2" | bc)
fslroi $input ${output}_example_func $mid 1


  cmd="convertwarp --ref=${output}_example_func --shiftmap=${shiftmap} --shiftdir=${uwdir} --out=${output}_WARP1 --relout"
  echo $cmd
  $cmd
  

imrm ${output}_tmp_????.*
fslsplit $input ${output}_tmp_
full_list=`imglob ${output}_tmp_????.*`
i=0
for file in $full_list ; do
  i=`zeropad $i 4`
  
  echo "processing $file"
 
  cmd="applywarp --ref=${output}_example_func --in=${file} --warp=${output}_WARP1 --premat=${mcdir}/MAT_${i} --rel --out=${file} --interp=${interp}"
  echo $cmd
  $cmd
  
  i=$(scale=0 ; echo "$i + 1" | bc)
done
echo "`basename $0`: merge outputs...."
fslmerge -t $output $full_list
outdir=$(dirname $output)
fslroi $output $outdir/example_func $mid 1
imrm $full_list
imrm ${output}_example_func
imrm ${output}_WARP1


echo "`basename $0` : done."
