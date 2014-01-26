#!/bin/bash
set -e
subdir="$1"
cd $(dirname $0)
installdir=~/.gnome2/nautilus-scripts/$subdir

mkdir -p $installdir
cp -sf `pwd`/scripts/nautilus-scripts/* $installdir ; rm $installdir/env_vars
cp `pwd`/scripts/nautilus-scripts/env_vars $installdir
sed -i "s|FSL_DIR=.*|FSL_DIR=${FSLDIR}|g" $installdir/env_vars
sed -i "s|FREESURFER_HOME=.*|FREESURFER_HOME=${FREESURFER_HOME}|g" $installdir/env_vars
sed -i "s|scriptdir=.*|scriptdir=`pwd`/scripts|g" $installdir/env_vars
echo "$(basename $0): installed scripts in '$installdir' - done."
