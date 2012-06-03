#!/bin/bash

key=""
while [ x$key != "xq" ] ; do clear; qstat -f ; read -t 2 -n 1 key ; done
echo ""

