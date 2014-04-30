#!/bin/bash
# Slices multiple inputs along z-direction and extracts values using labels in masks.

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

function minmaxavg() # NB: min / max values are clamped to whole numbers
{
  awk 'NR == 1 { max=$1; min=$1; sum=0 }
  { if ($1>max) max=$1; if ($1<min) min=$1; sum+=$1;}
  END {printf "%d:%d:%f\n", min, max, sum/NR}'
}

function getMin() # finds minimum in column
{
  minmaxavg | cut -d ":" -f 1 
}

function getMax() # finds maximum in column
{
  minmaxavg | cut -d ":" -f 2 
}

Usage() {
    echo ""
    echo "Usage:  `basename $0` [--vxcount|--extract] <input3D> <mask3D> <text-output> [<\"-bin\"|none>] [<\"fslmeants-opts\"|none>] [<vertcat penvalue[0|1],subjects[0|1]>]"
    echo "Example:  `basename $0` --extract \"FA-1 FA-2 FA-3\" \"FA-mask-1 FA-mask-2 FA-mask-3\" FA_vals.txt \"-bin\" \"--showall\" 0,1"
    echo "          `basename $0` --vxcount FA-list.txt FA-mask-list.txt FA_vals.txt"
    echo ""
    exit 1
}

# parse options
dovx=1 ; doex=1
if [ "$1" = "--vxcount" ] ; then dovx=1 ; doex=0 ; shift ; fi
if [ "$1" = "--extract" ] ; then dovx=0 ; doex=1 ; shift ; fi

# assign input arguments
[ "$3" = "" ] && Usage
_input="$1" ; _input="$(echo "$_input" | sed 's|,| |g')"
_mask="$2" ; _mask="$(echo "$_mask" | sed 's|,| |g')"
out="$3"
opts="$4" ; if [ x"$opts" = "x" ] ; then opts="none" ; fi
meants_opts="$5" ; if [ x"$meants_opts" = "x" ] ; then meants_opts="none" ; fi
if [ x"$6" = "x" ] ; then 
  vertcat0=0 
  vertcat1=0
else
  vertcat0=$(echo $6 | cut -d , -f 1)
  vertcat1=$(echo $6 | cut -d , -f 2)
fi

