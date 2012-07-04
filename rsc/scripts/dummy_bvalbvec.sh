#!/bin/bash
# creating pseudo bval/bvec files

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <4Dinput> <n_b0>"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage
file=`remove_ext "$1"`
if [ x"$2" = "x" ] ; then n_b0=4 ; else n_b0=$2 ; fi

nvols=`fslinfo  $file | grep ^dim4 | awk '{print $2}'`
intb0=$(scale=0; echo "$nvols / $n_b0" | bc)

vals=""
vecs=""
for i in `seq 1 $nvols` ; do
  if [ $i -eq 1 -a $n_b0 -gt 0 ] ; then
    vals=0
    vecs=0.5
  elif [ $i -le $n_b0 ] ; then
    vals=$vals" "0
    vecs=$vecs" "0.5
  else
    vals=$vals" "1000
    vecs=$vecs" "0.5    
  fi
done

echo "`basename $0`: '${file}_bvals':"
echo $vals | tee ${file}_bvals
echo "`basename $0`: '${file}_bvecs':"
echo $vecs
echo $vecs
echo $vecs
echo $vecs > ${file}_bvecs
echo $vecs >> ${file}_bvecs
echo $vecs >> ${file}_bvecs

echo "`basename $0`: done."
