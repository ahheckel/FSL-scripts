#!/bin/bash
# converts between affine matrix formats

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <mov> <targ> <inmat: .reg|.lta|.txt|.mat|.xfm> <outmat: .reg|.lta||.mat|.xfm>"
    echo "Note: vox2vox ascii (.txt): targ->mov, not mov->targ"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage

mov="$1"
targ="$2"
inmat="$3"
outmat="$4"

out_ext=${outmat##*.}
in_ext=${inmat##*.}


if [ "$in_ext" = "dat" ] ; then regin="--reg $inmat" ; fi
if [ "$in_ext" = "xfm" ] ; then regin="--xfm $inmat" ; fi
if [ "$in_ext" = "mat" ] ; then regin="--fsl $inmat" ; fi
if [ "$in_ext" = "lta" ] ; then regin="--lta $inmat" ; fi
if [ "$in_ext" = "txt" ] ; then regin="--vox2vox $inmat" ; fi


if [ "$out_ext" = "dat" ] ; then regout="--reg $outmat" ; fi
if [ "$out_ext" = "xfm" ] ; then regout="--xfmout $outmat" ; fi
if [ "$out_ext" = "mat" ] ; then regout="--fslregout $outmat" ; fi
if [ "$out_ext" = "lta" ] ; then regout="--ltaout $outmat" ; fi

if [ "$in_ext" != "dat" -a  "$out_ext" != "dat" ] ; then delme="--reg $$deleteme.reg.dat" ; else delme="" ; fi

cmd="tkregister2 --noedit --mov $mov --targ $targ $regin $regout $delme"
echo $cmd ; $cmd


rm -f $$deleteme.reg.dat


echo "`basename $0` : subj $subj , sess $sess : done."


             
