#!/bin/bash
# Normalize 4D: Divide by maximum value per volume and threshold result.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 18/02/2014

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage: $(basename $0) <input4D> <mask|none> <threshold|none> <output4D>"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage

# define input arguments
input=`${FSLDIR}/bin/remove_ext ${1}`
mask=`${FSLDIR}/bin/remove_ext ${2}`
prop=$3
output=`${FSLDIR}/bin/remove_ext ${4}`

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# check inputs and create mask if applicable
if [ `${FSLDIR}/bin/imtest $input` -eq 0 ];then
  echo "`basename $0`: '$input' does not exist or is not in a supported format."
  exit 1
fi
if [ x"$mask" = "xnone" ] ; then
  echo "`basename $0`: creating mask..."
  mask=$tmpdir/mask
  fslmaths $input -abs -Tmax -bin $mask
else
  if [ `${FSLDIR}/bin/imtest $mask` -eq 0 ];then
    echo "`basename $0`: '$mask' does not exist or is not in a supported format."
    exit 1
  fi
fi

# split
imrm ${tmpdir}/$(basename $input)_tmp????.*
fslsplit $input ${tmpdir}/$(basename $input)_tmp
full_list=`imglob ${tmpdir}/$(basename $input)_tmp????.*`

# normalize each volume
for i in $full_list ; do
  echo -n "$(basename $0): normalizing ${i}... "
  maximum=$(fslstats $i -k $mask -R | cut -d " " -f 2)
  echo "max : $maximum --- thres : $prop"
  if [ x"$prop" = "xnone" ] ; then
    fslmaths $i -div $maximum $i
  else
    fslmaths $i -div $maximum -thr $prop $i
  fi
done

# merge results
fslmerge -t $output $full_list

# cleanup
imrm $full_list

# done
echo "`basename $0`: done."
