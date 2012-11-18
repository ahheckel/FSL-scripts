#!/bin/bash
# Removes noise from a 4D functional.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <matrix> <output4D> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

input=$(remove_ext "$1")
matrix="$2"
output=$(remove_ext "$3")
subj="$4"  # optional
sess="$5"  # optional

echo "`basename $0` : subj $subj , sess $sess : removing nuisance regressors..."

n_cols=$(awk '{print NF}' $matrix | sort -nu | head -n 1)
comps=$(echo `seq 1 $n_cols` | sed "s| |","|g")
cmd="fsl_regfilt -i $input -o ${output} -d $matrix -f $comps"
echo $cmd | tee ${output}.cmd ; $cmd

echo "`basename $0` : subj $subj , sess $sess : done."

