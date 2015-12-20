#!/bin/bash

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage:   `basename $0` <b0> <nerve-mask> <softtissue-mask>"
    echo "Example: `basename $0` b0 nerve-mask soft-mask"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

b0="$(remove_ext $1)"
mask="$(remove_ext $2)"
softmask="$3"

# fsl ver.
fslversion=$(cat $FSLDIR/etc/fslversion)

 
# display info
echo "---------------------------"
echo "`basename $0` : fsl V.:       $fslversion"
echo "`basename $0` : input:        $b0"
echo "`basename $0` : nerve-mask:   $mask"
echo "`basename $0` : soft-mask:    $softmask"
echo "---------------------------"

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# make soft tissue mask (outside nerve)
imcp $b0 $tmpdir/
bet $tmpdir/$(basename $b0) $tmpdir/b0_bet -f 0.1 -m
fslmaths $tmpdir/b0_bet_mask -sub $mask -thr 0 $softmask

echo "`basename $0` : done."
