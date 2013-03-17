#!/bin/bash
# Applies MATLAB-formula to columns of numbers in textfile using OCTAVE.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/23/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:   `basename $0` <input-txt> <\"formula\"> <ouput-txt>"
    echo "         Each column in <input.txt> is loaded into OCTAVE variable 'c'."
    echo ""
    echo "Example: `basename $0` movpar.txt \"c\" movpar_nothingdone.txt"
    echo "         `basename $0` movpar.txt \"abs(c)\" movpar_abs.txt"
    echo "         `basename $0` movpar.txt \"c.*c\" movpar_squared.txt"
    echo "         `basename $0` movpar.txt \"c=diff(c); c=[0 ; c]\" movpar_1stderiv.txt"
    echo ""
    exit 1
}

function row2col()
{
  local dat=`cat $1`
  local i=""
  for i in $dat ; do echo $i ; done
}

if [ x$(which octave) = "x" ] ; then echo "`basename $0` : ERROR : OCTAVE does not seem to be installed on your system ! Exiting..." ; exit 1 ; fi

[ "$3" = "" ] && Usage
data="$1"
formula="output_precision(8); $2"
output="$3" 
outdir=`dirname $output`
indir=`dirname $data`

# check inout file
if [ ! -f $data ] ; then echo "`basename $0` : ERROR : input file '$data' not found... exiting." ; exit 1 ; fi

# count number of columns
n_cols=$(awk '{print NF}' $data | sort -nu | head -n 1)

# count number of data points
n=$(cat $data | wc -l)

echo "`basename $0` : $n data points in $n_cols columns."

# extract data column-wise and apply formula
echo "`basename $0` : applying formula '$formula' to each column..."
files=""
for i in `seq 1 $n_cols` ; do
  # extract column
  vals=$(cat $data | awk -v c=${i} '{print $c}')
  # apply formula
  c=$(octave -q --eval "c=[$vals] ; $formula") ; echo $c | cut -d "=" -f 2- | row2col > ${output}_$(zeropad $i 4)
  files=$files" "${output}_$(zeropad $i 4)
done

# create matrix
echo "`basename $0` : creating matrix '$output'..."
paste -d " " $files > $output

# cleanup
rm $files

echo "`basename $0` : done."

