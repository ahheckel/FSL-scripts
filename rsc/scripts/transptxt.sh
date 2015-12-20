#!/bin/bash
# Transpose table in textfile

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 25/03/2014

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
    echo "Usage: `basename $0` <input-txt> <output-txt>"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage
data="$1"
out="$2"

# check
if [ $(testascii $data) -eq  0 ] ; then
  echo "`basename $0`: ERROR : cannot read inputfile '$data' - exiting." ; exit 1 
fi

# count number of columns
n_cols=$(awk '{print NF}' $data | sort -nu | head -n 1)

# count number of rows
n_rows=$(cat $data | wc -l)

echo -n "`basename $0`: $n_rows rows , $n_cols columns --> "

# extract column
rm -f $out
for i in `seq 1 $n_cols` ; do  
  v=$(cat $data | awk -v c=${i} '{print $c}')
  echo $v >> $out
done

# count number of columns
n_cols=$(awk '{print NF}' $out | sort -nu | head -n 1)

# count number of rows
n_rows=$(cat $out | wc -l)

echo "$n_rows rows , $n_cols columns."
