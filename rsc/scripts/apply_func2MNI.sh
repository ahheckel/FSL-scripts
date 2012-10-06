#!/bin/bash
# writes func -> standard space w/o intermediary write-outs.

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <output4D> <mc mat-dir|.ecclog file|matrix file> <unwarp shiftmap> <unwarp direction: x/y/z/x-/y-/z-> <func_to_T1 mat> <T1_to_MNI warp> <interp>"
    echo "Example: `basename $0` bold mni_bold ./mc/prefiltered_func_data_mcf.mat/ ./unwarp/EF_UD_shift.nii.gz y ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz spline"
    echo "         `basename $0  diff mni_diff ./diff.ecclog ./unwarp/EF_UD_shift.nii.gz y ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz spline"
    echo "         `basename $0  diff mni_diff ./matrix.mat ./unwarp/EF_UD_shift.nii.gz y ./reg/example_func2highres.mat ./reg/highres2standard_warp.nii.gz spline"
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
interp="$8"
if [ x"$interp" = "x" ] ; then interp="trilinear" ; fi

# motion correction or eddy-correction ?
ecclog=0 ; sinlgemat=0
if [ ! -d $mcdir ] ; then
  echo "`basename $0`: '$mcdir' is not a directory..."
  if [ -f $mcdir -a ${mcdir#*.} = "ecclog" ] ; then
    echo "`basename $0`: '$mcdir' is an .ecclog file."
    ecclog=1
  elif [ -f $mcdir ] ; then
    sinlgemat=1
    echo "`basename $0`: '$mcdir' is not an .ecclog file - let's assume that it is a text file with a transformation matrix in it..."
  else
    echo "`basename $0`: '$mcdir' not found. Exiting..." ; exit 1
  fi
fi  

# display info
echo "`basename $0` : write func -> standard space w/o intermediary write-outs..."

# extract example_func
nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'`
mid=$(echo "scale=0 ; $nvol / 2" | bc)
fslroi $input ${output}_example_func $mid 1

# convert warps
  cmd="convertwarp --ref=${output}_example_func --shiftmap=${shiftmap} --shiftdir=${uwdir} --out=${output}_WARP1 --relout"
  echo $cmd
  $cmd
  
  
  cmd="convertwarp --ref=${FSL_DIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --warp1=${f2mni_warp} --premat=${f2t1_mat} --out=${output}_WARP2 --relout"
  echo $cmd
  $cmd
  
 
  cmd="convertwarp --ref=${FSL_DIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --warp1=${output}_WARP1  --warp2=${output}_WARP2 --out=${output}_WARP --relout" 
  echo $cmd
  $cmd  

# apply transforms
imrm ${output}_tmp_????.*
fslsplit $input ${output}_tmp_
full_list=`imglob ${output}_tmp_????.*`
i=0
for file in $full_list ; do
  echo "processing $file"   
  if [ $ecclog -eq 1 -o $sinlgemat -eq 1 ] ; then
    if [ $ecclog -eq 1 ] ; then
      line1=$(echo "$i*8 + 4" | bc -l)
      line2=$(echo "$i*8 + 7" | bc -l)
      cat ${mcdir} | sed -n "$line1,$line2"p > ${output}_tmp_ecclog.mat
      cmd="applywarp --ref=${FSL_DIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --in=${file} --warp=${output}_WARP --premat=${output}_tmp_ecclog.mat --rel --out=${file} --interp=${interp}"
    elif [ $sinlgemat -eq 1 ] ; then    
      cmd="applywarp --ref=${FSL_DIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --in=${file} --warp=${output}_WARP --premat=${mcdir} --rel --out=${file} --interp=${interp}"
    fi
  else
    i=`zeropad $i 4`
    cmd="applywarp --ref=${FSL_DIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --in=${file} --warp=${output}_WARP --premat=${mcdir}/MAT_${i} --rel --out=${file} --interp=${interp}"
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
imrm ${output}_WARP2
imrm ${output}_WARP
rm -f ${output}_tmp_ecclog.mat


echo "`basename $0` : done."
