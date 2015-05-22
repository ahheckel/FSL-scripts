#!/bin/bash

# Written by Andreas Heckel
# University of Freiburg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 05/20/2015

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <output> <tval|0(0 for label files)> <annotation> <input1 input2...>"
    echo "Example: `basename $0` out.txt 1.5  /usr/local/freesurfer/subjects/fsaverage/label/lh.aparc.a2009s.annot sig.mgh"
    echo "         `basename $0` out.txt 0  /usr/local/freesurfer/subjects/fsaverage/label/lh.aparc.a2009s.annot *.label"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# define vars
out="$1" ; shift
tval=$1 ; shift
annot="$1" ; shift
labelfiles="" ; 
while [ _$1 != _ ] ; do
  cp "$1" $tmpdir # copy inputs to tmpdir
  labels=$labels,\'$(basename $1)\'
  shift
done
labels="{$labels}"
labels=$(echo $labels | sed "s|{,'|{'|g")
wd=`pwd`

# copy files to tmpdir
cp $(which annotquery_label.m) $tmpdir
cp $(which annotquery_sig.m) $tmpdir
cp $annot $tmpdir

# adapt .m file
if [ $tval = "0" ] ; then
  sed -i "s|% labelfiles=LABELS|labelfiles=$labels|g" $tmpdir/annotquery_label.m
  sed -i "s|% annotfile=ANNOT|annotfile=\'$(basename $annot)\'|g" $tmpdir/annotquery_label.m
  sed -i "s|% out=OUT|out=\'$(basename $out)\'|g" $tmpdir/annotquery_label.m
  echo "exit" >> $tmpdir/annotquery_label.m
else
  sed -i "s|% sigfiles=SIGFILES|sigfiles=$labels|g" $tmpdir/annotquery_sig.m
  sed -i "s|% annotfile=ANNOT|annotfile=\'$(basename $annot)\'|g" $tmpdir/annotquery_sig.m
  sed -i "s|% out=OUT|out=\'$(basename $out)\'|g" $tmpdir/annotquery_sig.m
  sed -i "s|% tval=TVAL|tval=$tval|g" $tmpdir/annotquery_sig.m
  echo "exit" >> $tmpdir/annotquery_sig.m
fi

# execute
cd $tmpdir
if [ $tval = "0" ] ; then
  xterm -e "matlab -nodesktop -nosplash -r annotquery_label"
else
  xterm -e "matlab -nodesktop -nosplash -r annotquery_sig"
fi
cd $wd

# copy results file
cp $tmpdir/$(basename $out) $out

# display result
cat $out
