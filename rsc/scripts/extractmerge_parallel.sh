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
    echo "Usage: `basename $0` <out4D> <indices> [<fslmaths unary operator] <\"input files\"> <qsub logdir>"
    echo "Example: `basename $0` means.nii.gz 1,2,3 -Tmean \"\$inputs\" /tmp"
    echo "         `basename $0` bolds.nii.gz \"1 2 3\" \"\" \"\$inputs\" /tmp"
    echo "         `basename $0` bolds.nii.gz 1 \"\$inputs\" /tmp"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage    

# define vars
out="$1"
idces="$(echo "$2" | sed 's|,| |g')"
if [ $(echo $idces | wc -w) -gt 1 ] ; then op="$3" ; shift ; fi
inputs="$3"
if [ x"$logdir" = "x" ] ; then logdir="$wdir" ; else logdir="$4" ; fi

# check SGE
qstat &>/dev/null

# extracting...
n=0 ; i=1
for input in $inputs ; do
  if [ ! -f $input ] ; then echo "`basename $0`: '$input' not found." ; continue ; fi
  for idx in $idces ; do
    echo "`basename $0`: $i - extracting volume at pos. $idx from '$input'..."
    if [ $(echo $idces | wc -w) -gt 1 ] ; then
      fsl_sub -l $logdir fslroi $input $wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4) $idx 1 >> $wdir/jid.list
    else
      fsl_sub -l $logdir fslroi $input $wdir/_tmp_$(zeropad $n 4) $idx 1 >> $wdir/jid.list
    fi
  done
  n=$(echo "$n + 1" | bc)
  i=$[$i+1]
done

# waiting...
waitIfBusyIDs $wdir/jid.list

# if more than one index...
if [ $(echo $idces | wc -w) -gt 1 ] ; then
  n=0 ; rm -f $wdir/apply_operator.cmd
  echo "`basename $0`: merging (and applying unary fslmaths operator: '$op')..."
  for input in $inputs ; do
    if [ ! -f $input ] ; then continue ; fi
    files=""
    for idx in $idces ; do files=$files" "$wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4) ; done
    echo "fslmerge -t $wdir/_tmp_$(zeropad $n 4) $files ; \
    imrm $files ; \
    fslmaths $wdir/_tmp_$(zeropad $n 4) $op $wdir/_tmp_$(zeropad $n 4)" >> $wdir/apply_operator.cmd
    n=$(echo "$n + 1" | bc)
  done
  cat $wdir/apply_operator.cmd
  fsl_sub -l $logdir -t $wdir/apply_operator.cmd >> $wdir/jid.list
  # waiting...
  waitIfBusyIDs $wdir/jid.list
fi # end if

# merging...
echo "`basename $0`: merging to '${out}'..."
fsl_sub -l $logdir fslmerge -t ${out} $(imglob $wdir/_tmp_????) >> $wdir/jid.list

# waiting...
waitIfBusyIDs $wdir/jid.list

echo "`basename $0`: done."
