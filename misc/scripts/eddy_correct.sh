#!/bin/bash

input=`${FSLDIR}/bin/remove_ext ${1}`
output=`${FSLDIR}/bin/remove_ext ${2}`
ref=${3}
opts=${4}
full_list=""
i=""

if [ "$3" = "" ] ; then echo "_eddy_correct(): Usage: _eddy_correct <4dinput> <4doutput> <reference_no> <options>" ; echo "Exiting..." ; exit 1 ; fi
if [ "$4" = "" ] ; then opts="-interp trilinear" ; fi

if [ `${FSLDIR}/bin/imtest $input` -eq 0 ];then
    echo "_eddy_correct(): ERROR: Input does not exist or is not in a supported format. Exiting..."
    exit 1
fi

fslroi $input ${output}_ref $ref 1

fslsplit $input ${output}_tmp
full_list=`${FSLDIR}/bin/imglob ${output}_tmp????.*`

if [ -e ${output}.ecclog ] ; then echo "_eddy_correct(): WARNING: log-file already exists - deleting it..." ; rm ${output}.ecclog ; fi
for i in $full_list ; do
    echo processing $i
    echo processing $i >> ${output}.ecclog
    ${FSLDIR}/bin/flirt -in $i -ref ${output}_ref -nosearch -o $i -paddingsize 1 $opts >> ${output}.ecclog
done

fslmerge -t $output $full_list

/bin/rm ${output}_tmp????.* ${output}_ref*  

