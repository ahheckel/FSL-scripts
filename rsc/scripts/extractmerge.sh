#!/bin/bash
# Extracts and merges volumes from a series of 4D input files (for clusters).
# NOTE: This script is self-submitting and should never be submitted to a cluster.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 06/26/2013

set -e

trap 'echo "$0 : An ERROR has occured."' ERR
    
Usage() {
    echo ""
    echo "Usage: `basename $0` <out4D> <indices|all|mid> [<fslmaths unary operator>] <\"input files\"> [<qsub logdir>]"
    echo "Example: `basename $0` ./chk/means.nii.gz [0,1,2:2:end-1] -Tmean \"\$inputs\" /tmp"
    echo "         `basename $0` ./chk/means.nii.gz [0,1,2,3] -Tmean \"\$inputs\" /tmp"
    echo "         `basename $0` ./chk/bolds.nii.gz [0,1,2,3] none \"\$inputs\" /tmp"
    echo "         `basename $0` ./chk/bolds.nii.gz 0 \"\$inputs\" /tmp"
    echo "         `basename $0` ./chk/bolds.nii.gz mid \"\$inputs\""
    echo "         `basename $0` ./chk/bolds.nii.gz all -Tmean \"\$inputs\" /tmp"
    echo ""
    exit 1
}

delJIDs() {
  if [ x"SGE_ROOT" != "x" ] ; then
     local jidfile="$1" ; local i="" ; local j=0
     for i in $(cat $jidfile) ; do
        qdel $i
        j=$[$j+1]
     done
  fi
  rm -f $jidfile
  if [ $j -eq 0 ] ; then echo "`basename $0`: no job left to erase (OK)." ; fi
}

function isStillRunning() 
{ 
  if [ "x$SGE_ROOT" = "x" ] ; then echo "0"; return; fi # is cluster environment present ?
  
  # does qstat work ?
  qstat &>/dev/null
  if [ $? != 0 ] ; then 
    echo "ERROR : qstat failed. Is Network available ?" >&2
    echo "1"
    return
  fi
  
  local ID=$1
  local user=`whoami | cut -c 1-10`
  local stillrunnning=`qstat | grep $user | awk '{print $1}' | grep $ID | wc -l`
  echo $stillrunnning
}

function waitIfBusyIDs() 
{
  local IDfile=$1
  local ID=""
  echo -n "waiting..."
  for ID in $(cat $IDfile) ; do
    if [ `isStillRunning $ID` -gt 0 ] ; then
      while [ `isStillRunning $ID` -gt 0 ] ; do echo -n '.' ; sleep 5 ; done
    fi
  done
  echo "done."
  rm $IDfile ; touch $IDfile
}

