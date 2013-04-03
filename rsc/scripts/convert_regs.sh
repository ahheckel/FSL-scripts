#!/bin/bash
# Converts between affine matrix formats.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

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

if [ "$in_ext" = "$out_ext" ] ; then echo "`basename $0` : ERROR : file extension of input and output matrices are the same (*.$out_ext)" ; exit 1 ; fi

cp $inmat /tmp/$(basename $0)_$$.${in_ext}
_inmat=/tmp/$(basename $0)_$$.${in_ext}

if [ "$in_ext" = "dat" ] ; then regin="--reg $_inmat" ; fi
if [ "$in_ext" = "xfm" ] ; then regin="--xfm $_inmat" ; fi
if [ "$in_ext" = "mat" ] ; then regin="--fsl $_inmat" ; fi
if [ "$in_ext" = "lta" ] ; then regin="--lta $_inmat" ; fi
if [ "$in_ext" = "txt" ] ; then regin="--vox2vox $_inmat" ; fi

if [ "$out_ext" = "dat" ] ; then regout="--reg $outmat" ; fi
if [ "$out_ext" = "xfm" ] ; then regout="--xfmout $outmat" ; fi
if [ "$out_ext" = "mat" ] ; then regout="--fslregout $outmat" ; fi
if [ "$out_ext" = "lta" ] ; then regout="--ltaout $outmat" ; fi

if [ "$in_ext" != "dat" -a  "$out_ext" != "dat" ] ; then delme="--reg $$deleteme.reg.dat" ; else delme="" ; fi

cmd="tkregister2 --noedit --mov $mov --targ $targ $regin $regout $delme"
echo $cmd ; $cmd

rm -f $$deleteme.reg.dat
rm -f $_inmat

echo "`basename $0` : done."
