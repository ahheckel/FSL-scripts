#!/bin/bash

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <4Dinput> <sliceorder-textfile>"
    echo ""
    exit 1
}
   
[ "$2" = "" ] && Usage
data=`remove_ext "$1"`
out="$2"

n=`fslinfo  $data | grep ^dim4 | awk '{print $2}'`
isuneven=$(echo "$n % 2" | bc)
if [ $isuneven -eq 1 ] ; then
  echo "`basename $0`: n=$n -> SIEMENS says: 'uneven first'..." 
  order=$(octave -q --eval "[1:2:$n,2:2:$n]'" | cut -d "=" -f 2-) # uneven first
elif [ $isuneven -eq 0 ] ; then
  echo "`basename $0`: n=$n -> SIEMENS says: 'even first'..." 
  order=$(octave -q --eval "[2:2:$n,1:2:$n]'" | cut -d "=" -f 2-) # even first
else
  echo "`basename $0`: An Error has occurred." 
  exit 1 
fi

rm -f $out
for i in $order ; do
  echo $i >> $out
done

echo "`basename $0`: done."
