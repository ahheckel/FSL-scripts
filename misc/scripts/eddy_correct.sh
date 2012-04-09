#!/bin/sh

Usage() {
    echo ""
    echo "Usage: eddy_correct <4dinput> <4doutput> <reference_no> <cost> <interp>"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

input=`${FSLDIR}/bin/remove_ext ${1}`
output=`${FSLDIR}/bin/remove_ext ${2}`
ref=${3}
cost=${4}
interp=${5}
full_list=""

if [ "$4" = "" ] ; then cost="corratio" ; fi
if [ "$5" = "" ] ; then interp="trilinear" ; fi

if [ `${FSLDIR}/bin/imtest $input` -eq 0 ];then
    echo "Input does not exist or is not in a supported format"
    exit 1
fi

echo "cost:   $cost"
echo "interp: $interp"

fslroi $input ${output}_ref $ref 1

fslsplit $input ${output}_tmp
full_list=`${FSLDIR}/bin/imglob ${output}_tmp????.*`

for i in $full_list ; do
    echo processing $i
    echo processing $i >> ${output}.ecclog
    if [ "$interp" = "spline" ] ; then
      ${FSLDIR}/bin/flirt -in $i -ref ${output}_ref -nosearch -paddingsize 1 -cost $cost > ${output}.ecclog.tmp # mutualinfo added by HKL
      ${FSLDIR}/bin/applywarp --ref=${output}_ref --in=$i --out=$i --premat=${output}.ecclog.tmp  --interp=spline # added by HKL
    else
      ${FSLDIR}/bin/flirt -in $i -ref ${output}_ref -out $i -nosearch -paddingsize 1 -cost $cost -interp $interp > ${output}.ecclog.tmp # mutualinfo added by HKL
    fi
    cat ${output}.ecclog.tmp  >> ${output}.ecclog ; rm ${output}.ecclog.tmp # added by HKL
done

fslmerge -t $output $full_list

/bin/rm ${output}_tmp????.* ${output}_ref*

