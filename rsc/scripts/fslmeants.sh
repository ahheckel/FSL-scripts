#!/bin/bash
# fslmeants per x/y/z/t coordinate

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/04/2014

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage:  `basename $0` <input> <mask> <x,y,z,t min> <x,y,z,t size> <fslmeants_opts>"
    echo "Example:  `basename $0` input mask 0,0,3,0 -1,-1,1,-1 --showall -o output"
    echo "          `basename $0` input mask 0,0,3,5 -1,-1,9,1 --label -o output"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage

# define input arguments
input=$(remove_ext "$1")
shift
mask=$(remove_ext "$1")
shift
xyzt_min=$(echo "$1" | sed "s|,| |g")
shift
xyzt_size=$(echo "$1" | sed "s|,| |g")
x=$(echo $xyzt_min | cut -d " " -f 1)
y=$(echo $xyzt_min | cut -d " " -f 2)
z=$(echo $xyzt_min | cut -d " " -f 3)
t=$(echo $xyzt_min | cut -d " " -f 4)
xs=$(echo $xyzt_size | cut -d " " -f 1)
ys=$(echo $xyzt_size | cut -d " " -f 2)
zs=$(echo $xyzt_size | cut -d " " -f 3)
ts=$(echo $xyzt_size | cut -d " " -f 4)
shift
opts="$@"

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# extract
cmd="fslroi $input $tmpdir/roi_in $x $xs $y $ys $z $zs $t $ts"
echo "    $cmd" ; $cmd
cmd="fslroi $mask  $tmpdir/roi_mask $x $xs $y $ys $z $zs $t $ts"
echo "    $cmd" ; $cmd

# run fslmeants
# If use --label switch, ommit the -m switch, otw. will give incorrect results (bug in fslmeants ?)
if [ $(echo $opts | grep "\-\-label" | wc -l) -gt 0 ] ; then
  opts=$(echo $opts | sed "s|--label|--label=$tmpdir/roi_mask|g")
  cmd="fslmeants -i $tmpdir/roi_in $opts"
else
  cmd="fslmeants -i $tmpdir/roi_in -m $tmpdir/roi_mask $opts"
fi
echo "    $cmd" ; $cmd

# done
echo "`basename $0` : done."
