
#!/bin/bash
# The FEAT way of smoothing.
# NOTE: also performs grand mean scaling.

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <4dinput> <4doutput> <"FWHM kernels"> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage
data=`remove_ext "$1"`
out=`remove_ext "$2"`
BOLD_SMOOTHING_KRNLS="$3"
subj="$4"  # optional
sess="$5"  # optional

echo "`basename $0`: subj $subj , sess $sess : smoothing $data with [ $BOLD_SMOOTHING_KRNLS ] (FWHM) kernels -> ${out}_[${BOLD_SMOOTHING_KRNLS}] ..." 

# making mask
$(dirname $0)/feat_mask.sh ${data} $(dirname ${out})/susan_mask $subj $sess
susan_int=`cat $(dirname ${out})/susan_mask_vals |  awk '{print $5}'`
median_intensity=`cat $(dirname ${out})/susan_mask_vals |  awk '{print $4}'`

echo "`basename $0`: subj $subj , sess $sess : masking `basename ${data}` -> `basename ${out}_thresh`..."
fslmaths ${data} -mas $(dirname $out)/susan_mask ${out}_thresh

echo "`basename $0`: subj $subj , sess $sess : generating mean from `basename ${out}_thres` -> susan_mean_func..."
fslmaths ${out}_thresh -Tmean $(dirname $out)/susan_mean_func

# smoothing
for sm_krnl in $BOLD_SMOOTHING_KRNLS ; do
  _sm_krnl=$(echo $sm_krnl | sed "s|\.||g") # remove '.'
  smoothsigma=$(echo "scale=10; $sm_krnl / 2.355" | bc -l)

  if [ $smoothsigma = "0" ] ; then 
    echo "`basename $0`: subj $subj , sess $sess : FWHM: $sm_krnl - sigma: $smoothsigma -> no smoothing..."
    imcp ${out}_thresh ${out}_smooth
  else
    echo "`basename $0`: subj $subj , sess $sess : FWHM: $sm_krnl - sigma: $smoothsigma"
    cmd="susan ${out}_thresh $susan_int $smoothsigma 3 1 1 $(dirname $out)/susan_mean_func $susan_int ${out}_smooth"
    echo "`basename $0`: subj $subj , sess $sess : executing command: $cmd"
    $cmd
  fi
  
  echo "`basename $0`: subj $subj , sess $sess : masking `basename ${out}_smooth` -> `basename ${out}_smooth`..."
  fslmaths ${out}_smooth -mas $(dirname $out)/susan_mask ${out}_smooth
  
  # global mean scaling
  normmean=10000
  $(dirname $0)/feat_scale.sh ${out}_smooth ${out}_intnorm "global" $normmean $median_intensity $subj $sess
  echo "`basename $0`: subj $subj , sess $sess : writing ${out}_s${_sm_krnl}..."
  fslmaths ${out}_intnorm ${out}_s${_sm_krnl}              
done # end sm_krnl

# cleanup
echo "`basename $0`: subj $subj , sess $sess : cleanup..."
imrm ${out}_intnorm ${out}_smooth ${out}_bet ${out}_thresh ${out}_smooth_usan_size $(dirname $out)/susan_mean_func

echo "`basename $0` : subj $subj , sess $sess : done."
