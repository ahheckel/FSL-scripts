#!/bin/bash
# Deletes all SGE jobs belonging to the current user.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

for i in $(qstat -f |grep $(whoami | cut -c 1-10) | awk '{print $1}') ; do qdel $i ; done

