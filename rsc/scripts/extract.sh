#!/bin/bash
# Extracts images from 4D volume.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

set -e

trap 'echo "$0 : An ERROR has occured."' ERR
    
Usage() {
    echo ""
    echo "Usage: `basename $0` <out-Prefix> <idx> <input file>"
    echo "Example: `basename $0` ./test/melodic 0,1,2,3 melodic_IC.nii.gz"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage    

pref="$1" ; mkdir -p $(dirname $pref)
idxs="$(echo "$2" | sed 's|,| |g')"
input=$(remove_ext "$3")
#pref=$(basename $input)

for idx in $idxs ; do
  #echo "`basename $0`: extracting volume at pos. $idx from '$input'..."
  cmd="fslroi $input ${pref}_$(zeropad $idx 4) $idx 1"
  echo $cmd ; $cmd
done

echo "`basename $0`: done."
