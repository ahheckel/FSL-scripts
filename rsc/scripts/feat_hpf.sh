#!/bin/bash
# The FEAT way of high-pass filtering.

# Based on FSL's featlib.tcl (v. 4.1.9). 
# Adapted by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <4dinput> <output> <hpf(s)> <TR(s)> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage
data=`remove_ext "$1"`
out=`remove_ext "$2"`
hpf="$3"
TR="$4"
subj="$5"  # optional
sess="$6"  # optional

if [ $hpf = "inf" -o $hpf = "Inf" ] ; then 
  fslmaths $data ${out}
else
  hp_sigma_sec=$(echo "scale=9; $hpf / 2.0" | bc -l)
  hp_sigma_vol=$(echo "scale=9; $hp_sigma_sec / $TR" | bc -l)
  echo "`basename $0`: subj $subj , sess $sess : highpass temporal filtering of ${data} (Gaussian-weighted least-squares straight line fitting, with sigma=${hp_sigma_sec}s)..."
  cmd="fslmaths $data -bptf $hp_sigma_vol -1 ${out}" ; echo $cmd
  $cmd
fi

echo "`basename $0`: subj $subj , sess $sess : done."
