#!/bin/bash
# Robustfov wrapper (requires FSL 5).

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 02/02/2014

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage: $(basename $0) <input> <output> [<opts>]"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage

# define input arguments
input=`${FSLDIR}/bin/remove_ext ${1}`
output=`${FSLDIR}/bin/remove_ext ${2}`
shift 2
opts="$@"

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# checks
fslversion=$(cat $FSLDIR/etc/fslversion | cut -d . -f 1)
if [ `${FSLDIR}/bin/imtest $input` -eq 0 ];then
    echo "`basename $0`: ERROR: Input does not exist or is not in a supported format."
    exit 1
fi
if [ "$input" = "$output" ] ; then
  echo "`basename $0`: WARNING: Same filename for input and output ('$input')."
fi
if [ $fslversion -lt 5 ] ; then
  echo "`basename $0`: ERROR: FSL v5 or greater required (installed: v. $(cat $FSLDIR/etc/fslversion))."
  exit 1
fi

# execute
echo "`basename $0`: executing robustfov..."
robustfov -i $input $opts | tee $tmpdir/log
cmd="fslroi $input $tmpdir/$(basename $output) $(cat $tmpdir/log | grep ^[[:digit:]])"
echo -n "${cmd}; " ; $cmd
cmd="immv $tmpdir/$(basename $output) $output"
echo $cmd ; $cmd

# done
echo "`basename $0`: done."
