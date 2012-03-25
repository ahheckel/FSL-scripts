#!/bin/bash

files=`find ./ -mindepth "$2" -maxdepth "$3" -name "$1" -type f | sort`
for i in $files ; do echo $i ; done

read -p "Press any key to continue..."

if [ ! -f _output.tmp.nii.gz ] ; then 
  fslmerge -t _output.tmp $files
  fslview _output.tmp.nii.gz
  rm _output.tmp.nii.gz
else
  echo "_output.tmp already exists."
fi



