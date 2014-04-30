#!/bin/bash
# Splits text file into files with n columns.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 08/14/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e
 
function testascii()
{
  local file="$1"
  if LC_ALL=C grep -q '[^[:print:][:space:]]' $file; then
      echo "0"
  else
      echo "1"
  fi
}

Usage() {
    echo ""
    echo "Usage:   `basename $0` <inputTXT> <size> <outputTXT>"
    echo "Example: `basename $0` in 128 out"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# assign input arguments
input="$1"
n=$2
output="$3"

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# check whether textfile or not
if [ ! -f $input ] ; then
  echo "`basename $0` : 'input' does not exist. Exiting." ; exit 1
fi
if [ $(testascii $input) -eq 0 ] ; then
  echo "`basename $0` : cannot read 'input' - is it a textfile ? Exiting." ; exit 1
fi

# count columns
n_cols=$(awk '{print NF}' $input | sort -nu | head -n 1)
echo "`basename $0` : $n_cols columns in '$input'."

# check for residuals
iter=$(echo "scale=0 ; $n_cols / $n" | bc -l)
_n_cols=$(echo "scale=0; $iter*$n" | bc -l)
resid=$(echo "scale=0; $n_cols - $_n_cols" | bc -l)
if [ $resid -gt 0 ] ; then echo "`basename $0` : WARNING: last split ('${output}_$(zeropad $iter 3)') will only have $resid columns (not $n)." ; fi

# extract data column-wise
echo "`basename $0` : extracting data column-wise from '$input'..."
beg=1
last=$n
j=0
while [ 1 -eq 1 ] ; do
  files=""
  if [ $last -gt $n_cols ] ; then last=$n_cols ; fi
  for i in `seq $beg $last` ; do
    # extract column
    cat $input | awk -v c=${i} '{print $c}' > $tmpdir/$(basename $output)_$(zeropad $i 4)  
    files=$files" "$tmpdir/$(basename $output)_$(zeropad $i 4)  
  done
  paste -d " " $files > ${output}_$(zeropad $j 3)
  if [ $last -eq $n_cols ] ; then break ; fi
  beg=$[$last+1] ; last=$[$beg-1+$n] ; j=$[$j+1]
done

# done
echo "`basename $0` : done."
