#!/bin/bash
# Deletes SGE jobs belonging to the current user.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/26/2013

Usage() {
    echo ""
    echo "Usage: `basename $0` [StringInJobname|all]"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

if [ "$1" = "all" ] ; then
  for i in $(qstat -f | grep $(whoami | cut -c 1-10) | awk '{print $1}' | grep -v @ | sort -u)  ; do qdel $i ; done
else
  for i in $(qstat -f | grep $(whoami | cut -c 1-10) | grep $1 | awk '{print $1}' | grep -v @ | sort -u) ; do qdel $i ; done
fi
