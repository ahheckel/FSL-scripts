#!/bin/bash
# Load appropriate MNI template as overlay to MNI registered significance maps.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 05/26/2014

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:  `basename $0` <MNI-SPMs>"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

# assign input arguments
inputs="$@"

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

fvinput=""
for input in $inputs ; do
  input=$(remove_ext $input)
    
  # check1
  if [ $(imtest $input) -eq 0 ] ; then echo "$(basename $0) : WARNING: input '$input' not found! Continuing loop..." ; continue ; fi
  
  # check2
  code=$(fslhd $input | grep ^sform_code | awk '{print $2}')
  if [ $code -ne 4 ] ; then
    echo "`basename $0` : ERROR: '$input' doesn't seem to be registered to MNI space! (sform_code=${code}). Exiting." ; exit 1
  fi
  
  # define fslview argument
  fvinput=$fvinput" ""$input -l "Red-Yellow" -b 0.95,1 -t 1"
done # end input loop

# check3 (if size / resolution matches)
MNItemplates="${FSLDIR}/data/standard/MNI152_T1_4mm_brain ${FSLDIR}/data/standard/MNI152_T1_3mm_brain ${FSLDIR}/data/standard/MNI152_T1_2mm_brain ${FSLDIR}/data/standard/MNI152_T1_1mm_brain ${FSLDIR}/data/standard/MNI152_T1_0.5mm"
for MNI in $MNItemplates ; do
  if [ $(imtest $MNI) -eq 0 ] ; then echo "$(basename $0) : WARNING: template '$MNI' not found! Continuing loop..." ; continue ; fi
  set +e
  fslmeants -i $input -m $MNI &>/dev/null
  if [ $? -gt 0 ] ; then 
    echo "$(basename $0) : WARNING : size / resolution does not match btw. '$input' and '$MNI' (ignore error above) - continuing loop..."
    continue
  else
    set -e
    # execute
    fslview $MNI -t 1 -l "Greyscale" $fvinput &>/dev/null
    break
  fi        
done # end MNI loop

# done
echo "`basename $0` : done."
