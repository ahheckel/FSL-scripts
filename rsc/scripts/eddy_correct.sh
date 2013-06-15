#!/bin/bash
# Modification of FSL's eddy_correct (v.4.1.9). 

# Adapted by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 06/15/2013

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage: $(basename $0) [-t|-n] <4dinput> <4doutput> <reference_no> <dof> <cost{mutualinfo(=default),corratio,normcorr,normmi,leastsq,labeldiff}> <interp{spline,trilinear(=default),nearestneighbour,sinc}>"
    echo "Options (mutually exclusive):  -t :  test mode: just copy input->output and create .ecclog file with identities."
    echo "                               -n :  no write-outs, just create .ecclog file."
    exit 1
}

noec=0 ; nowrite=0
if [ "$1" = "-t" ] ; then 
  noec=1 ; echo "`basename $0` : test-mode." ; shift
elif [ "$1" = "-n" ] ; then 
  nowrite=1 ; echo "`basename $0` : no write-outs." ; shift
fi

[ "$3" = "" ] && Usage

# define input arguments
input=`${FSLDIR}/bin/remove_ext ${1}`
output=`${FSLDIR}/bin/remove_ext ${2}`
ref=${3}
dof=${4}
cost=${5}
interp=${6}
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
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files
#tmpdir=/tmp/$(basename $0)_$$
#mkdir -p $tmpdir

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# display info
fslversion=$(cat $FSLDIR/etc/fslversion | cut -d . -f 1)
echo "`basename $0`: FSL    : v.${fslversion}"
echo "`basename $0`: dof    : $dof"
echo "`basename $0`: cost   : $cost"
echo "`basename $0`: interp : $interp"

# extract reference image
fslroi $input ${output}_ref $ref 1

# split
imrm ${tmpdir}/$(basename $output)_tmp????.*
fslsplit $input ${tmpdir}/$(basename $output)_tmp
full_list=`imglob ${tmpdir}/$(basename $output)_tmp????.*`

# execute
rm -f ${output}.ecclog # to avoid accumulation on re-run
for i in $full_list ; do
  echo processing $i
  echo processing $i >> ${output}.ecclog
  if [ $noec != 1 ] ; then    
    if [ "$interp" = "spline" -a $fslversion -lt 5 ] ; then
      ${FSLDIR}/bin/flirt -in $i -ref ${output}_ref -nosearch -paddingsize 1 -dof $dof -cost $cost > ${output}.ecclog.tmp    
      if [ $nowrite -eq 0 ] ; then          
        cat ${output}.ecclog.tmp | sed -n '3,6'p > ${output}.ecclog.tmp.applywarp
        ${FSLDIR}/bin/applywarp --ref=${output}_ref --in=$i --out=$i --premat=${output}.ecclog.tmp.applywarp --interp=spline
        rm ${output}.ecclog.tmp.applywarp          
      fi        
    else      
      if [ $nowrite -eq 0 ] ; then
        ${FSLDIR}/bin/flirt -in $i -ref ${output}_ref -out $i -nosearch -paddingsize 1 -dof $dof -cost $cost -interp $interp > ${output}.ecclog.tmp
      else
        ${FSLDIR}/bin/flirt -in $i -ref ${output}_ref -nosearch -paddingsize 1 -dof $dof -cost $cost > ${output}.ecclog.tmp
      fi        
    fi    
    # remove neg. values          
    #if [ "$interp" = "spline" -a $nowrite -eq 0 ] ; then
      ##${FSLDIR}/bin/fslmaths $i -abs $i
      #${FSLDIR}/bin/fslmaths $i -thr 0 $i
    #fi  
  else
    echo "" >> ${output}.ecclog.tmp
    echo "Final result:" >> ${output}.ecclog.tmp
    cat $FSLDIR/etc/flirtsch/ident.mat >> ${output}.ecclog.tmp
    echo "" >> ${output}.ecclog.tmp 
  fi
  cat ${output}.ecclog.tmp >> ${output}.ecclog ; rm ${output}.ecclog.tmp
done

# merge results
if [ $nowrite -eq 0 ] ; then
  fslmerge -t $output $full_list
fi

# cleanup
imrm $full_list
imrm ${output}_ref

# done
echo "`basename $0`: done."