# extract shift-vector if present
shiftvector=0 ; addhigh=0 ; addlow=0
if [ $(testascii $_mask) -eq 1 ] ; then
  shiftvector=$(cat $_mask | grep -v ^# | awk '{print $2}')
  if [ x"$shiftvector" = "x" ] ; then shiftvector=0 ; echo "`basename $0`: NOTE: No z-shift column detected in '$_mask'." ; fi
  addhigh=$(echo $shiftvector | row2col | getMin | grep - || true) ; if [ x"$addhigh" = "x" ] ; then addhigh=0 ; fi ; addhigh=${addhigh#-}
  addlow=$(echo $shiftvector | row2col | getMax | grep  -v - || true) ; if [ x"$addlow" = "x" ] ; then addlow=0 ; fi ; addlow=${addlow#-}
fi

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
    masks="$(cat $_mask | grep -v ^# | awk '{print $1}')" # asuming ascii list with volumes
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
    inputs="$(cat $_input | grep -v ^#)" # asuming ascii list with volumes
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

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# checks
echo $masks  | row2col > $tmpdir/masks.txt
echo $inputs | row2col > $tmpdir/inputs.txt
echo $shiftvector | row2col > $tmpdir/shift.txt
n_lines1=$(cat $tmpdir/masks.txt | wc -l)
n_lines2=$(cat $tmpdir/inputs.txt | wc -l)
n_lines3=$(cat $tmpdir/shift.txt | wc -l)
if [ $n_lines1 -ne $n_lines2 ] ; then
  echo "`basename $0`: ERROR : Number of inputs ($n_lines2) and number of masks ($n_lines1) do not match. Exiting" ; exit 1
fi
if [ $n_lines1 -ne $n_lines3 -a x"$shiftvector" != "x0" ] ; then
  echo "`basename $0`: ERROR : Number of masks ($n_lines1) and number of shifts ($n_lines3) do not match. Exiting" ; exit 1
fi

# looping...
n_mask=0 ; mask_tmp="" ; header="" ; vxmask_tmp=""
for counter in `seq 1 $n_lines2` ; do
  mask="$(cat $tmpdir/masks.txt | sed -n ${counter}p)"
  input="$(cat $tmpdir/inputs.txt | sed -n ${counter}p)"
  
  if [ x"$opts" = "x-bin" ] ; then
    fslmaths $mask -bin $tmpdir/$(basename $mask)
    mask=$tmpdir/$(basename $mask)
  fi
  
  # rem extension
  mask=$(remove_ext $mask)
  input=$(remove_ext $input)
  
  # extract range
  n0min=$(fslstats $mask -R | awk '{print$1}')
  n0max=$(fslstats $mask -R | awk '{print$2}')

  # number of slices (z)
  Z=$(fslinfo $mask | grep ^dim3 | awk '{print $2}')
  
  # shift
  if [ x"$shiftvector" != "x0" ] ; then
    _shift=$(echo $shiftvector | row2col | sed -n ${counter}p)
  else
    _shift=0
  fi
   
  # display info
  echo "---------------------------"
  echo "`basename $0` : fsl V.:         $fslversion"
  echo "`basename $0` : input:          $input"
  echo "`basename $0` : slices(z):      $Z"
  echo "`basename $0` : mask:           $mask"
  echo "`basename $0` : mmask:          $mmask"
  echo "`basename $0` : minputs:        $minput"
  echo "`basename $0` : markers:        1 - ${n0max}"
  echo "`basename $0` : shift:          $_shift (high: $addhigh low: $addlow)"
  echo "`basename $0` : binarize:       $opts"
  echo "`basename $0` : fslmeants-opt:  $meants_opts"
  echo "`basename $0` : vert-cat pens:  $vertcat0"
  echo "`basename $0` : vert-cat subj:  $vertcat1"
  echo "`basename $0` : do-extract:     $doex"
  echo "`basename $0` : do-vxcount:     $dovx"
  echo "`basename $0` : txt-out:        $out"
  echo "---------------------------"

  # slice input in z direction
  $(dirname $0)/split4D.sh z $input [0:1:end] $tmpdir/$(basename $input)

  # slice mask in z direction
  $(dirname $0)/split4D.sh z $mask [0:1:end] $tmpdir/$(basename $mask)

  # looping...
  rm -f $tmpdir/meants_??? ; outs_tmp="" ; vxouts_tmp=""
  for n in `seq 1 $n0max` ; do # for each "color"
    meantsfiles="" ; vxfiles=""
    for i in `seq 0 $[$Z-1]` ; do # for each slice
      # segment
      cmd="$(dirname $0)/seg_mask.sh $tmpdir/$(basename $mask)_slice_$(zeropad $i 4) $n $tmpdir/$(basename $mask)_slice_$(zeropad $i 4)_$(zeropad $n 3)"
      echo $cmd ; $cmd 1 > /dev/null
      
      # extract
      if [ $doex -eq 1 ] ; then
        if [ x"$meants_opts" != "xnone" ] ; then _meants_opts=$meants_opts ; else _meants_opts="" ; fi
        cmd="fslmeants -i $tmpdir/$(basename $input)_slice_$(zeropad $i 4) -m $tmpdir/$(basename $mask)_slice_$(zeropad $i 4)_$(zeropad $n 3) $_meants_opts -o $tmpdir/_meants_$(zeropad $i 4)_$(zeropad $n 3)"
        echo $cmd ; $cmd
        
        # get last line
        lastline=$(cat $tmpdir/_meants_$(zeropad $i 4)_$(zeropad $n 3) | tail -n1)
        
        # NaN?
        if [ x"$lastline" = "x" ] ; then echo "NaN" > $tmpdir/meants_$(zeropad $i 4)_$(zeropad $n 3) ; else echo $lastline > $tmpdir/meants_$(zeropad $i 4)_$(zeropad $n 3) ; fi
        
        # clear
        rm $tmpdir/_meants_$(zeropad $i 4)_$(zeropad $n 3)
      fi
      
      # get voxel count/volume
      if [ $dovx -eq 1 ] ; then 
        cmd="fslstats $tmpdir/$(basename $mask)_slice_$(zeropad $i 4)_$(zeropad $n 3) -V"
        echo $cmd ; $cmd  | cut -d " " -f 1 > $tmpdir/vx_$(zeropad $i 4)_$(zeropad $n 3)
      fi
      
      # collect per-slice outputs
      if [ $doex -eq 1 ] ; then meantsfiles=$meantsfiles" "$tmpdir/meants_$(zeropad $i 4)_$(zeropad $n 3) ; fi
      if [ $dovx -eq 1 ] ; then vxfiles=$vxfiles" "$tmpdir/vx_$(zeropad $i 4)_$(zeropad $n 3) ; fi
    done
    
    # vert-cat per-slice outputs
    if [ $doex -eq 1 ] ; then cat $meantsfiles > $tmpdir/out_$(zeropad $n 4) ; fi
    if [ $dovx -eq 1 ] ; then cat $vxfiles > $tmpdir/vxout_$(zeropad $n 4) ; fi
    
    # shift slices if applicable
    if [ x"$shiftvector" != "x0" ] ; then
      # shift extraction
      if [ $doex -eq 1 ] ; then 
        mv $tmpdir/out_$(zeropad $n 4) $tmpdir/__out_$(zeropad $n 4)
        for sl in `seq 1 $[$addhigh+$_shift]` ; do echo 0 ; done > $tmpdir/out_$(zeropad $n 4)
        cat $tmpdir/__out_$(zeropad $n 4) >> $tmpdir/out_$(zeropad $n 4)
        for sl in `seq 1 $[$addlow-$_shift]` ; do echo 0 ; done >> $tmpdir/out_$(zeropad $n 4)
        rm $tmpdir/__out_$(zeropad $n 4)
        #cat  $tmpdir/vxout_$(zeropad $n 4)
      fi      
      # shift voxel count/volume
      if [ $dovx -eq 1 ] ; then 
        mv $tmpdir/vxout_$(zeropad $n 4) $tmpdir/__vxout_$(zeropad $n 4)
        for sl in `seq 1 $[$addhigh+$_shift]` ; do echo 0 ; done > $tmpdir/vxout_$(zeropad $n 4)
        cat $tmpdir/__vxout_$(zeropad $n 4) >> $tmpdir/vxout_$(zeropad $n 4)
        for sl in `seq 1 $[$addlow-$_shift]` ; do echo 0 ; done >> $tmpdir/vxout_$(zeropad $n 4)
        rm $tmpdir/__vxout_$(zeropad $n 4)
        #cat  $tmpdir/vxout_$(zeropad $n 4)
      fi
    fi
    
    # do heading
    header=$(basename $out)__$(basename $input)__$(basename $mask)_$(zeropad $n 3)
    if [ $doex -eq 1 ] ; then sed -i "1i $header" $tmpdir/out_$(zeropad $n 4) ; fi
    if [ $dovx -eq 1 ] ; then sed -i "1i $header" $tmpdir/vxout_$(zeropad $n 4) ; fi

    # collect n outputs (n=number of pen-values)
    if [ $doex -eq 1 ] ; then outs_tmp=$outs_tmp" "$tmpdir/out_$(zeropad $n 4) ; fi
    if [ $dovx -eq 1 ] ; then vxouts_tmp=$vxouts_tmp" "$tmpdir/vxout_$(zeropad $n 4) ; fi
    
    echo ""
  done
  
  # horz-cat or vert-cat pen-values ?
  if [ $vertcat0 -eq 1 ] ; then
    if [ $doex -eq 1 ] ; then cat $outs_tmp > $tmpdir/$(basename $out)_$(zeropad $n_mask 3) ; fi
    if [ $dovx -eq 1 ] ; then cat $vxouts_tmp > $tmpdir/vx_$(basename $out)_$(zeropad $n_mask 3) ; fi
  else
    if [ $doex -eq 1 ] ; then paste -d " " $outs_tmp > $tmpdir/$(basename $out)_$(zeropad $n_mask 3) ; fi
    if [ $dovx -eq 1 ] ; then paste -d " " $vxouts_tmp > $tmpdir/vx_$(basename $out)_$(zeropad $n_mask 3) ; fi
  fi
  
  # collect subjects
  if [ $doex -eq 1 ] ; then mask_tmp=$mask_tmp" "$tmpdir/$(basename $out)_$(zeropad $n_mask 3) ; fi
  if [ $dovx -eq 1 ] ; then vxmask_tmp=$vxmask_tmp" "$tmpdir/vx_$(basename $out)_$(zeropad $n_mask 3) ; fi
  
  # increment
  n_mask=$[$n_mask+1]
done

# horz-cat or vert-cat subjects ?
if [ $vertcat1 -eq 1 ] ; then
  if [ $doex -eq 1 ] ; then 
    echo "cat $mask_tmp > $out"
    cat  $mask_tmp > $out
  fi
  if [ $dovx -eq 1 ] ; then 
    echo "cat $vxmask_tmp > $(dirname $out)/vxcount_$(basename $out)"
    cat  $vxmask_tmp > $(dirname $out)/vxcount_$(basename $out)
  fi
else
  if [ $doex -eq 1 ] ; then 
    echo "paste -d \" \" $mask_tmp > $out"
    paste -d " " $mask_tmp > $out
  fi
  if [ $dovx -eq 1 ] ; then 
    echo "paste -d \" \" $vxmask_tmp > $(dirname $out)/vxcount_$(basename $out)"
    paste -d " " $vxmask_tmp > $(dirname $out)/vxcount_$(basename $out)
  fi
fi

# done.
echo "`basename $0` : done."
