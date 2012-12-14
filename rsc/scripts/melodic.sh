#!/bin/bash
# Wrapper for FSL's Melodic.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/28/2012

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <\"input-file(s)\"|inputfiles.txt> <TR(sec)> <output-dir> [melodic options]"
    echo "Example: `basename $0` \"file01.nii.gz file02.nii.gz ...\" 3.330 -1"
    echo "         `basename $0` inputfiles.txt 3.330 ./melodic_ICA \"--nobet -d 25\""
    echo "         `basename $0` singlefile.nii.gz 3.330 -1"
    echo ""
    echo "          multiple inputs:          assuming 'concat' mode."
    echo "          textfile as input:        assuming 'concat' mode on files in textfile."
    echo "          single file as input:     assuming single session mode."
    echo "                                    -1: saves result in directory of input file."
    echo ""
    exit 1
}

#function _imtest()
#{
  #local vol="$1"
 
  #if [ -f ${vol} -o -f ${vol}.nii -o -f ${vol}.nii.gz -o -f ${vol}.hdr -o -f ${vol}.img ] ; then
    #if [ $(fslinfo $vol 2>/dev/null | wc -l) -gt 0 ] ; then
      #echo "1"
    #else
      #echo "0"
    #fi
  #else
    #echo "0" 
  #fi  
#}

function testascii()
{
  local file="$1"
  if LC_ALL=C grep -q '[^[:print:][:space:]]' $file; then
      echo "0"
  else
      echo "1"
  fi
}

[ "$3" = "" ] && Usage
inputs="$1"
TR=$2
outdir="$3"
_opts="$4"


# single session ICA ?
if [ $(echo "$inputs" | wc -w) -eq 1 ] ; then
  if [ $(imtest $inputs) -eq 1 ] ; then # single session ICA
    gica=0
    if [ "$outdir" = "-1" ] ; then outdir="$(dirname $inputs)" ; fi
    subdir=$(remove_ext $(basename $inputs)).ica    
  elif [ $(testascii $inputs) -eq 1 ] ; then # assume group ICA
    gica=1
    inputs="$(cat $inputs)" # assuming ascii list with volumes
    subdir=groupmelodic.ica
  else
    echo "`basename $0`: ERROR : cannot read inputfile '$inputs' - exiting." ; exit 1 
  fi
else # assume group ICA
  gica=1
  subdir=groupmelodic.ica
fi


# display info
if [ $gica -eq 1 ] ; then 
  echo "`basename $0`: applying 'concat' mode."
else 
  echo "`basename $0`: applying single session mode."
fi


# check
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


# gather inputs (four group melodic)
if [ $gica -eq 1 ] ; then
  err=0 ; rm -f $outdir/melodic.inputfiles ; i=1
  for file in $inputs ; do
    if [ -f $file ] ; then echo "`basename $0`: $i adding '$file' to input filelist..." ; echo $file >> $outdir/melodic.inputfiles ; i=$[$i+1] ; else echo "`basename $0`: ERROR: '$file' does not exist !" ; err=1 ; fi
  done
  if [ $err -eq 1 ] ; then "`basename $0`: An ERROR has occured. Exiting..." ; exit 1 ; fi
  input2melodic="$outdir/melodic.inputfiles"
else
  input2melodic="$inputs" # sinlge file for single session ICA
fi


# execute melodic
cmd="melodic -i $input2melodic -o $outdir/$subdir $opts"
echo $cmd | tee $outdir/melodic.cmd
. $outdir/melodic.cmd


# link to report webpage
ln -sfv ./report/00index.html $outdir/$subdir/report.html


# done
echo "`basename $0`: done."
