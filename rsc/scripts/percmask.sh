#!/bin/bash

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/04/2014

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e


Usage() {
    echo ""
    echo "Usage: `basename $0` <volume> <exclude-mask|none> <out-mask> [<lower percentile(def:65)>] [<higher percentile(def:75)>]"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

t2="$(remove_ext $1)"
mask="$(remove_ext $2)"
out="$3"
if [ x"$4" = "x" ] ; then lowperc=65 ; else lowperc=$4 ; fi
if [ x"$5" = "x" ] ; then highperc=75 ; else highperc=$5 ; fi

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

echo "`basename $0`:"

# dilate nerve mask
if [ "$mask" != "none" ] ; then
  cmd="fslmaths $mask -bin -kernel 2D -dilF $tmpdir/mask_bin_dilF"
  echo "    $cmd" ; $cmd
fi

# bet image
cmd="bet $t2 $tmpdir/t2_bet -f 0.1 -m"
echo "    $cmd" ; $cmd

# erode
cmd="fslmaths $tmpdir/t2_bet_mask -kernel 2D -ero -ero $tmpdir/t2_bet_mask"
echo "    $cmd" ; $cmd

# remove nerve
if [ "$mask" != "none" ] ; then
  cmd="fslmaths $tmpdir/t2_bet_mask -sub $tmpdir/mask_bin_dilF -thr 0 -bin $tmpdir/t2_bet_nonerve"
  echo "    $cmd" ; $cmd
else
  cmd="imcp $tmpdir/t2_bet_mask $tmpdir/t2_bet_nonerve"
  echo "    $cmd" ; $cmd
fi

# z-slice
Z=$(fslinfo $t2 | grep ^dim3 | awk '{print $2}')
$(dirname $0)/split4D.sh z $tmpdir/t2_bet_nonerve [0:1:end] $tmpdir/t2_bet_nonerve
$(dirname $0)/split4D.sh z $t2 [0:1:end] $tmpdir/t2

# for each slice...
_ms=""
for i in `seq 0 $[$Z-1]` ; do 
  _m=$tmpdir/t2_bet_nonerve_slice_$(zeropad $i 4)
  _t2=$tmpdir/t2_slice_$(zeropad $i 4)

  # remove vasculature from bet-mask
  cmd="fslmaths $_t2 -mas $_m -thr $(fslstats $_t2 -k $_m -p $highperc) -bin ${_m}_1"
  echo "    $cmd" ; $cmd

  # additionally remove fat/bone
  cmd="fslmaths $_t2 -mas $_m -thr $(fslstats $_t2 -k $_m -p $lowperc) -bin ${_m}_0"
  echo "    $cmd" ; $cmd
  
  cmd="fslmaths ${_m}_0 -sub ${_m}_1 -thr 0 -bin ${_m}_done"
  echo "    $cmd" ; $cmd
  
  _ms=$_ms" "${_m}_done
done
fslmerge -z $tmpdir/t2_bet_done $_ms

# copy to output
cmd="imcp $tmpdir/t2_bet_done $out"
echo "    $cmd" ; $cmd

# done
echo "`basename $0`: done."
