#!/bin/bash
# extract images from 4D volume
set -e

trap 'echo "$0 : An ERROR has occured."' ERR
    
Usage() {
    echo ""
    echo "Usage: `basename $0` <out-Prefix> <idx> <\"input file\">"
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
