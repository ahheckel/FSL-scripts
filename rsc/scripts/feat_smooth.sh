#!/bin/bash
# The FEAT way of smoothing.
# NOTE: also performs grand mean scaling.

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <4dinput> <4doutput> <\"FWHM kernels\"> <\"HighPass cutoffs\"|'none'> [<TR>] [<subj_idx>] [<sess_idx>]"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage
data=`remove_ext "$1"`
out=`remove_ext "$2"`
BOLD_SMOOTHING_KRNLS="$3"
hpf_cutoffs="$4"
if [ x"$hpf_cutoffs" = "x" -o "$hpf_cutoffs" = "none" ] ; then 
  dohpf=0
else 
  dohpf=1
  tr=$5  
fi
subj="$6"  # optional
sess="$7"  # optional

echo "`basename $0`: subj $subj , sess $sess : smoothing $data with [ $BOLD_SMOOTHING_KRNLS ] (FWHM) kernels -> ${out}_[${BOLD_SMOOTHING_KRNLS}] ..." 

# making mask
$(dirname $0)/feat_mask.sh ${data} ${out}_susan_mask $subj $sess
median_intensity=`cat ${out}_susan_mask_vals |  awk '{print $4}'`
susan_int=`cat ${out}_susan_mask_vals |  awk '{print $5}'`

echo "`basename $0`: subj $subj , sess $sess : masking `basename ${data}` -> `basename ${out}_thresh`..."
fslmaths ${data} -mas ${out}_susan_mask ${out}_thresh

echo "`basename $0`: subj $subj , sess $sess : generating mean from `basename ${out}_thres` -> *_susan_mean_func..."
fslmaths ${out}_thresh -Tmean ${out}_susan_mean_func

# smoothing
for sm_krnl in $BOLD_SMOOTHING_KRNLS ; do
  _sm_krnl=$(echo $sm_krnl | sed "s|\.||g") # remove '.'
  smoothsigma=$(echo "scale=10; $sm_krnl / 2.355" | bc -l)

  if [ $smoothsigma = "0" ] ; then 
    echo "`basename $0`: subj $subj , sess $sess : FWHM: $sm_krnl - sigma: $smoothsigma -> no smoothing..."
    imcp ${out}_thresh ${out}_smooth
  else
    echo "`basename $0`: subj $subj , sess $sess : FWHM: $sm_krnl - sigma: $smoothsigma"
    cmd="susan ${out}_thresh $susan_int $smoothsigma 3 1 1 ${out}_susan_mean_func $susan_int ${out}_smooth"
    echo "`basename $0`: subj $subj , sess $sess : executing command: $cmd"
    $cmd
  fi
  
  echo "`basename $0`: subj $subj , sess $sess : masking `basename ${out}_smooth` -> `basename ${out}_smooth`..."
  fslmaths ${out}_smooth -mas ${out}_susan_mask ${out}_smooth
  
  # global mean scaling
  normmean=10000
  $(dirname $0)/feat_scale.sh ${out}_smooth ${out}_intnorm "global" $normmean $median_intensity $subj $sess  
  echo "`basename $0`: subj $subj , sess $sess : writing ${out}_s${_sm_krnl}..."
  fslmaths ${out}_intnorm ${out}_s${_sm_krnl}
  
  # high pass filtering (if applicable)
  if [ $dohpf -eq 1 ] ; then
    for hpf_cutoff in $hpf_cutoffs ; do
      echo "`basename $0`: subj $subj , sess $sess : high pass filtering with cutoff '$hpf_cutoff' (s) -> ${out}_s${_sm_krnl}_hpf${hpf_cutoff}..."
      $(dirname $0)/feat_hpf.sh ${out}_s${_sm_krnl} ${out}_s${_sm_krnl}_hpf${hpf_cutoff} $hpf_cutoff $tr $subj $sess
    done # end hpf_cutoff
    imrm ${out}_s${_sm_krnl}
  fi
done # end sm_krnl

# cleanup
echo "`basename $0`: subj $subj , sess $sess : cleanup..."
imrm ${out}_intnorm ${out}_smooth ${out}_bet ${out}_thresh ${out}_smooth_usan_size ${out}_susan_mean_func

echo "`basename $0`: subj $subj , sess $sess : done."
