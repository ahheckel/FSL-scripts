#!/bin/bash
# Duplicates input volume n times.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 19/03/2014

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage: $(basename $0) <input4D> <n|volume> <output4D>"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# define input arguments
input=`${FSLDIR}/bin/remove_ext ${1}`
n=`${FSLDIR}/bin/remove_ext ${2}`
output=`${FSLDIR}/bin/remove_ext ${3}`

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# check inputs
if [ `${FSLDIR}/bin/imtest $input` -eq 0 ];then
  echo "`basename $0`: '$input' does not exist or is not in a supported format."
  exit 1
fi
if [ $(imtest $n) -eq 1 ] ; then
  n=`fslnvols $n`
fi

# duplicate
echo "`basename $0`: duplicating '$input' $n times."
files=""
for i in `seq 1 $n` ; do
  imcp $input $tmpdir/$i
  files=$files" "$tmpdir/$i
done

# merge
fslmerge -t $output $files

# clean up
imrm $files

# done
echo "`basename $0`: done."
