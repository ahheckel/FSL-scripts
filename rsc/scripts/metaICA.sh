#!/bin/bash
# Meta-ICA ("Toward a neurometric foundation of pICA of fMRI data" Poppe et al. Cogn. Affect. Behav. Neurosci. (2013))
# This script is self-submiting and should never be submitted to a cluster.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 12/02/2014

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <\"input-file(s)\"|inputfiles.txt> <TR(sec)> <output-dir> <N_subjectorders> [melodic-options_subj-level] [melodic-options_meta-level]"
    echo "Examples: `basename $0` \"file01.nii.gz file02.nii.gz ...\" 3.330 ./mICA.gica 50 \"-d 20\" \"--nobet -d 20 --bgimage=\$FSLDIR/data/standard/MNI152_T1_2mm\""
    echo "          `basename $0` inputfiles.txt 3.330 ./mICA.gica 25 \"-d 20\" \"--nobet -d 20 --bgimage=\$FSLDIR/data/standard/MNI152_T1_2mm\""
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

function _imtest()
{
  local vol="$1"
 
  if [ -f ${vol} -o -f ${vol}.nii -o -f ${vol}.nii.gz -o -f ${vol}.hdr -o -f ${vol}.img ] ; then
    if [ $(fslinfo $vol 2>/dev/null | wc -l) -gt 0 ] ; then
      echo "1"
    else
      echo "0"
    fi
  else
    echo "0" 
  fi  
}

function testascii()
{
  local file="$1"
  if LC_ALL=C grep -q '[^[:print:][:space:]]' $file; then
      echo "0"
  else
      echo "1"
  fi
}

function exec_melodic()
{
  local input2melodic="$1"
  local outdir="$2"
  local subdir="$3"
  local opts="$4"
  local sge="$5" ; if [ x"$sge" = "x" ] ; then sge=0 ; fi
  
  # convert to absolute paths
  if [ $(echo $input2melodic | grep ^/ | wc -l) -eq 0 ] ; then input2melodic=$(pwd)/$input2melodic ; fi
  if [ $(echo $outdir | grep ^/ | wc -l) -eq 0 ] ; then outdir=$(pwd)/$outdir ; fi
  
  # check
  if [ ! -f $input2melodic ] ; then 
    if [ $(_imtest $input2melodic) -eq 0 ] ; then echo "`basename $0`: ERROR: '$input2melodic' does not exist !" ; exit 1 ; fi
  fi

  # add guireport to opts
  opts="$opts --guireport=$outdir/$subdir/report.html"

  # delete outdir if present
  if [ -f $outdir/$subdir/report/00index.html ] ; then echo "" ; echo "`basename $0`: WARNING : output directory '$outdir/$subdir' already exists - deleting it in 5 seconds..." ; echo "" ; sleep 5 ; rm -r $outdir/$subdir ; fi
  
  # create output directory
  mkdir -p $outdir/$subdir

  # execute melodic
  echo ""
  cmd="melodic -i $input2melodic -o $outdir/$subdir $opts"
  echo $cmd | tee $outdir/$subdir/melodic.cmd
  if [ $sge -eq 1 -a x"$SGE_ROOT" != "x" ] ; then
    fsl_sub -l $outdir/$subdir/ -t $outdir/$subdir/melodic.cmd >> ./jid.list
  else
    . $outdir/$subdir/melodic.cmd
  fi

  # link to report webpage
  if [ -f $outdir/$subdir/report/00index.html ] ; then  
    ln -sfv ./report/00index.html $outdir/$subdir/report.html  
  fi
}

[ "$6" = "" ] && Usage
inputs="$1"
TR=$2
outdir="$3"
Nsubjorders="$4"
_opts0="$5"
_opts1="$6"

# create job ID file
touch ./jid.list

# define exit trap
trap "set +e ; delJIDs ./jid.list ; exit" EXIT

# check for multiple inputs
if [ $(echo "$inputs" | wc -w) -eq 1 ] ; then
  if [ $(_imtest $inputs) -eq 1 ] ; then # single session ICA
    gica=0
    echo "`basename $0`: ERROR : only one file as input - exiting." ; exit 1 
  elif [ $(testascii $inputs) -eq 1 ] ; then # assume group ICA
    if [ $(cat $inputs | grep "[[:alnum:]]" | wc -l) -eq 1 ] ; then
      gica=0
      echo "`basename $0`: ERROR : only one file as input - exiting." ; exit 1
    elif [ $(cat $inputs | grep "[[:alnum:]]" | wc -l) -gt 1 ] ; then
      gica=1
    else
      echo "`basename $0`: ERROR : '$input' is empty - exiting." ; exit 1
    fi      
    inputs="$(cat $inputs)" # asuming ascii list with volumes
  else
    echo "`basename $0`: ERROR : cannot read inputfile '$inputs' - exiting." ; exit 1 
  fi