# define vars
out="$1"
# rem commas and brackets
idces="$(echo "$2" | sed 's|,| |g')"
idces=$(echo $idces | cut -d ] -f 1)
idces=$(echo $idces | cut -d [ -f 2)
# more than one index ?
if [ $(echo $idces | wc -w) -gt 1 -o "$idces" = "all" -o $(echo $idces | grep : | wc -l) -gt 0 ] ; then
  op="$3" ; shift
  if [ x"$op" = "xnone" ] ; then op=" " ; fi
  multi=1
else
  multi=0
fi
inputs="$3"
logdir="$4"

[ "$3" = "" ] && Usage

# create working dir.
# Don't use mktemp because script is self-submitting.
#wdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files
wdir=./$(basename $out).$$
mkdir -p $wdir
touch $wdir/jid.list

# define exit trap
trap "set +e ; echo -e \"\n`basename $0`: erasing Job-IDs in '$wdir/jid.list'\" ; delJIDs $wdir/jid.list ; rm -f $wdir/* ; rmdir $wdir ; exit" EXIT

# define logdir
if [ x"$logdir" = "x" ] ; then logdir="$wdir" ; else logdir="$4" ; fi

# check SGE
if [ "x$SGE_ROOT" != "x" ] ; then
  echo "`basename $0`: checking SGE..."
  qstat &>/dev/null
fi

# delete infofile
rm -f ${out}.txt

# extracting...
n=0 ; i=1
for input in $inputs ; do
  if [ $(imtest $input) -eq 0 ] ; then echo "`basename $0`: WARNING: cannot read '$input' - continuing..." | tee -a ${out}.txt ; continue ; fi
  nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'` ; mid=$(echo "scale=0 ; $nvol / 2" | bc)
  if [ "$idces" = "all" ] ; then
      echo "`basename $0`: $i - applying unary fslmaths operator '$op' to '$input'..." | tee -a ${out}.txt
      fsl_sub -l $logdir fslmaths $input $op $wdir/_tmp_$(zeropad $n 4) >> $wdir/jid.list # apply operator
  elif [ "$idces" = "mid" ] ; then
      echo "`basename $0`: $i - extracting volume at pos. $mid from '$input'..."  | tee -a ${out}.txt
      fsl_sub -l $logdir fslroi $input $wdir/_tmp_$(zeropad $n 4) $mid 1 >> $wdir/jid.list
  else
    for idx in $idces ; do
      idx=$(echo $idx | sed "s|mid|$mid|g") ; idx=$(echo $idx | sed "s|end|$[$nvol-1]|g")
      if [ $(echo $idx | grep : | wc -l) -gt 0 ] ; then
        field1=$(echo $idx | cut -d : -f 1); field1=$[$field1]
        field2=$(echo $idx | cut -d : -f 2); field2=$[$field2]
        field3=$(echo $idx | cut -d : -f 3); field3=$[$field3]
        for idx in `seq $field1 $field2 $field3` ; do
          echo "`basename $0`: $i - extracting volume at pos. $idx from '$input'..."  | tee -a ${out}.txt
          fsl_sub -l $logdir fslroi $input $wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4) $idx 1 >> $wdir/jid.list
        done
      else      
        idx=$[$idx]
        echo "`basename $0`: $i - extracting volume at pos. $idx from '$input'..."  | tee -a ${out}.txt
        if [ $multi -eq 1 ] ; then
          fsl_sub -l $logdir fslroi $input $wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4) $idx 1 >> $wdir/jid.list
        elif [ $multi -eq 0 ] ; then
          fsl_sub -l $logdir fslroi $input $wdir/_tmp_$(zeropad $n 4) $idx 1 >> $wdir/jid.list
        fi
      fi
    done    
  fi
  n=$(echo "$n + 1" | bc)
  i=$[$i+1]
done

# waiting...
waitIfBusyIDs $wdir/jid.list

# apply fslmaths operator if more than one index...
if [ $multi -eq 1 ] ; then
  n=0 ; rm -f $wdir/apply_operator.cmd
  echo "`basename $0`: merging (and applying unary fslmaths operator: '$op')..."  | tee -a ${out}.txt
  for input in $inputs ; do
    if [ $(imtest $input) -eq 0 ] ; then continue ; fi
    files=""    
    for idx in $idces ; do        
      idx=$(echo $idx | sed "s|mid|$mid|g") ; idx=$(echo $idx | sed "s|end|$[$nvol-1]|g")
      if [ $(echo $idx | grep : | wc -l) -gt 0 ] ; then
        field1=$(echo $idx | cut -d : -f 1); field1=$[$field1]
        field2=$(echo $idx | cut -d : -f 2); field2=$[$field2]
        field3=$(echo $idx | cut -d : -f 3); field3=$[$field3]
        for idx in `seq $field1 $field2 $field3` ; do
          files=$files" "$wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4)
        done
      else      
        idx=$[$idx]
        files=$files" "$wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4)
      fi
    done
    echo "fslmerge -t $wdir/_tmp_$(zeropad $n 4) $files ; \
    imrm $files ; \
    fslmaths $wdir/_tmp_$(zeropad $n 4) $op $wdir/_tmp_$(zeropad $n 4)" >> $wdir/apply_operator.cmd
    n=$(echo "$n + 1" | bc)
  done
  echo -n "    " ; cat $wdir/apply_operator.cmd
  fsl_sub -l $logdir -t $wdir/apply_operator.cmd >> $wdir/jid.list
  # waiting...
  waitIfBusyIDs $wdir/jid.list
fi # end if

# merging...
echo "`basename $0`: merging to '${out}'..."  | tee -a ${out}.txt
cmd="fslmerge -t ${out} $(imglob $wdir/_tmp_????.*)"
echo "    $cmd" | tee -a ${out}.txt
fsl_sub -l $logdir "$cmd" >> $wdir/jid.list

# waiting...
waitIfBusyIDs $wdir/jid.list

# list error log entries
echo "`basename $0`: cat SGE *.e logs:"
cat $logdir/*.e*

# done
echo "`basename $0`: done." 
