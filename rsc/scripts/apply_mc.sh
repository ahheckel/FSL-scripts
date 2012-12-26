#!/bin/bash
# Applies motion-correction to 4D.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 12/25/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <output4D> <mc mat-dir|.ecclog file|matrix file> [<interp (default:trilinear)>]"
    echo "Example: `basename $0` bold mc_bold ./mc/prefiltered_func_data_mcf.mat/ spline"
    echo "Example: `basename $0` bold mc_bold ./matrix.mat sinc"
    echo "Example: `basename $0` diff mc_diff ./diff.ecclog trilinear"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# define vars
input=`remove_ext "$1"`
output=`remove_ext "$2"`
mcdir="$3"
interp="$4"
if [ x"$interp" = "x" ] ; then interp="trilinear" ; fi

# calling function
cmd="$(dirname $0)/apply_mc+unwarp.sh $input $output $mcdir none 00 $interp"

# display info
echo "`basename $0` : executing:"
echo "    $cmd"
$cmd

echo "`basename $0` : done."
