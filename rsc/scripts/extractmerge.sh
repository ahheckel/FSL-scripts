#!/bin/bash

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

wdir=`pwd`/.extmerge$$
mkdir -p $wdir
trap "echo -e \"\ncleanup: erasing '$wdir'\" ; rm -f $wdir/* ; rmdir $wdir ; exit" EXIT
    
Usage() {
    echo ""
    echo "Usage: `basename $0` <out4D> <idx> <\"input files\">"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage    
  
out="$1"
idx="$2"
inputs="$3"

n=0
for input in $inputs ; do
  echo "`basename $0`: extracting volume at pos. $idx from '$input'..."
  fslroi $input $wdir/_tmp_$(zeropad $n 4) $idx 1
  n=$(echo "$n + 1" | bc)
done
echo "`basename $0`: merging..."
fslmerge -t ${out} $(imglob $wdir/_tmp_????)

echo "`basename $0`: done."
