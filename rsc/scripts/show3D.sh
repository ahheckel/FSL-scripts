#!/bin/bash

files=`find ./ -mindepth "$2" -maxdepth "$3" -name "$1"  -type f | sort`
for i in $files ; do echo $i ; done

read -p "Press any key to continue..."

if [ $# -lt 5 ]
then
  find ./ -mindepth "$2" -maxdepth "$3" -name "$1"  -type f | sort | xargs -I{} --max-args=1 fslview {}
else
  find ./ -mindepth "$2" -maxdepth "$3" -name "$1"  -type f | sort | xargs -I{} --max-args=1 fslview {} -b $4,$5
fi


