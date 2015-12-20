#!/bin/bash
# Collects and merges volumes from the directory tree.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

wdir=`pwd`/.collectvols$$ ; mkdir -p $wdir
trap "echo -e \"\ncleanup: erasing '$wdir'\" ; rm -f $wdir/* ; rmdir $wdir ; exit" EXIT

Usage() {
    echo ""
    echo "Usage: `basename $0` [ -m|-e [idx] ] <4doutput> <\"subdir/filename\"> <subjectsdir> <\"01 02 ...\"|-> <\"sessa sessb ...\">"
    echo ""
    exit 1
}

[ "$5" = "" ] && Usage
domean=0 ; doextr=0
if [ $1 = "-m" ] ; then 
  domean=1
  shift
elif [ $1 = "-e" ] ; then
  doextr=1
  idx=$2
  shift 2
fi
out=`remove_ext "$1"`
file="$2"
subjdir="$3"
if [ "$4" = "-" ] ; then
  subj=$(find $subjdir -mindepth 1 -maxdepth 1 -type d | grep -v FS_ | sort)
else
  subj="$4"
  _subj=""
  for i in $subj ; do
    _subj=$_subj" "$subjdir/$i
  done
  subj="$_subj"
fi
sess="$5"


c=1 ; for i in $subj ; do
  for j in $sess ; do 
    if [ -f $i/$j/$file ] ; then
      echo "$(zeropad $c 3) found: $i/$j/$file" 
      c=$[$c+1]
    else
      echo "    not found: $i/$j/$file"
    fi
  done
done ; c=0

set +e
read -p "Press key..."
set -e

mkdir -p $(dirname $out)
files=""
rm -f $wdir/*
rm -f ${out}.list
c=1 ; for i in $subj ; do
  for j in $sess ; do 
    if [ -f $i/$j/$file ] ; then
      if [ $doextr -eq 1 ] ; then
        echo "$(zeropad $c 3) found: $i/$j/$file - extracting at pos. $idx..." | tee -a ${out}.list
        _file=$(zeropad $c 3)_extracted_${idx}
        fslroi $i/$j/$file $wdir/$_file $idx 1
        files=$files" "$wdir/$_file
      elif [ $domean -eq 1 ] ; then
        echo "$(zeropad $c 3) found: $i/$j/$file - creating mean..." | tee -a ${out}.list
        _file=$(zeropad $c 3)_mean
        fslmaths $i/$j/$file -Tmean $wdir/$_file
        files=$files" "$wdir/$_file
      else
        echo "$(zeropad $c 3) found: $i/$j/$file" >> ${out}.list
        files=$files" "$i/$j/$file
      fi
      c=$[$c+1]
    else
      echo "    not found: $i/$j/$file" >> ${out}.list
    fi
  done
done ; c=0

echo "merging..."
cmd="fslmerge -t ${out} $files"
echo $cmd ; $cmd

#cmd="fslview ${out}"
#echo $cmd | tee ${out}.cmd ; chmod +x ${out}.cmd ; $cmd


echo "`basename $0`: done."
