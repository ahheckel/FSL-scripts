#!/bin/bash
# Wrapper for slicesdir to supply a output directory name other than 'slicesdir'.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 05/19/2014

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` [<slicesdir options>] <outdir> <input-volumes>"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage

# parse inputs
opts=""
while [ $(echo "$1" | grep ^- | wc -l) -eq 1 ] ; do
  opts=$opts" "$1
  if [ "$1" = "-p" ] ; then opts=$opts" "$2 ; shift ; fi
  if [ "$1" = "-e" ] ; then opts=$opts" "$2 ; shift ; fi
  shift
done
outdir="$1"
shift
inputs="$@"

# run slicesdir
slicesdir $opts $inputs >/dev/null
if [ -d $outdir ] ; then
  read -p "Press key to delete '$outdir' directory..."
  rm -r $outdir/*
  rmdir $outdir
fi

# rename to output directory
mv slicesdir $outdir

# display info
echo ""
echo "Finished. To view, point your web browser at"
if [ $(echo $outdir | grep ^/ | wc -l ) -gt 0 ] ; then
  echo "firefox file:$outdir/index.html"
else
  echo "firefox file:`pwd`/$outdir/index.html"
fi
echo ""
