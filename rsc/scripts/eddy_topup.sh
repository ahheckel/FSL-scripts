#!/bin/bash
# Applies EDDY (FSL v5) to a TOPUP directory, which was created with topup.sh.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/27/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <topup-directory> <output-name>"
    echo ""
    exit 1
}


[ "$2" = "" ] && Usage

fldr="$1"
out="$2"
wd="`pwd`"

# check version of FSL
fslversion=$(cat $FSLDIR/etc/fslversion | cut -d . -f 1)
if [ $fslversion -lt 5 ] ; then echo "`basename $0`: ERROR : only works with FSL >= 5 ! (FSL $(cat $FSLDIR/etc/fslversion) was detected.)  Exiting." ; exit 1 ; fi

# concatenate bvals/bvecs (minus first)
paste -d " " $fldr/bvalsminus_concat.txt $fldr/bvalsplus_concat.txt > $fldr/eddy_bvals_concat.txt
paste -d " " $fldr/bvecsminus_concat.txt $fldr/bvecsplus_concat.txt > $fldr/eddy_bvecs_concat.txt

# create eddy's index text file
N=$(for i in `seq 1 $(cat $fldr/diff.files | wc -l)` ; do cat $fldr/diff.files | sed -n ${i}p | cut -d : -f 2 ; done)
indexlist=$(k=1 ; for i in $N ; do for j in `seq 1 $i` ; do echo $k ; done ; k=$[$k+1] ;  done)
echo $indexlist > $fldr/eddy_index.txt

# change to TOPUP directory
cd $fldr

  # define variables
  bvecs=eddy_bvecs_concat.txt
  bvals=eddy_bvals_concat.txt
  dwi=diffs_merged.nii.gz
  mask=uw_nodif_brain_mask.nii.gz
  acqp=$(ls *_acqparam_lowb.txt)
  topup_basename=$(ls *_movpar.txt)
  topup_basename=$(echo ${topup_basename%_mov*})
  eddy_index=eddy_index.txt

  # display info
  echo "`basename $0`: bvals          : $bvals"
  echo "`basename $0`: bvecs          : $bvecs"
  echo "`basename $0`: dwi            : $dwi"
  echo "`basename $0`: mask           : $mask"
  echo "`basename $0`: acqp           : $acqp"
  echo "`basename $0`: topup_basename : $topup_basename"
  echo "`basename $0`: eddy_index     : $eddy_index"

  # execute eddy...
  echo "`basename $0`: executing eddy:"
  cmd="eddy --imain=${dwi} --mask=${mask} --bvecs=${bvecs} --bvals=${bvals} --out=${out} --acqp=${acqp} --topup=${topup_basename} --index=${eddy_index} -v"
  echo "    $cmd" ; $cmd

# change to prev. working directory
cd $wd
