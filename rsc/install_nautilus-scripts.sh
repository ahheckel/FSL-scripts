#!/bin/bash
set -e

Usage() {
    echo ""
    echo "Usage:  `basename $0` <subdir>"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

subdir="$1"
cd $(dirname $0)
installdirs="$HOME/.gnome2/nautilus-scripts/$subdir $HOME/.local/share/nautilus/scripts/$subdir" # for old and newer (ubuntu >14.04, gnome3) nautilus versions
for installdir in $installdirs ; do
  mkdir -p $installdir
  echo $installdir
  cp -sf `pwd`/scripts/nautilus-scripts/* $installdir ; rm $installdir/env_vars
  cp `pwd`/scripts/nautilus-scripts/env_vars $installdir
  sed -i "s|PATH=.*|PATH=${PATH}|g" $installdir/env_vars
  sed -i "s|FSL_DIR=.*|FSL_DIR=${FSLDIR}|g" $installdir/env_vars
  sed -i "s|FREESURFER_HOME=.*|FREESURFER_HOME=${FREESURFER_HOME}|g" $installdir/env_vars
  sed -i "s|scriptdir=.*|scriptdir=`pwd`/scripts|g" $installdir/env_vars
  echo "$(basename $0): scripts installed in '$installdir' - done."
done

echo "$(basename $0): env_vars created in installation directory:"
echo "---------------------------"
cat $installdir/env_vars
echo "---------------------------"
