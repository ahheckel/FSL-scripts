#!/bin/sh

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR # added by HKL

set -e # added by HKL

Usage() {
    echo ""
    echo "Usage: eddy_correct [-t] <4dinput> <4doutput> <reference_no> <dof> <cost{mutualinfo(=default),corratio,normcorr,normmi,leastsq,labeldiff}> <interp{spline,trilinear(=default),nearestneighbour,sinc}>"
    echo ""
    exit 1
}

noec=0
if [ "$1" = "-t" ] ; then noec=1 ; echo "`basename $0` : test-mode." ; shift ; fi

[ "$3" = "" ] && Usage

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

if [ `${FSLDIR}/bin/imtest $input` -eq 0 ];then
echo "Input does not exist or is not in a supported format"
    exit 1
fi

echo "dof: $dof"
echo "cost: $cost"
echo "interp: $interp"

fslroi $input ${output}_ref $ref 1

fslsplit $input ${output}_tmp
full_list=`${FSLDIR}/bin/imglob ${output}_tmp????.*`

rm -f ${output}.ecclog # added by HKL to avoid accumulation on re-run

for i in $full_list ; do
echo processing $i
    echo processing $i >> ${output}.ecclog
    if [ $noec != 1 ] ; then      
      if [ "$interp" = "spline" ] ; then
        ${FSLDIR}/bin/flirt -in $i -ref ${output}_ref -nosearch -paddingsize 1 -dof $dof -cost $cost > ${output}.ecclog.tmp # added by HKL
        cat ${output}.ecclog.tmp | sed -n '3,6'p > ${output}.ecclog.tmp.applywarp # added by HKL
        ${FSLDIR}/bin/applywarp --ref=${output}_ref --in=$i --out=$i --premat=${output}.ecclog.tmp.applywarp --interp=spline # added by HKL
        #${FSLDIR}/bin/fslmaths $i -abs $i # added by HKL
        ${FSLDIR}/bin/fslmaths $i -thr 0 $i # added by HKL
        rm ${output}.ecclog.tmp.applywarp # added by HKL
      else
        ${FSLDIR}/bin/flirt -in $i -ref ${output}_ref -out $i -nosearch -paddingsize 1 -dof $dof -cost $cost -interp $interp > ${output}.ecclog.tmp # added by HKL
      fi
    else
      echo "" >> ${output}.ecclog.tmp
      echo "Final result:" >> ${output}.ecclog.tmp
      cat $FSL_DIR/etc/flirtsch/ident.mat >> ${output}.ecclog.tmp
      echo "" >> ${output}.ecclog.tmp 
    fi
cat ${output}.ecclog.tmp >> ${output}.ecclog ; rm ${output}.ecclog.tmp # added by HKL
done

fslmerge -t $output $full_list

/bin/rm ${output}_tmp????.* ${output}_ref*

