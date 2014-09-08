#!/bin/bash
# Computes T2 relaxation time from 4D multi-echo.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 09/07/2014

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <TE1,TE2,TE3,TE4(ms),...> <output4D>"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# define vars
input=`remove_ext "$1"`
TE="$2" ; TE="$(echo "$TE" | sed 's|,| |g')"
output=`remove_ext "$3"`

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# check
n_echo=$(fslnvols $input)
if [ $n_echo -lt 2 ] ; then
  echo "`basename $0` : ERROR: '$input' needs to contain at least 2 volumes (echoes) - exiting..." ; exit 1
fi
if [ $n_echo -ne $(echo $TE | wc -w) ] ; then
  echo "`basename $0` : ERROR: number of volumes in '$input' ($n_echo) and number of provided echo-times ($(echo $TE | wc -w)) do not match - exiting..." ; exit 1
fi

if [ $n_echo -gt 2 ] ; then
  # create design matrix
  for i in $TE ; do
    echo -${i} 1
  done > $tmpdir/design
  # execute
  echo "`basename $0` : fitting exponential ($n_echo echoes)..."
  cmd="fslmaths $input -log $tmpdir/input"
  echo "    $cmd"  ; $cmd
  cmd="fsl_glm -i $tmpdir/input -d $tmpdir/design -o $tmpdir/out --out_res=$tmpdir/res"
  echo "    $cmd"  ; $cmd
  cmd="fslroi $tmpdir/out $tmpdir/T2 0 1"
  echo "    $cmd"  ; $cmd
  cmd="fslroi $tmpdir/out $tmpdir/S0 1 1"
  echo "    $cmd"  ; $cmd
  cmd="fslmaths $tmpdir/T2 -recip ${output}_T2"
  echo "    $cmd"  ; $cmd
  cmd="fslmaths $tmpdir/S0 -exp ${output}_S0"
  echo "    $cmd"  ; $cmd
  #cmd="fslmaths $tmpdir/res ${output}_res"
  #echo "    $cmd"  ; $cmd
elif [ $n_echo -eq 2 ] ; then
  dTE="$(echo "$TE" | sed 's| |-|g')"
  dTE=$(echo $dTE | bc -l)
  # execute
  echo "`basename $0` : calculating T2 (dTE=${dTE}ms, $n_echo echoes)..."
  cmd="fslroi $input $tmpdir/0 0 1"
  echo "    $cmd"  ; $cmd
  cmd="fslroi $input $tmpdir/1 1 1"
  echo "    $cmd"  ; $cmd
  cmd="fslmaths $tmpdir/0 -div $tmpdir/1 $tmpdir/div" 
  echo "    $cmd"  ; $cmd
  cmd="fslmaths $tmpdir/div -log -recip -mul $dTE ${output}_T2" 
  echo "    $cmd"  ; $cmd
fi

# done
echo "`basename $0` : done."
