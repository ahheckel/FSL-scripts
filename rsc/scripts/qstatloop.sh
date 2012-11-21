#!/bin/bash
# Displays SGE queues in an endless-loop (exit with 'q').

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

key=""
while [ x$key != "xq" ] ; do clear; qstat -f ; read -t 2 -n 1 key ; done
echo ""

