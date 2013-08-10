#!/bin/bash
# Creates union of provided index numbers.

# Adapted by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 07/17/2013

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage:     $(basename $0) <input-mask> <mask-values> <output-mask>"
    echo "Example:   $(basename $0) mask 1,4,5 mask_reduced"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage
  
# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# assign arguments
input=$(remove_ext $1)
vals="$2"
output=$(remove_ext $3)

# check
if [ $(imtest $input) -eq 0 ] ; then
  echo "$(basename $0): ERROR: '$input' does not exist or is not a volume - exiting..." ; exit 1
fi
if [ "$input" = "$output" ] ; then
  echo "$(basename $0): ERROR: input '$input' and output '$output' are the same - exiting..." ; exit 1
fi

# rem commas
vals="$(echo "$vals" | sed 's|,| |g')"

# execute
echo "$(basename $0):"
masks=""
for i in $vals ; do
 cmd="fslmaths $input -thr $i -mul -1 -thr -${i} -mul -1 $tmpdir/mask_${i}" ; echo "    $cmd" ; $cmd
 maximum=`fslstats $tmpdir/mask_${i} -R | cut -d " " -f 2  | cut -d . -f 1`
 if [ $maximum = "0" ] ; then
  echo "$(basename $0): WARNING: value '$i' not found in '$input'!"
 fi
 masks=$masks" "$tmpdir/mask_${i}
done

# merge and binarize
cmd="fslmerge -t $output $masks" ; echo "    $cmd" ; $cmd
cmd="fslmaths $output -Tmax -bin $output" ; echo "    $cmd" ; $cmd

# done
echo "$(basename $0): done."
