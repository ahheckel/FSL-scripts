#!/bin/bash
# apply motion correction and unwarp shiftmap to 4Ds

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <output4D> <mc mat-dir | .ecclog file> <unwarp shiftmap> <unwarp direction: x/y/z/x-/y-/z-> <interp (default:trilinear)>"
    echo "Example: `basename $0` bold uw_bold ./mc/prefiltered_func_data_mcf.mat/ ./unwarp/EF_UD_shift.nii.gz y spline"
    echo "Example: `basename $0` diff uw_diff ./ec_dwi.ecclog ./unwarp/EF_UD_shift.nii.gz y spline"
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

# motion correction or eddy-correction ?
ecclog=0
if [ ! -d $mcdir ] ; then
  if [ -f $mcdir -a ${mcdir#*.} = "ecclog" ] ; then
    echo "`basename $0`: '$mcdir' is an .ecclog file."
    ecclog=1
  else
    echo "`basename $0`: '$mcdir' is neither a directory nor an .ecclog file. Exiting..." ; exit 1
  fi
fi  

echo "`basename $0` : applying motion-correction and shiftmap..."

# write unwarp warpfield
nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'`
mid=$(echo "scale=0 ; $nvol / 2" | bc)
fslroi $input ${output}_example_func $mid 1
cmd="convertwarp --ref=${output}_example_func --shiftmap=${shiftmap} --shiftdir=${uwdir} --out=${output}_WARP1 --relout"
echo $cmd
$cmd


# combine with motion correction
imrm ${output}_tmp_????.*
fslsplit $input ${output}_tmp_
full_list=`imglob ${output}_tmp_????.*`
i=0
for file in $full_list ; do
  echo "processing $file"

  if [ $ecclog -eq 1 ] ; then
    line1=$(echo "$i*8 + 4" | bc -l)
    line2=$(echo "$i*8 + 7" | bc -l)
    cat ${mcdir} | sed -n "$line1,$line2"p > ${output}_tmp_ecclog.mat
    cmd="applywarp --ref=${output}_example_func --in=${file} --warp=${output}_WARP1 --premat=${output}_tmp_ecclog.mat --rel --out=${file} --interp=${interp}"  
  else
    i=`zeropad $i 4`  
    cmd="applywarp --ref=${output}_example_func --in=${file} --warp=${output}_WARP1 --premat=${mcdir}/MAT_${i} --rel --out=${file} --interp=${interp}"  
  fi
  
  echo $cmd
  $cmd
  
  i=$(scale=0 ; echo "$i + 1" | bc)
done

# merge
echo "`basename $0`: merge outputs...."
fslmerge -t $output $full_list
outdir=$(dirname $output)
fslroi $output $outdir/example_func $mid 1

# cleanup
imrm $full_list
imrm ${output}_example_func
imrm ${output}_WARP1
rm -f _tmp_ecclog.mat

echo "`basename $0` : done."
