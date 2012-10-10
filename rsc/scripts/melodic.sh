#!/bin/bash
# execute melodic

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <\"input-file(s)\"|inputfiles.txt> <TR(sec)> <output-dir> [<bet 0|1, def 1>]"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage
inputs="$1"
TR=$2
outdir="$3"
bet="$4"

if [ x"$bet" = "x" ] ; then bet=1 ; fi

# single session ICA ?
gica=1
if [ $(echo "$inputs" | wc -w) -eq 1 ] ; then
  if [ -f $inputs ] ; then
    gica=0
    subdir=$(remove_ext $(basename $inputs)).ica
  else
    inputs="$(cat $inputs)"
    subdir=groupmelodic.ica
  fi
else
  subdir=groupmelodic.ica
fi

# create command options
opts="-v --tr=${TR} --report --guireport=$outdir/$subdir/report.html -d 0 --mmthresh=0.5 --Oall"
if [ $bet -eq 0 ] ; then  opts="$opts --nobet --bgthreshold=10" ; fi
if [ $gica -eq 1 ] ; then opts="$opts -a concat" ; fi

# create output directory
mkdir -p $outdir/$subdir

# check inputs
err=0 ; rm -f $outdir/input.files ; i=1
for file in $inputs ; do
  if [ -f $file ] ; then echo "`basename $0`: $i adding '$file' to input filelist..." ; echo $file >> $outdir/input.files ; i=$[$i+1] ; else echo "`basename $0`: ERROR: '$file' does not exist !" ; err=1 ; fi
done
if [ $err -eq 1 ] ; then "`basename $0`: An ERROR has occured. Exiting..." ; exit 1 ; fi

# execute melodic
cmd="melodic -i $outdir/input.files -o $outdir/$subdir $opts"
echo $cmd | tee $outdir/melodic.cmd
. $outdir/melodic.cmd

# link to report webpage
ln -sfv ./report/00index.html $outdir/$subdir/report.html

# done
echo "`basename $0`: done."
