#!/bin/bash
# Slices multiple inputs along z-direction using labels in masks.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 22/01/2014

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

function testascii()
{
  local file="$1"
  if LC_ALL=C grep -q '[^[:print:][:space:]]' $file; then
      echo "0"
  else
      echo "1"
  fi
}

function row2col()
{
  local dat=`cat $1`
  local i=""
  for i in $dat ; do echo $i ; done
}

Usage() {
    echo ""
    echo "Usage:  `basename $0` <input3D> <mask3D> <text-output>"
    echo "Example:  `basename $0` \"FA-1 FA-2 FA-3\" \"FA-mask-1 FA-mask-2 FA-mask-3\" FA_vals.txt"
    echo "          `basename $0` FA-list.txt FA-mask-list.txt FA_vals.txt"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# assign input arguments
_input="$1"
_mask="$2"
out="$3"

# process multiple masks ?
masks=""
if [ $(echo "$_mask" | wc -w) -eq 1 ] ; then
  if [ $(imtest $_mask) -eq 1 ] ; then # single mask
    mmask=0
    masks=$_mask
  elif [ $(testascii $_mask) -eq 1 ] ; then
    if [ $(cat $_mask | grep "[[:alnum:]]" | wc -l) -eq 1 ] ; then
      mmask=0 # single mask
    elif [ $(cat $_mask | grep "[[:alnum:]]" | wc -l) -gt 1 ] ; then
      mmask=1 # multiple masks
    else
      echo "`basename $0`: ERROR : '$_mask' is empty - exiting." ; exit 1
    fi      
    masks="$(cat $_mask)" # asuming ascii list with volumes
  else
    echo "`basename $0`: ERROR : cannot read inputfile '$_mask' - exiting." ; exit 1 
  fi
else
  mmask=1
  masks=$_mask
fi

# process multiple inputs ?
inputs=""
if [ $(echo "$_input" | wc -w) -eq 1 ] ; then
  if [ $(imtest $_input) -eq 1 ] ; then # single mask
    minput=0
    inputs=$_input
  elif [ $(testascii $_input) -eq 1 ] ; then
    if [ $(cat $_input | grep "[[:alnum:]]" | wc -l) -eq 1 ] ; then
      minput=0 # single mask
    elif [ $(cat $_input | grep "[[:alnum:]]" | wc -l) -gt 1 ] ; then
      minput=1 # multiple inputs
    else
      echo "`basename $0`: ERROR : '$_input' is empty - exiting." ; exit 1
    fi      
    inputs="$(cat $_input)" # asuming ascii list with volumes
  else
    echo "`basename $0`: ERROR : cannot read inputfile '$_input' - exiting." ; exit 1 
  fi
else
  minput=1
  inputs=$_input
fi

# fsl ver.
fslversion=$(cat $FSLDIR/etc/fslversion)

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files
#tmpdir=`pwd`/${outdir}_$(basename $0).$$ ; mkdir $tmpdir

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

echo  $masks  | row2col > $tmpdir/masks.txt
echo  $inputs | row2col > $tmpdir/inputs.txt

n_lines1=$(cat $tmpdir/masks.txt | wc -l)
n_lines2=$(cat $tmpdir/inputs.txt | wc -l)
if [ $n_lines1 -ne $n_lines2 ] ; then
  echo "`basename $0`: ERROR : Number of inputs ($n_lines2) and number of masks ($n_lines1) do not match. Exiting" ; exit 1
fi

n_mask=0 ; mask_tmp="" ; header=""
for counter in `seq 1 $n_lines2` ; do
  mask="$(cat $tmpdir/masks.txt | sed -n ${counter}p)"
  input="$(cat $tmpdir/inputs.txt | sed -n ${counter}p)"
  
  # rem extension
  mask=$(remove_ext $mask)
  input=$(remove_ext $input)
  
  # extract range
  n0min=$(fslstats $mask -R | awk '{print$1}')
  n0max=$(fslstats $mask -R | awk '{print$2}')

  # number of slices (z)
  Z=$(fslinfo $mask | grep ^dim3 | awk '{print $2}')
   
  # display info
  echo "---------------------------"
  echo "`basename $0` : fsl V.:     $fslversion"
  echo "`basename $0` : input:      $input"
  echo "`basename $0` : slices(z):  $Z"
  echo "`basename $0` : mask:       $mask"
  echo "`basename $0` : mmask:      $mmask"
  echo "`basename $0` : minputs:    $minput"
  echo "`basename $0` : markers:    1 - ${n0max}"
  echo "`basename $0` : txt-out:    $out"
  echo "---------------------------"

  # slice input in z direction
  $(dirname $0)/split4D.sh z $input [0:1:end] $tmpdir/$(basename $input)

  # slice mask in z direction
  $(dirname $0)/split4D.sh z $mask [0:1:end] $tmpdir/$(basename $mask)

  rm -f $tmpdir/meants_??? ; outs_tmp=""
  for n in `seq 1 $n0max` ; do # for each "color"
    for i in `seq 0 $[$Z-1]` ; do # for each slice
      # segment
      cmd="$(dirname $0)/seg_mask.sh $tmpdir/$(basename $mask)_slice_$(zeropad $i 4) $n $tmpdir/$(basename $mask)_slice_$(zeropad $i 4)_$(zeropad $n 3)"
      echo $cmd ; $cmd 1 > /dev/null
      
      # extract
      cmd="fslmeants -i $tmpdir/$(basename $input)_slice_$(zeropad $i 4) -m $tmpdir/$(basename $mask)_slice_$(zeropad $i 4)_$(zeropad $n 3)"
      echo $cmd ; $cmd >> $tmpdir/meants_$(zeropad $n 3)
    done
    # remove blank lines
    sed '/^$/d' $tmpdir/meants_$(zeropad $n 3) > $tmpdir/out_$(zeropad $n 4)
    # collect n outputs (n=number of colors or "nerves")
    outs_tmp=$outs_tmp" "$tmpdir/out_$(zeropad $n 4)
    header=$header" "$(basename $out)__$(basename $input)__$(basename $mask)_$(zeropad $n 3)
    echo ""
  done
  
  # horz-cat
  if [ $mmask -eq 1 ] ; then
    echo "paste -d \" \" $outs_tmp > $tmpdir/$(basename $out)_$(zeropad $n_mask 3)"
    paste -d " " $outs_tmp > $tmpdir/$(basename $out)_$(zeropad $n_mask 3)
    mask_tmp=$mask_tmp" "$tmpdir/$(basename $out)_$(zeropad $n_mask 3)
    n_mask=$[$n_mask+1]
  elif [ $mmask -eq 0 ] ; then
    echo "paste -d \" \" $outs_tmp > $out"
    paste -d " " $outs_tmp > ${out}
    sed -i "1i $header" ${out}
    n_mask=$[$n_mask+1]
  fi
done

# horz-cat masks if applicable
if [ $mmask -eq 1 ] ; then
  echo "paste -d \" \" $mask_tmp > $out"
  paste -d " " $mask_tmp > ${out}
  sed -i "1i $header" ${out}
fi

# done.
echo "`basename $0` : done."
