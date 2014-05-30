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

# is variable defined ? (for use in excel, nautilus, etc.)
if [ x"$FSLDIR" = "x" ] ; then
  if [ -f ~/.gnome2/nautilus-scripts/MRI/env_vars ] ; then
    source ~/.gnome2/nautilus-scripts/MRI/env_vars
  elif [ -f ~/.gnome2/nautilus-scripts/env_vars ] ; then
    source ~/.gnome2/nautilus-scripts/env_vars
  else
    echo "$(basename $0) : ERROR: environment file '~/.gnome2/nautilus-scripts/MRI/env_vars' not found! Exiting." ; exit 1 
  fi
fi

# assign input arguments
inputs="$@"

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

fvinput=""
for input in $inputs ; do
  input=$(remove_ext $input)
  
  # add thresholded melodic mask if found
  c=${input#*__}
  d=${c%%__*}.gica
  echo ---------------------
  echo $d
  melmask=${input%/dualreg/*}/melodic/$d/groupmelodic.ica/melodic_IC_masks
  echo ---------------------
  echo $melmask
  if [ $(imtest $melmask) -eq 1 ] ; then
    fvinput="$melmask -l "Green""" "$fvinput
  fi
    
  # check1
  if [ $(imtest $input) -eq 0 ] ; then 
    input=${input%*__cluster*} # remove prefix __cluster? that might be present in excel sheet...
    if [ $(imtest $input) -eq 0 ] ; then 
      echo "$(basename $0) : WARNING: input '$input' not found! Continuing loop..." ; continue
    fi
  fi
  
  # check2
  code=$(fslhd $input | grep ^sform_code | awk '{print $2}')
  if [ $code -ne 4 ] ; then
    echo "`basename $0` : ERROR: '$input' doesn't seem to be registered to MNI space! (sform_code=${code}). Exiting." ; exit 1
  fi
  
  # define fslview argument
  fvinput=$fvinput" ""$input -l "Red-Yellow" -b 0.95,1 -t 1"
done # end input loop

# add melodic_IC on top if found
if [ $(imtest $(dirname $(dirname $input))/melodic_IC) -eq 1 ] ; then
  fvinput="$(dirname $(dirname $input))/melodic_IC -l "Blue-Lightblue" -b 2,6 -t 1"" "$fvinput
fi

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
