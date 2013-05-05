#!/bin/bash

Usage() {
    echo ""
    echo "Usage: `basename $0` <4dinput> <motion-corr:0|1> <FWHM(mm)> <hpf(s)|Inf> <TR(s)> <resolution(mm)|0>"
    echo ""
    exit 1
}

[ "$6" = "" ] && Usage

# assign input arguments
input="$(remove_ext $1)"
domc=$2
smkrnl="$3" ; _smkrnl=$(echo $smkrnl | sed "s|\.||g") # remove '.'
hpf="$4"
TR="$5"
res=$6

# display info
echo "`basename $0` : input:           $input"
echo "`basename $0` : motion-corr:     $domc"
echo "`basename $0` : smooth(FWHM):    $smkrnl"
echo "`basename $0` : hpf(s):          $hpf"
echo "`basename $0` : TR(s):           $TR"
echo "`basename $0` : resolution(mm):  $res"
echo "---------------------------"

# mid volume is...
total_volumes=`fslnvols $input 2> /dev/null`
idx=$(echo "scale=0; $total_volumes / 2" | bc)

# commands
if [ $domc -eq 1 ] ; then
  cmd="mcflirt -in $input -out ${input}_mcf -refvol $idx"
  echo "`basename $0`: $cmd" ; $cmd
  sminput=${input}_mcf
else
  sminput=${input} 
fi

cmd="$(dirname $0)/feat_smooth.sh ${sminput} ${sminput} $smkrnl $hpf $TR"
echo "`basename $0`: $cmd" ; $cmd
imrm ${sminput}_susan_mask.nii.gz
rm ${sminput}_susan_mask_vals

if [ $res -gt 0 ] ; then 
  cmd="$(dirname $0)/resample.sh ${sminput}_s${_smkrnl}_hpf${hpf} $res ${sminput}_s${_smkrnl}_hpf${hpf}_res${res}"
  echo "`basename $0`: $cmd" ; $cmd
  icainput=${sminput}_s${_smkrnl}_hpf${hpf}_res${res}
else 
  icainput=${sminput}_s${_smkrnl}_hpf${hpf}
fi

cmd="$(dirname $0)/melodic.sh ${icainput} $TR -1"
echo "`basename $0`: $cmd" ; $cmd

# done
echo "`basename $0`: done."