else # assume group ICA
  gica=1
fi

# check whether input files exist
err=0
for file in $inputs ; do
  if [ $(_imtest $file) -eq 0 ] ; then echo "`basename $0`: ERROR: '$file' does not exist !" ; err=1 ; fi
done
if [ $err -eq 1 ] ; then echo "`basename $0`: An ERROR has occured. Exiting..." ; exit 1 ; fi

# create command options
optsSUBJ="-v --tr=${TR} --report --mmthresh=0.5 -a concat $_opts0"
optsMETA="-v --tr=${TR} --report --mmthresh=0.5 -a concat --vn $_opts1 --Oall"

# create output directory
mkdir -p $outdir

# create first "permutation"
input2melodic="$outdir/melodic.inputfiles"
subdir=groupmelodic$(zeropad 0 4).ica
# display info
echo "-----------------------------------------"
echo "`basename $0`: outdir:    $outdir/${subdir}"
echo "`basename $0`: inputfile: ${input2melodic}$(zeropad 0 4)"
echo "-----------------------------------------"
# gather inputs and create inputfile
err=0 ; rm -f ${input2melodic}$(zeropad 0 4) ; i=1
for file in $inputs ; do
  if [ $(_imtest $file) -eq 1 ] ; then echo "`basename $0`: $i adding '$file' to input filelist..." ; echo $file >> ${input2melodic}$(zeropad 0 4) ; i=$[$i+1] ; else echo "`basename $0`: ERROR: '$file' does not exist !" ; err=1 ; fi
done
if [ $err -eq 1 ] ; then echo "`basename $0`: An ERROR has occured. Exiting..." ; exit 1 ; fi
# execute
exec_melodic ${input2melodic}$(zeropad 0 4) $outdir ${subdir} "$optsSUBJ" 1

# create remaining permutations
for i in `seq 1 $[$Nsubjorders - 1]` ; do
  subdir=groupmelodic$(zeropad $i 4).ica
  # display info
  echo "`basename $0`: outdir: $outdir/${subdir}"
  echo "`basename $0`: inputfile: ${input2melodic}$(zeropad $i 4)"
  sort -R  ${input2melodic}$(zeropad 0 4) > ${input2melodic}$(zeropad $i 4)
  exec_melodic ${input2melodic}$(zeropad $i 4) $outdir $subdir "$optsSUBJ" 1
done

# wait till finished
waitIfBusyIDs ./jid.list

# metaICA
input2melodic="$outdir/melodic.inputfilesMETA"
subdir=groupmelodicMETA.ica
# display info
echo "-----------------------------------------"
echo "`basename $0`: outdir:    $outdir/$subdir"
echo "`basename $0`: inputfile: ${input2melodic}"
echo "-----------------------------------------"
# gather inputs
melodicICs="" ; err=0 ; rm -f ${input2melodic}
for i in `seq 0 $[$Nsubjorders - 1]` ; do
  melodicICs=$melodicICs" "$outdir/groupmelodic$(zeropad $i 4).ica/melodic_IC.nii.gz
done
i=1 ; for file in $melodicICs ; do
  if [ $(_imtest $file) -eq 1 ] ; then echo "`basename $0`: $i adding '$file' to input filelist..." ; echo $file >> ${input2melodic} ; i=$[$i+1] ; else echo "`basename $0`: ERROR: '$file' does not exist !" ; err=1 ; fi
done
if [ $err -eq 1 ] ; then echo "`basename $0`: An ERROR has occured. Exiting..." ; exit 1 ; fi
# merge
fslmerge -t $outdir/melodic_ICMETA $(cat ${input2melodic})
# execute
exec_melodic $outdir/melodic_ICMETA $outdir $subdir "$optsMETA"
# create symlink for compatibility
ln -sfv $outdir/$subdir $outdir/groupmelodic.ica

# wait till finished
waitIfBusyIDs ./jid.list

# done
echo "`basename $0`: done."
