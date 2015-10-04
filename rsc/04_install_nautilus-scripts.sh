#!/bin/bash

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/01/2013

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:    `basename $0` <subdir>"
    echo "Example:  `basename $0` MRI"
    echo "          `basename $0` ."
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

subdir="$1"
cd $(dirname $0)
installdirs="$HOME/.gnome2/nautilus-scripts/$subdir $HOME/.local/share/nautilus/scripts/$subdir" # for old and newer (ubuntu >=14.04, gnome3) nautilus versions
for installdir in $installdirs ; do
  mkdir -p $installdir
  #cp -sf `pwd`/scripts/nautilus-scripts/* $installdir ; rm $installdir/env_vars # symlinks may not be recognized by some nautilus versions
  cp -f `pwd`/scripts/nautilus-scripts/* $installdir ; rm $installdir/env_vars ; chmod u+x $installdir/*
  cp `pwd`/scripts/nautilus-scripts/env_vars $installdir
  sed -i "s|PATH=.*|PATH=${PATH}|g" $installdir/env_vars
  sed -i "s|FSL_DIR=.*|FSL_DIR=${FSLDIR}|g" $installdir/env_vars
  sed -i "s|FREESURFER_HOME=.*|FREESURFER_HOME=${FREESURFER_HOME}|g" $installdir/env_vars
  sed -i "s|scriptdir=.*|scriptdir=`pwd`/scripts|g" $installdir/env_vars
  echo "$(basename $0): scripts installed in '$installdir' - done."
done

echo "$(basename $0): file 'env_vars' created in installation directory with following content:"
echo "--------------------------------"
cat $installdir/env_vars
echo "--------------------------------"
