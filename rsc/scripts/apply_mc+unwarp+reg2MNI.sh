#!/bin/bash
# Applies native space -> standard space transforms w/o intermediary write-outs.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

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
    echo "Usage: `basename $0` <input4D> <output4D> <mc mat-dir|.ecclog file|matrix file> <unwarp shiftmap> <unwarp direction: x/y/z/x-/y-/z-> <func_to_T1 mat> <T1_to_MNI warp> [<interp (default:trilinear)>] [<MNI_ref>]"
    echo "Example: `basename $0` bold mni_bold ./mc/prefiltered_func_data_mcf.mat/ ./unwarp/EF_UD_shift.nii.gz y ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz"
    echo "         `basename $0` diff mni_diff ./diff.ecclog ./unwarp/EF_UD_shift.nii.gz y ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz nn"
    echo "         `basename $0` diff mni_diff ./matrix.mat ./unwarp/EF_UD_shift.nii.gz y- ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz spline"
    echo "         `basename $0` diff mni_diff none ./unwarp/EF_UD_shift.nii.gz y- ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz spline"
    echo "         `basename $0` bold mni_bold ./mc/prefiltered_func_data_mcf.mat/ none 00 ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz trilinear"
    echo "         `basename $0` bold  T1_bold ./mc/prefiltered_func_data_mcf.mat/ none 00 none ./reg/func2highres_warp.nii.gz spline reg/highres.nii.gz"
    echo ""
    exit 1
}

[ "$7" = "" ] && Usage

input=`remove_ext "$1"`
output=`remove_ext "$2"`
mcdir="$3"
shiftmap=`remove_ext "$4"` ; douw=1 ; if [ "$shiftmap" = "none" ] ; then douw=0 ; fi
uwdir="$5" ; if [ "$uwdir" = "00" -o "$uwdir" = "0" ] ; then douw=0 ; fi
f2t1_mat="$6"
f2mni_warp=`remove_ext "$7"`
interp="$8"
if [ x"$interp" = "x" ] ; then interp="trilinear" ; fi
ref=`remove_ext "$9"`
if [ x"$ref" = "x" ] ; then ref="${FSLDIR}/data/standard/MNI152_T1_2mm_brain" ; fi

# MNI affine-only registration ?
if [ "$f2t1_mat" != "none" -a "$f2mni_warp" = "none" ] ; then MNIaff=1 ; else MNIaff=0 ; fi
if [ "$f2t1_mat" = "none" -a "$f2mni_warp" = "none" ] ; then  echo "`basename $0` : You must enter an MNI transform (warpfield or affine or both) - exiting..." ; exit 1 ; fi

# display info
echo ""
echo "`basename $0` : input:         $input"
echo "`basename $0` : output:        $output"
echo "`basename $0` : motion-corr:   $mcdir"
echo "`basename $0` : do-unwarp:     $douw"
echo "`basename $0` : uw-dir:        $uwdir"
echo "`basename $0` : uw-shiftmap:   $shiftmap"
echo "`basename $0` : func2T1_mat:   $f2t1_mat"
echo "`basename $0` : func2MNI_warp: $f2mni_warp"
echo "`basename $0` : interp:        $interp"
echo "`basename $0` : MNI-ref:       $ref"
echo "`basename $0` : MNI-aff-only:  $MNIaff"
echo ""

# motion correction or eddy-correction ?
ecclog=0 ; sinlgemat=0
if [ "$mcdir" = "none" ] ; then
  echo "`basename $0` : no motion correction."
elif [ ! -d $mcdir ] ; then
  echo "`basename $0`: '$mcdir' is not a directory..."
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
echo "`basename $0` : write func -> standard space w/o intermediary write-outs..."

# extract example_func
nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'`
mid=$(echo "scale=0 ; $nvol / 2" | bc)
fslroi $input ${output}_example_func $mid 1

# convert (relative) warps
# create shiftmap warp
if [ $douw -eq 1 ] ; then
  cmd="convertwarp --ref=${output}_example_func --shiftmap=${shiftmap} --shiftdir=${uwdir} --out=${output}_WARP1 --relout"
  echo $cmd
  $cmd
fi

# create MNI warp and concatenate
if [ $MNIaff -eq 0 ] ; then
  postmatopt=""
  if [ "$f2t1_mat" = "none" ] ; then
    cmd="convertwarp --ref=${ref} --warp1=${f2mni_warp} --out=${output}_WARP2 --relout"
  else
    cmd="convertwarp --ref=${ref} --warp1=${f2mni_warp} --premat=${f2t1_mat} --out=${output}_WARP2 --relout"
  fi
  echo $cmd
  $cmd
  # concatenate warps
  if [ $douw -eq 1 ] ; then
    cmd="convertwarp --ref=${ref} --warp1=${output}_WARP1 --warp2=${output}_WARP2 --out=${output}_WARP --relout"
    warpopt="--warp=${output}_WARP"
    
    echo $cmd
    $cmd
  else
    warpopt="--warp=${output}_WARP2"
  fi
else
  postmatopt="--postmat=$f2t1_mat"
  # concatenate warps
  if [ $douw -eq 1 ] ; then
    warpopt="--warp=${output}_WARP1"
  else
    warpopt=""
  fi
fi

# apply transforms
imrm ${output}_tmp_????.*
fslsplit $input ${output}_tmp_
full_list=`imglob ${output}_tmp_????.*`
i=0
for file in $full_list ; do
  echo "processing $file"
  if [ "$mcdir" = "none" ] ; then
    cmd="applywarp --ref=${ref} --in=${file} $warpopt $postmatopt --rel --out=${file} --interp=${interp}"
  elif [ $ecclog -eq 1 ] ; then
    line1=$(echo "$i*8 + 4" | bc -l)
    line2=$(echo "$i*8 + 7" | bc -l)
    cat ${mcdir} | sed -n "$line1,$line2"p > ${output}_tmp_ecclog.mat
    echo "${output}_tmp_ecclog.mat :"
    cat ${output}_tmp_ecclog.mat
    cmd="applywarp --ref=${ref} --in=${file} $warpopt --premat=${output}_tmp_ecclog.mat $postmatopt --rel --out=${file} --interp=${interp}"
  elif [ $sinlgemat -eq 1 ] ; then    
    cmd="applywarp --ref=${ref} --in=${file} $warpopt --premat=${mcdir} $postmatopt --rel --out=${file} --interp=${interp}"
  else
    i=`zeropad $i 4`
    cmd="applywarp --ref=${ref} --in=${file} $warpopt --premat=${mcdir}/MAT_${i} $postmatopt --rel --out=${file} --interp=${interp}"
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
imrm ${output}_WARP2
imrm ${output}_WARP
rm -f ${output}_tmp_ecclog.mat

echo "`basename $0`: done."
