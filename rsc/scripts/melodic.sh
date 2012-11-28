#!/bin/bash
# Wrapper for FSL's Melodic.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <\"input-file(s)\"|inputfiles.txt> <TR(sec)> <output-dir> [melodic options]"
    echo "Example: `basename $0` inputfiles.txt 3.30 melodic_ICA \"--nobet -d 25\""
    echo "         `basename $0` singlefile.nii.gz 3.30 -1"
    echo "          -1: saves result in directory of input file."
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage
inputs="$1"
TR=$2
outdir="$3"
_opts="$4"

# single session ICA ?
gica=1
if [ $(echo "$inputs" | wc -w) -eq 1 ] ; then
  if [ -f $inputs ] ; then # single session ICA
    gica=0
    if [ "$outdir" = "-1" ] ; then outdir="$(dirname $inputs)" ; fi
    subdir=$(remove_ext $(basename $inputs)).ica    
  else # assume group ICA
    inputs="$(cat $inputs)"
    subdir=groupmelodic.ica
  fi
else # assume group ICA
  subdir=groupmelodic.ica
fi
if [ "$outdir" = "-1" ] ; then echo "`basename $0`: ERROR : you must specify an output directory for group-ICA... exiting." ; exit 1 ; fi

# check inputs
err=0
for file in $inputs ; do
  if [ ! -f $file ] ; then echo "`basename $0`: ERROR: '$file' does not exist !" ; err=1 ; fi
done
if [ $err -eq 1 ] ; then "`basename $0`: An ERROR has occured. Exiting..." ; exit 1 ; fi

# delete outdir if present
if [ -f $outdir/$subdir/report/00index.html ] ; then echo "" ; echo "`basename $0`: WARNING : output directory '$outdir/$subdir' already exists - deleting it..." ; echo "" ; rm -r $outdir/$subdir ; fi

# create command options
opts="-v --tr=${TR} --report --guireport=$outdir/$subdir/report.html -d 0 --mmthresh=0.5 --Oall $_opts"
if [ $gica -eq 1 ] ; then opts="$opts -a concat" ; fi

# create output directory
mkdir -p $outdir/$subdir

# gather inputs
err=0 ; rm -f $outdir/melodic.inputfiles ; i=1
for file in $inputs ; do
  if [ -f $file ] ; then echo "`basename $0`: $i adding '$file' to input filelist..." ; echo $file >> $outdir/melodic.inputfiles ; i=$[$i+1] ; else echo "`basename $0`: ERROR: '$file' does not exist !" ; err=1 ; fi
done
if [ $err -eq 1 ] ; then "`basename $0`: An ERROR has occured. Exiting..." ; exit 1 ; fi

# execute melodic
cmd="melodic -i $outdir/melodic.inputfiles -o $outdir/$subdir $opts"
echo $cmd | tee $outdir/melodic.cmd
. $outdir/melodic.cmd

# link to report webpage
ln -sfv ./report/00index.html $outdir/$subdir/report.html

# done
echo "`basename $0`: done."
