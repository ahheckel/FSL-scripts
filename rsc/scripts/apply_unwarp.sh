#!/bin/bash
# apply unwarp shiftmap to 4Ds

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <output4D> <unwarp shiftmap> <unwarp direction: x/y/z/x-/y-/z-> <interp (default:trilinear)>"
    echo "Example: `basename $0` bold uw_bold ./unwarp/EF_UD_shift.nii.gz y spline"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage

input=`remove_ext "$1"`
output=`remove_ext "$2"`
shiftmap="$3"
uwdir="$4"
interp="$5"
if [ x"$interp" = "x" ] ; then interp="trilinear" ; fi

echo "`basename $0` : applying shiftmap..."

nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'`
mid=$(echo "scale=0 ; $nvol / 2" | bc)
fslroi $input ${output}_example_func $mid 1

  cmd="convertwarp --ref=${output}_example_func --shiftmap=${shiftmap} --shiftdir=${uwdir} --out=${output}_WARP1 --relout"
  echo $cmd
  $cmd
    
  cmd="applywarp --ref=${output}_example_func --in=${input} --warp=${output}_WARP1 --rel --out=${output} --interp=${interp}"
  echo $cmd
  $cmd

outdir=$(dirname $output)
fslroi $output $outdir/example_func $mid 1

imrm ${output}_example_func
imrm ${output}_WARP1


echo "`basename $0` : done."
