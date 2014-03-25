#!/bin/bash
# Creates pseudoimage from motion paramaters and applies high-pass filter on it.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/25/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <movpar> <output> <hpf(s)> <TR(s)> [<subj_idx>] [<sess_idx>]"
    echo "Example: `basename $0` prefiltered_func_data_mcf.par movpar.hpf 150 3.30"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage
data="$1"
out="$2"
hpf="$3"
TR="$4"
subj="$5"  # optional
sess="$6"  # optional

# checks
if [ ! -f $data ] ; then echo "`basename $0`: subj $subj , sess $sess : ERROR: '$data' not found - exiting." exit 1 ; fi
if [ "$hpf" = "Inf" -o "$hpf" = "inf" ] ; then
  echo "`basename $0`: subj $subj , sess $sess : no filtering -> just copying '$data' to '$out' (hpf=${hpf})."
  cp ${data} ${out}
  exit
fi

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# count number of columns
n_cols=$(awk '{print NF}' $data | sort -nu | head -n 1)

# count number of data points
n_rows=$(cat $data | wc -l)

# info
echo "`basename $0`: subj $subj , sess $sess : high-pass filtering '$data' ($n_rows rows , $n_cols columns) --> '$out'"

# transpose input to please fslascii2img
$(dirname $0)/transptxt.sh $data $tmpdir/data_transp
# create pseudoimage
fslascii2img $tmpdir/data_transp $n_cols 1 1 $n_rows 1 1 1 $TR $tmpdir/data.nii.gz
# hpf pseudoimage
$(dirname $0)/feat_hpf.sh $tmpdir/data.nii.gz $tmpdir/data_hpf.nii.gz $hpf $TR $subj $sess
# convert to ascii
fsl2ascii $tmpdir/data_hpf.nii.gz $tmpdir/data_hpf
# concatenate ascii
cat $tmpdir/data_hpf????? | sed '/^\s*$/d' > $out

# done
echo "`basename $0`: subj $subj , sess $sess : done."
