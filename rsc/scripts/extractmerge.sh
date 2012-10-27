#!/bin/bash

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

wdir=`pwd`/.extmerge$$
mkdir -p $wdir
trap "echo -e \"\ncleanup: erasing '$wdir'\" ; rm -f $wdir/* ; rmdir $wdir ; exit" EXIT
   
Usage() {
    echo ""
    echo "Usage: `basename $0` <out4D> <indices|all|mid> [<fslmaths unary operator>] <\"input files\">"
    echo "Example: `basename $0` means.nii.gz 1,2,3 -Tmean \"\$inputs\""
    echo "         `basename $0` bolds.nii.gz \"1 2 3\" \" \" \"\$inputs\""
    echo "         `basename $0` bolds.nii.gz 1 \"\$inputs\""
    echo "         `basename $0` bolds.nii.gz all -Tmean \"\$inputs\""
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage    

# define vars
out="$1"
idces="$(echo "$2" | sed 's|,| |g')"
if [ $(echo $idces | wc -w) -gt 1 -o "$idces" = "all" ] ; then op="$3" ; shift ; fi
inputs="$3"

# extracting...
n=0 ; i=1
for input in $inputs ; do
  if [ ! -f $input ] ; then echo "`basename $0`: '$input' not found." ; continue ; fi
  if [ "$idces" = "all" ] ; then
    echo "`basename $0`: $i - applying unary fslmaths operator '$op' to '$input'..."
    fslmaths $input $op $wdir/_tmp_$(zeropad $n 4) # apply operator
  elif [ "$idces" = "mid" ] ; then
      nvol=`fslinfo  $input | grep ^dim4 | awk '{print $2}'` ; mid=$(echo "scale=0 ; $nvol / 2" | bc)
      echo "`basename $0`: $i - extracting volume at pos. $mid from '$input'..."
      fslroi $input $wdir/_tmp_$(zeropad $n 4) $mid 1
  else
    for idx in $idces ; do
      echo "`basename $0`: $i - extracting volume at pos. $idx from '$input'..."
      if [ $(echo $idces | wc -w) -gt 1 ] ; then
        fslroi $input $wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4) $idx 1
      else
        fslroi $input $wdir/_tmp_$(zeropad $n 4) $idx 1
      fi
    done
  fi
  n=$(echo "$n + 1" | bc)
  i=$[$i+1]
done

# if more than one index...
if [ $(echo $idces | wc -w) -gt 1 ] ; then
  n=0 ; rm -f $wdir/apply_operator.cmd
  echo "`basename $0`: merging (and applying unary fslmaths operator: '$op')..."
  for input in $inputs ; do
    if [ ! -f $input ] ; then continue ; fi
    files=""
    for idx in $idces ; do files=$files" "$wdir/_tmp_$(zeropad $n 4)_idx$(zeropad $idx 4) ; done
    echo "fslmerge -t $wdir/_tmp_$(zeropad $n 4) $files ; \
    imrm $files ; \
    fslmaths $wdir/_tmp_$(zeropad $n 4) $op $wdir/_tmp_$(zeropad $n 4)" >> $wdir/apply_operator.cmd
    n=$(echo "$n + 1" | bc)
  done
  cat $wdir/apply_operator.cmd
  . $wdir/apply_operator.cmd
fi # end if

# merging...
echo "`basename $0`: merging to '${out}'..."
fslmerge -t ${out} $(imglob $wdir/_tmp_????.*)

echo "`basename $0`: done."
