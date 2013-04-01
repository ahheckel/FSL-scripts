#!/bin/bash
# Applies motion-correction and unwarp-shiftmap to 4D.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 12/15/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

function testascii()
{
  local file="$1"
  if LC_ALL=C grep -q '[^[:print:][:space:]]' $file; then
      echo "0"
  else
      echo "1"
  fi
}

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <output4D> <mc mat-dir|.ecclog file|matrix file> <unwarp shiftmap> <unwarp direction: x/y/z/x-/y-/z-> [<interp (default:trilinear)>]"
    echo "Example: `basename $0` bold uw_bold ./mc/prefiltered_func_data_mcf.mat/ ./unwarp/EF_UD_shift.nii.gz y- spline"
    echo "         `basename $0` diff uw_diff ./ec_dwi.ecclog ./unwarp/EF_UD_shift.nii.gz y trilinear"
    echo "         `basename $0` diff uw_diff ./matrix.mat ./unwarp/EF_UD_shift.nii.gz y sinc"
    echo "         `basename $0` diff uw_diff none ./unwarp/EF_UD_shift.nii.gz y sinc"
    echo "         `basename $0` diff uw_diff ./mc/prefiltered_func_data_mcf.mat/ none 00 nn"
    echo ""
    exit 1
}

[ "$5" = "" ] && Usage

input=`remove_ext "$1"`
output=`remove_ext "$2"`
mcdir="$3"
shiftmap=`remove_ext "$4"` ; douw=1 ; if [ "$shiftmap" = "none" ] ; then douw=0 ; fi
uwdir="$5" ; if [ "$uwdir" = "00" -o "$uwdir" = "0" ] ; then douw=0 ; fi
interp="$6"
if [ x"$interp" = "x" ] ; then interp="trilinear" ; fi

# display info
echo ""
echo "`basename $0` : input:         $input"
echo "`basename $0` : output:        $output"
echo "`basename $0` : motion-corr:   $mcdir"
echo "`basename $0` : do-unwarp:     $douw"
echo "`basename $0` : uw-dir:        $uwdir"
echo "`basename $0` : uw-shiftmap:   $shiftmap"
echo "`basename $0` : interp:        $interp"
echo ""

# motion correction / eddy-correction ?
ecclog=0 ; sinlgemat=0
if [ "$mcdir" = "none" ] ; then
  echo "`basename $0` : no motion correction."
elif [ ! -d $mcdir ] ; then
  echo "`basename $0` : '$mcdir' is not a directory..."
  if [ -f $mcdir -a ${mcdir##*.} = "ecclog" ] ; then
    echo "`basename $0` : '$mcdir' is an .ecclog file."
    ecclog=1
  elif [ $(testascii $mcdir) -eq 1 ] ; then
    sinlgemat=1
    echo "`basename $0` : '$mcdir' is not an .ecclog file - let's assume that it is a text file with a single transformation matrix in it: "
    cat $mcdir
  else
    echo "`basename $0` : cannot read '$mcdir' - exiting..." ; exit 1
  fi
fi  

# display info
if [ $douw -eq 0 -a "$mcdir" = "none" ] ; then  echo "`basename $0` : neither motion correction nor unwarping is to be applied - just copying..." ; imcp $input $output ; exit ; fi
if [ "$mcdir" != "none" ] ; then
  echo "`basename $0` : applying motion-correction."
fi
if [ $douw -eq 1 ] ; then
  echo "`basename $0` : applying shiftmap."
fi

# extract example_func
nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'`
mid=$(echo "scale=0 ; $nvol / 2" | bc)
cmd="fslroi $input ${output}_example_func $mid 1"
echo $cmd ; $cmd

# apply unwarp?
if [ $douw -eq 1 ] ; then
  # write unwarp warpfield
  cmd="convertwarp --ref=${output}_example_func --shiftmap=${shiftmap} --shiftdir=${uwdir} --out=${output}_WARP1 --relout"
  echo $cmd
  $cmd  
  # define warpfield for applywarp
  warpopt="--warp=${output}_WARP1 "
else
  warpopt=""
fi

# combine with motion correction
imrm ${output}_tmp_????.*
fslsplit $input ${output}_tmp_
full_list=`imglob ${output}_tmp_????.*`
i=0
for file in $full_list ; do
  echo "processing $file"
  if [ "$mcdir" = "none" ] ; then
    cmd="applywarp --ref=${output}_example_func --in=${file} $warpopt --rel --out=${file} --interp=${interp}"
  elif [ $ecclog -eq 1 ] ; then
    line1=$(echo "$i*8 + 4" | bc -l)
    line2=$(echo "$i*8 + 7" | bc -l)
    cat ${mcdir} | sed -n "$line1,$line2"p > ${output}_tmp_ecclog.mat
    echo "${output}_tmp_ecclog.mat :"
    cat ${output}_tmp_ecclog.mat
    cmd="applywarp --ref=${output}_example_func --in=${file} $warpopt --premat=${output}_tmp_ecclog.mat --rel --out=${file} --interp=${interp}"  
  elif [ $sinlgemat -eq 1 ] ; then
    cmd="applywarp --ref=${output}_example_func --in=${file} $warpopt --premat=${mcdir} --rel --out=${file} --interp=${interp}"  
  else
    i=`zeropad $i 4`  
    cmd="applywarp --ref=${output}_example_func --in=${file} $warpopt --premat=${mcdir}/MAT_${i} --rel --out=${file} --interp=${interp}"  
  fi
  
  echo $cmd
  $cmd
  
  i=$(scale=0 ; echo "$i + 1" | bc)
done

# merge
echo "`basename $0`: merge outputs..."
fslmerge -t $output $full_list

# cleanup
imrm $full_list
imrm ${output}_example_func
imrm ${output}_WARP1
rm -f ${output}_tmp_ecclog.mat 

echo "`basename $0`: done."
