#!/bin/bash
# Modification of FSL's eddy_correct (v.4.1.9). This script is self-submitting to SGE cluster to speed things up.

# Adapted by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 06/15/2013

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage:   $(basename $0) [-t|-n] <4dinput> <4doutput> <reference_no|reference_vol> <dof> <cost{mutualinfo(=default),corratio,normcorr,normmi,leastsq,labeldiff}> <interp{spline,trilinear(=default),nearestneighbour,sinc}> [<flirt-opts>]"
    echo "Options  (mutually exclusive):    -t :  test mode: just copy input->output and create .ecclog file with identities."
    echo "                                  -n :  no write-outs, just create .ecclog file."
    echo ""
    echo "Example: $(basename $0) input.nii.gz ec_input 0 12 corratio spline \"-2D\""
    echo "         $(basename $0) input.nii.gz ec_input b0 12 corratio spline \"-2D\""
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

noec=0 ; nowrite=0
if [ "$1" = "-t" ] ; then 
  noec=1 ; echo "`basename $0`: test-mode." ; shift
elif [ "$1" = "-n" ] ; then 
  nowrite=1 ; echo "`basename $0`: no write-outs." ; shift
fi

[ "$3" = "" ] && Usage

# define input arguments
input=`${FSLDIR}/bin/remove_ext ${1}`
output=`${FSLDIR}/bin/remove_ext ${2}`
ref=${3}
dof=${4}
cost=${5}
interp=${6}
opts="$7"
full_list=""
if [ "$4" = "" ] ; then dof=12 ; fi
if [ "$5" = "" ] ; then cost="mutualinfo" ; fi
if [ "$6" = "" ] ; then interp="trilinear" ; fi

# check input
if [ `${FSLDIR}/bin/imtest $input` -eq 0 ];then
  echo "Input does not exist or is not in a supported format"
  exit 1
fi

# create working dir.
# NOTE: Don't use mktemp, because this script is self-submitting.
#tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files
tmpdir=${output}.$$ ; mkdir -p $tmpdir

# create jid file
jidfile=$tmpdir/$(basename ${output}).sge.$$
touch $jidfile

# define exit trap
trap "delJIDs $jidfile ; rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# display info
fslversion=$(cat $FSLDIR/etc/fslversion | cut -d . -f 1)
echo "`basename $0`: FSL    : v.${fslversion}"
echo "`basename $0`: dof    : $dof"
echo "`basename $0`: cost   : $cost"
echo "`basename $0`: interp : $interp"
echo "`basename $0`: opts   : $opts"
echo "`basename $0`: output : $output"
echo "---------------------------"

# extract reference image
if [ $(imtest $ref) -eq 0 ] ; then
  fslroi $input ${output}_ref $ref 1
else
  echo "`basename $0`: NOTE: '$ref' is a volume, not an index."
  imcp $ref ${output}_ref
fi

# split
imrm $tmpdir/$(basename $output)_tmp????.*
fslsplit $input $tmpdir/$(basename $output)_tmp
full_list=`imglob $tmpdir/$(basename $output)_tmp????.*`

# execute
JID=1 # dummy job ID
rm -f ${output}.ecclog ${output}.cmd # to avoid accumulation on re-run
for i in $full_list ; do
  cmd=""
  if [ $noec != 1 ] ; then
    echo processing $i
    cmd="echo processing $i > ${i}.ecclog.tmp ;"
    if [ "$interp" = "spline" -a $fslversion -lt 5 ] ; then
      cmd="flirt $opts -in $i -ref ${output}_ref -nosearch -paddingsize 1 -dof $dof -cost $cost >> ${i}.ecclog.tmp ;"
      if [ $nowrite -eq 0 ] ; then          
        cmd="$cmd cat ${i}.ecclog.tmp | sed -n '3,6'p > ${i}.ecclog.tmp.applywarp ; applywarp --ref=${output}_ref --in=$i --out=$i --premat=${i}.ecclog.tmp.applywarp --interp=spline ; rm ${i}.ecclog.tmp.applywarp ;"
      fi        
    else      
      if [ $nowrite -eq 0 ] ; then
        cmd="$cmd flirt $opts -in $i -ref ${output}_ref -out $i -nosearch -paddingsize 1 -dof $dof -cost $cost -interp $interp >> ${i}.ecclog.tmp ;"
      else
        cmd="$cmd flirt $opts -in $i -ref ${output}_ref -nosearch -paddingsize 1 -dof $dof -cost $cost >> ${i}.ecclog.tmp ;"
      fi        
    fi
    ## remove neg. values          
    #if [ "$interp" = "spline" -o "$interp" = "sinc"] ; then
      #if [ $nowrite -eq 0 ] ; then cmd="$cmd fslmaths $i -thr 0 $i ;" ; fi
    #fi
    echo $cmd >> ${output}.cmd
  else
    echo processing $i >> ${output}.ecclog
    echo "" >> ${output}.ecclog.tmp
    echo "Final result:" >> ${output}.ecclog.tmp
    cat $FSLDIR/etc/flirtsch/ident.mat >> ${output}.ecclog.tmp
    echo "" >> ${output}.ecclog.tmp
    cat ${output}.ecclog.tmp >> ${output}.ecclog
    rm ${output}.ecclog.tmp
  fi
done

# execute cmd-list
if [ -f ${output}.cmd ] ; then
  cat ${output}.cmd
  fsl_sub -l $tmpdir -N $(basename $0) -j $JID -t ${output}.cmd > $jidfile
  waitIfBusyIDs $jidfile
  cat $tmpdir/$(basename $output)_tmp????.ecclog.tmp >> ${output}.ecclog
  rm $tmpdir/$(basename $output)_tmp????.ecclog.tmp
fi

# merge results
if [ $nowrite -eq 0 ] ; then
  fsl_sub -l $tmpdir -N $(basename $0) -j $JID fslmerge -t $output $full_list > $jidfile
fi

waitIfBusyIDs $jidfile

# cleanup
imrm $full_list ${output}_ref

# done
echo "`basename $0`: done."

