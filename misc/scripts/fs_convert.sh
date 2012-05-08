
#!/bin/bash
# convert FS format to FSL format / normalize WM-intensity and conform to 256^3 at 1mm (or another isotropic resolution)

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` [-n] <input> <output> [<resolution>]"
    echo ""
    exit 1
}

if [ "$1" = "-n" ] ; then 
  normalize=1
  shift
else 
  normalize=0
fi

[ "$2" = "" ] && Usage

input=$1
out=$2
res=$3

if [ x"$res" = "x" ] ; then 
  resopt=""
else
  resopt="-applyisoxfm $res"
fi


if [ $normalize -eq 1 ] ; then
  mri_convert $input ${input%%.*}.mnc -odt float
  nu_correct ${input%%.*}.mnc ${input%%.*}_nu.mnc
  mri_normalize ${input%%.*}_nu.mnc ${input%%.*}_nu_norm.mnc
  mri_convert ${input%%.*}_nu_norm.mnc ${input%%.*}_nu_norm.nii.gz -odt float

  rm -f ${input%%.*}.mnc ${input%%.*}_nu.mnc ${input%%.*}_nu_norm.mnc ${input%%.*}_nu.imp

  fslreorient2std ${input%%.*}_nu_norm ${input%%.*}_nu_norm
  flirt -in ${input%%.*}_nu_norm.nii.gz -ref ${input%%.*}_nu_norm.nii.gz $resopt -out ${out}

  rm -f ${input%%.*}_nu_norm.nii.gz ${input%%.*}_nu_norm.nii.gz  
else
  mri_convert $input $out -odt float
  fslreorient2std $out $out
  if [ x"$resopt" != "x" ] ; then 
    flirt -in $out -ref $out $resopt -out ${out}
  fi  

fi

echo "`basename $0`: done."
