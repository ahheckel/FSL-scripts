#!/bin/bash

for i in $(qstat -f |grep $(whoami | cut -c 1-10) | awk '{print $1}') ; do qdel $i ; done

