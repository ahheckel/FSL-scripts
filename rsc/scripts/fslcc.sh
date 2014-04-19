#!/bin/bash
# Reformats fslcc output to display a matrix.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 19/04/2014

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <melodic_IC> <IC-template> <template-labels.txt> <output-dir> [fslcc-options]"
    echo ""
    exit 1
}


[ "$4" = "" ] && Usage

# define inputs
input=$(remove_ext "$1")
template=$(remove_ext "$2")
labels="$3"
outdir="$4"
shift 4
opts="$@"
wd=`pwd`

# OCTAVE installed ?
if [ x$(which octave) = "x" ] ; then echo "`basename $0` : ERROR : OCTAVE does not seem to be installed on your system ! Exiting..." ; exit 1 ; fi

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# create binary mask
echo "`basename $0`:"
cmd="fslmaths $input -abs -thr 0 -bin -Tmax $tmpdir/mask"
echo "    $cmd" ; $cmd

# execute fslcc
fslcc_out=$tmpdir/fslcc.txt
cmd="fslcc $opts -m $tmpdir/mask $input $template"
echo "    $cmd" ; $cmd | tee $fslcc_out

# substitute Matlab routine
cp $(dirname $0)/templates/template_fslcc.m $tmpdir/fslcc.m
cp $labels $tmpdir/
imcp $input $tmpdir/
imcp $template $tmpdir/
out=fslcc__$(basename $input)__$(basename $template).txt
sed -i "s|c=load('/tmp/fslcc_out'.*|c=load('$fslcc_out');|g" $tmpdir/fslcc.m
sed -i "s|fid1=fopen('/tmp/rsn_labels'.*|fid1=fopen('$tmpdir/$(basename $labels)');|g" $tmpdir/fslcc.m
sed -i "s|fid2=fopen('loop.txt'.*)|fid2=fopen('$out', 'wt');|g" $tmpdir/fslcc.m
sed -i "s|cols=.*|cols=$(fslnvols $(basename $input));|g" $tmpdir/fslcc.m
sed -i "s|rows=.*|rows=$(fslnvols $(basename $template));|g" $tmpdir/fslcc.m

# execute Octave/Malab
cd $tmpdir
octave -q --eval fslcc

# copy result
cd $wd
cp $tmpdir/$out $outdir/$out
cat $outdir/$out

# done
echo "`basename $0`: done."

