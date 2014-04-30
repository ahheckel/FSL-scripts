#!/bin/bash
# Make .ecclog file from matrix.

# Adapted by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 08/03/2013

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage:   $(basename $0) <matrix> <n> <out.ecclog>"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

mat="$1"
n=$2
output="$3"

if [ ! -f $mat ] ; then echo "$(basename $0): '$mat' not found. Exiting." ; exit 1 ; fi
  
rm -f ${output}
for i in `seq 1 $n` ; do
  echo processing $i >> ${output}
  echo "" >> ${output}
  echo "Final result:" >> ${output}
  cat $mat >> ${output}
  echo "" >> ${output}
done

echo "$(basename $0): done."
