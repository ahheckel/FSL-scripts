#!/bin/bash
# removes noise from 4D functional 

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


n_cols=$(awk '{print NF}' $matrix | sort -nu | head -n 1)
comps=$(echo `seq 1 $n_cols` | sed "s| |","|g")
cmd="fsl_regfilt -i $input -o ${output} -d $matrix -f $comps"
echo $cmd | tee ${output}.cmd ; $cmd

echo "`basename $0` : subj $subj , sess $sess : done."

