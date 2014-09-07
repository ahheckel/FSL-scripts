#!/bin/bash
# Computes T2 relaxation time from 4D double-echo.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 04/25/2014

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <TE2-TE1(ms)> <output4D>"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# define vars
input=`remove_ext "$1"`
dTE=$2
output=`remove_ext "$3"`

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# check
if [ $(fslnvols $input) -ne 2 ] ; then
  echo "`basename $0` : ERROR: '$input' needs to contain two volumes (echoes) - exiting..." ; exit 1
fi

# execute
cmd="fslroi $input $tmpdir/0 0 1"
echo "    $cmd"  ; $cmd
cmd="fslroi $input $tmpdir/1 1 1"
echo "    $cmd"  ; $cmd
cmd="fslmaths $tmpdir/0 -div $tmpdir/1 $tmpdir/div" 
echo "    $cmd"  ; $cmd
cmd="fslmaths $tmpdir/div -log -recip -mul $dTE $output" 
echo "    $cmd"  ; $cmd

# done
echo "`basename $0` : done."
