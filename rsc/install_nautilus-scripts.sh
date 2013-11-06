#!/bin/bash
subdir="$1"
cd $(dirname $0)
installdir=~/.gnome2/nautilus-scripts/$subdir
mkdir -p $installdir
cp -sf `pwd`/scripts/nautilus-scripts/*  $installdir
rm $installdir/env_vars
cp `pwd`/scripts/nautilus-scripts/env_vars $installdir

