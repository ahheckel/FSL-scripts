#!/bin/bash
# Replaces whole-numbered value (incl. zero) in an FSL mask.

# Adapted by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 01/04/2014

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage:     $(basename $0) <input-mask> <source-val> <dest-val> <output-mask>"
    echo "Example:   $(basename $0) mask1 1 4 mask2"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage
  
# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
#trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# assign arguments
input=$(remove_ext $1)
val0="$2"
val1="$3"
output=$(remove_ext $4)

# check
if [ $(imtest $input) -eq 0 ] ; then
  echo "$(basename $0): ERROR: '$input' does not exist or is not a volume - exiting..." ; exit 1
fi

# execute
echo "$(basename $0):"
mask=$tmpdir/mask
if [ x"$val0" != "x0" ] ; then
  cmd="fslmaths $input -thr $val0 -mul -1 -thr -${val0} -mul -1 $mask" ; echo "    $cmd" ; $cmd
  maximum=`fslstats $mask -R | cut -d " " -f 2  | cut -d . -f 1`
  if [ $maximum = "0" ] ; then
   echo "$(basename $0): WARNING: value '$val0' not found in '$input'!"
  fi
  # remove val0 from input
  cmd="fslmaths $input -sub $mask ${mask}_sub" ; echo "    $cmd" ; $cmd
  # replace val0 with val1
  cmd="fslmaths $mask -abs -bin -mul $val1 ${mask}_repl" ; echo "    $cmd" ; $cmd
  cmd="fslmaths ${mask}_sub -add ${mask}_repl $output" ; echo "    $cmd" ; $cmd
else
  # invert
  cmd="fslmaths $input -abs -binv $mask" ; echo "    $cmd" ; $cmd
  maximum=`fslstats $mask -R | cut -d " " -f 2  | cut -d . -f 1`
  if [ $maximum = "0" ] ; then
   echo "$(basename $0): WARNING: value '$val0' not found in '$input'!"
  fi
  # replace 0 with val1
  cmd="fslmaths $mask -mul $val1 ${mask}_repl" ; echo "    $cmd" ; $cmd
  cmd="fslmaths $input -add ${mask}_repl $output" ; echo "    $cmd" ; $cmd
fi

# done
echo "$(basename $0): done."
