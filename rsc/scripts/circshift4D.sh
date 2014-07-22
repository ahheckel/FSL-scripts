#!/bin/bash
# Shifts input volume by n voxels along any dimension.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 17/04/2014

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage:  `basename $0` <input> <x,y,z,t shift(in vx)> <output>"
    echo "Example:  `basename $0` in +2,-3,+10,0 out"
    echo ""
    exit 1
}

# assign input arguments
[ "$3" = "" ] && Usage
input=$(remove_ext "$1")
shifts="$2" ; shifts="$(echo "$shifts" | sed 's|,| |g')"
output=$(remove_ext "$3")

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

i=0 ; for sh in $shifts ; do
  if [ $sh -eq 0 ] ; then i=$[$i+1] ; continue ; fi
  if [ $i -eq 0 ] ; then dim="-x" ; fi
  if [ $i -eq 1 ] ; then dim="-y" ; fi
  if [ $i -eq 2 ] ; then dim="-z" ; fi
  if [ $i -eq 3 ] ; then dim="-t" ; fi
  nsh=$(echo $sh | cut -c 2-)
  if [ $(imtest $tmpdir/out) -eq 0 ] ; then imcp $input $tmpdir/out ; fi
  
  # info
  echo "`basename $0`: shifting $sh voxels along dimension '$(echo $dim| cut -c 2-)'."
  
  # prepare command for fslroi
  if [ "$(echo $sh | cut -c 1)" = "+" ] ; then
    if [ "$dim" = "-x" ] ; then n=$(fslinfo $input | grep ^dim1 | awk '{print $2}') ; fslroicmd_plus="0 $n 0 -1 0 -1 0 -1" ; fi
    if [ "$dim" = "-y" ] ; then n=$(fslinfo $input | grep ^dim2 | awk '{print $2}') ; fslroicmd_plus="0 -1 0 $n 0 -1 0 -1" ; fi
    if [ "$dim" = "-z" ] ; then n=$(fslinfo $input | grep ^dim3 | awk '{print $2}') ; fslroicmd_plus="0 -1 0 -1 0 $n 0 -1" ; fi
    if [ "$dim" = "-t" ] ; then n=$(fslinfo $input | grep ^dim4 | awk '{print $2}') ; fslroicmd_plus="0 -1 0 -1 0 -1 0 $n" ; fi
  elif [ "$(echo $sh | cut -c 1)" = "-" ] ; then
    if [ "$dim" = "-x" ] ; then n=$(fslinfo $input | grep ^dim1 | awk '{print $2}') ; fslroicmd_minus="$nsh $n 0 -1 0 -1 0 -1" ; fi
    if [ "$dim" = "-y" ] ; then n=$(fslinfo $input | grep ^dim2 | awk '{print $2}') ; fslroicmd_minus="0 -1 $nsh $n 0 -1 0 -1" ; fi
    if [ "$dim" = "-z" ] ; then n=$(fslinfo $input | grep ^dim3 | awk '{print $2}') ; fslroicmd_minus="0 -1 0 -1 $nsh $n 0 -1" ; fi
    if [ "$dim" = "-t" ] ; then n=$(fslinfo $input | grep ^dim4 | awk '{print $2}') ; fslroicmd_minus="0 -1 0 -1 0 -1 $nsh $n" ; fi
  fi

  # split
  $(dirname $0)/split4D.sh $(echo $dim|cut -d - -f 2) $input [0] $tmpdir/empty

  # clear
  split4D_tag=_slice ; if [ "$dim" = "-t" ] ; then split4D_tag="" ; fi
  fslmaths $tmpdir/empty${split4D_tag}_0000 -thr 0 -mul -1 -thr 0 $tmpdir/empty

  # replicate
  $(dirname $0)/repvol.sh $dim $tmpdir/empty $nsh $tmpdir/empty

  # merge
  echo "$(basename $0):"
  if [ "$(echo $sh | cut -c 1)" = "+" ] ; then
    cmd="fslmerge $dim $tmpdir/out $tmpdir/empty $tmpdir/out"
    echo "    $cmd" ; $cmd
    cmd="fslroi $tmpdir/out $tmpdir/out $fslroicmd_plus"
    echo "    $cmd" ; $cmd
  elif [ "$(echo $sh | cut -c 1)" = "-" ] ; then
    cmd="fslmerge $dim $tmpdir/out $tmpdir/out $tmpdir/empty"
    echo "    $cmd" ; $cmd
    cmd="fslroi $tmpdir/out $tmpdir/out $fslroicmd_minus"
    echo "    $cmd" ; $cmd
  fi
  
  #increment
  i=$[$i+1]
  echo ""
done

# copy result
imcp $tmpdir/out $output

# done.
echo "`basename $0`: done."
