#!/bin/bash

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

wdir=`pwd`/.extmerge$$
mkdir -p $wdir
trap "echo -e \"\ncleanup: erasing '$wdir'\" ; rm -f $wdir/* ; rmdir $wdir ; exit" EXIT
 
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
  rm $IDfile
}

    
Usage() {
    echo ""
    echo "Usage: `basename $0` <out4D> <indices> <\"input files\"> <qsub logdir>"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage    
  
out="$1"
idces="$2"
inputs="$3"
logdir="$4"

n=0 ; i=1
for input in $inputs ; do
  if [ ! -f $input ] ; then echo "`basename $0`: '$input' not found." ; continue ; fi
  for idx in $idces ; do
    echo "`basename $0`: $i - extracting volume at pos. $idx from '$input'..."
    fsl_sub -l $logdir fslroi $input $wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4) $idx 1 >> $wdir/jid.list
  done
  n=$(echo "$n + 1" | bc)
  i=$[$i+1]
done

waitIfBusyIDs $wdir/jid.list

echo "`basename $0`: merging (and applying unary fslmaths operator)..."
n=0 ; i=1
for input in $inputs ; do
  if [ ! -f $input ] ; then continue ; fi
  files="" ; cmd=""
  for idx in $idces ; do
    files=$wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4)" "$wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4)
  done
  cmd="fslmerge -t $wdir/_tmp_$(zeropad $n 4) $files ; imrm $files ; fslmaths -Tmean $wdir/_tmp_$(zeropad $n 4) $wdir/_tmp_$(zeropad $n 4)"
  fsl_sub -l $logdir $cmd >> $wdir/jid.list
  n=$(echo "$n + 1" | bc)
  i=$[$i+1]
done

waitIfBusyIDs $wdir/jid.list

echo "`basename $0`: merging..."
fsl_sub -l $logdir fslmerge -t ${out} $(imglob $wdir/_tmp_????) >> $wdir/jid.list

waitIfBusyIDs $wdir/jid.list

echo "`basename $0`: done."
