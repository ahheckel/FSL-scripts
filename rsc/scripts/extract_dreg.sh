#!/bin/bash
# Extracts values from binarized clusters in significance maps.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 05/25/2014

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

function testascii()
{
  local file="$1"
  if [ ! -f $file ] ; then 
      echo "0"
  elif LC_ALL=C grep -q '[^[:print:][:space:]]' $file; then
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
    echo "Usage:  `basename $0` <input-SPM> <effect-maps> <text-output> <p-val> [<\"fslmeants-opts\"|none>](def:none)"
    echo "Example:  `basename $0` \"SPM-1,SPM-2,SPM-3\" \"effect1 effect2 effect3\" Out_table.txt 0.975 \"--eig\""
    echo "          `basename $0` SPM.txt Effect.txt Out_table.txt 0.975"
    echo "          `basename $0` SPM.txt Dummy.txt Out_table.txt 0.975"
    echo ""
    exit 1
}


# assign input arguments
[ "$4" = "" ] && Usage
_spm="$1" ; _spm="$(echo "$_spm" | sed 's|,| |g')"
_effect="$2" ; _effect="$(echo "$_effect" | sed 's|,| |g')"
out="$3"
pthres=$4
opts="$5"

# text-file as input ?
if [ $(testascii $_spm) -eq 1 ] ; then
  spm=$(cat $_spm)
else
  spm=$_spm
fi
if [ $(testascii $_effect) -eq 1 ] ; then
  effect=$(cat $_effect)
else
  effect=$_effect
fi

# fsl ver.
fslversion=$(cat $FSLDIR/etc/fslversion)

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# checks
echo  $effect  | row2col > $tmpdir/effects.txt
echo  $spm | row2col > $tmpdir/spms.txt
n_lines1=$(cat $tmpdir/spms.txt | wc -l)
n_lines2=$(cat $tmpdir/effects.txt | wc -l)
if [ $n_lines1 -ne $n_lines2 ] ; then
  echo "`basename $0`: NOTE : Number of spms ('$n_lines1') and number of effects ($n_lines2) do not match."
fi

# display info
echo "---------------------------"
echo "`basename $0` : fsl V.:     $fslversion"
echo "`basename $0` : spm(-txt):  $_spm"
echo "`basename $0` : n_spms:     $n_lines1"
echo "`basename $0` : data:       $_effect"
echo "`basename $0` : txt-out:    $out"
echo "---------------------------"

# looping...
spm_counter=0 ; eff_counter=0
out_tmp="" ; out_out_tmp="" ; header=""
for spm_counter in `seq 1 $n_lines1` ; do
  spm="$(cat $tmpdir/spms.txt | sed -n ${spm_counter}p)" ; spm=$(remove_ext $spm)
  # display info
  echo "`basename $0` : spm:        $spm"
  
  # cluster
  echo ""
  cluster -i $spm -t $pthres
  echo ""
  
  # number of clusters
  n_cl=$(cluster -i $spm -t $pthres -o $tmpdir/spm_${spm_counter} | grep ^[[:digit:]] | wc -l)
  # ic number (dual_regression)
  n_ic=$(echo ${spm##*ic} | cut -d _ -f 1 | bc)
  
  # display info
  dregdir=$(dirname $(dirname $(dirname $spm)))
  echo "`basename $0` : dreg-dir:   $dregdir"
  echo "`basename $0` : n_clusters  $n_cl"
  echo "`basename $0` : n_ic:       $n_ic"
  echo "`basename $0` : p-thres:    $pthres"
  
  # search for (effect-)files (presuming dreg-directory structure)
  imglob $dregdir/dr_stage2_subject[0-9][0-9][0-9][0-9][0-9].nii.gz | row2col | sort > $tmpdir/effects.txt
  n_lines2=$(cat $tmpdir/effects.txt | wc -l)

  # check
  if [ $n_lines2 -eq 0 ] ; then
    echo "`basename $0` : ERROR: '$dregdir/dr_stage2_subject\*.nii.gz' files found ... exiting." exit 1 
  fi  

  # display info
  echo "`basename $0` : n_effects:  $n_lines2"
  echo "---------------------------"
  
  for eff_counter in `seq 1 $n_lines2` ; do
    effect="$(cat $tmpdir/effects.txt | sed -n ${eff_counter}p)" ; effect=$(remove_ext $effect)
    cmd="$(dirname $0)/split4D.sh t $effect [$n_ic] $tmpdir/ic"
    #echo "    $cmd"
    $cmd
  
    cmd="fslmeants -i $tmpdir/ic_$(zeropad $n_ic 4) $opts --label=$tmpdir/spm_${spm_counter} -o $tmpdir/spm_${spm_counter}_eff_${eff_counter}"
    echo "    $cmd"
    $cmd
    out_tmp=$out_tmp" "$tmpdir/spm_${spm_counter}_eff_${eff_counter}
  done
  for i in `seq 1 $n_cl` ; do
    header=$header" "${spm}__cluster${i}
  done
  echo $header > $tmpdir/header
  cat $tmpdir/header $out_tmp > $tmpdir/$(basename $out)_${spm_counter} # concat effects/subjects
  out_tmp="" ; header=""
  out_out_tmp=$out_out_tmp" "$tmpdir/$(basename $out)_${spm_counter}
done
paste -d " " $out_out_tmp > $out # concat spms
  
# done.
echo "`basename $0` : done."
