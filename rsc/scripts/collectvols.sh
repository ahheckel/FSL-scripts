#!/bin/bash
# collect and merge volumes from the directory tree

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <4doutput> <\"subdir/filename\"> <subjectsdir> <\"01 02 ...\"|-> <\"sessa sessb ...\">"
    echo ""
    exit 1
}

[ "$5" = "" ] && Usage
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


mkdir -p $(dirname $out)
files=""
c=1 ; for i in $subj ; do
  for j in $sess ; do 
    if [ -f $i/$j/$file ] ; then
      echo "$(zeropad $c 3) found: $i/$j/$file"
      files=$files" "$i/$j/$file
      c=$[$c+1]
    else
      echo "    not found: $i/$j/$file"
    fi
  done
done ; c=0

set +e
read -p "Press key..."
set -e

echo "merging..."
cmd="fslmerge -t ${out} $files"
echo $cmd ; $cmd

#cmd="fslview ${out}"
#echo $cmd | tee ${out}.cmd ; chmod +x ${out}.cmd ; $cmd


echo "`basename $0`: done."
