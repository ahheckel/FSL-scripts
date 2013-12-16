#!/bin/bash

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

Usage() {
    echo ""
    echo "Usage:   `basename $0` <input3D> <mask3D> <text-output>"
    echo "Example: `basename $0` FA FA_1stb0-mask FA_vals.txt"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

input="$(remove_ext $1)"
mask="$(remove_ext $2)"
out="$3"

# fsl ver.
fslversion=$(cat $FSLDIR/etc/fslversion)

# extract range
n0min=$(fslstats $mask -R | awk '{print$1}')
n0max=$(fslstats $mask -R | awk '{print$2}')

# number of slices (z)
Z=$(fslinfo $mask | grep ^dim3 | awk '{print $2}')
 
# display info
echo "---------------------------"
echo "`basename $0` : fsl V.:     $fslversion"
echo "`basename $0` : input:      $input"
echo "`basename $0` : slices(z):  $Z"
echo "`basename $0` : mask:       $mask"
echo "`basename $0` : markers:    ${n0min} - ${n0max}"
echo "`basename $0` : mask:       $mask"
echo "`basename $0` : txt-out:    $out"
echo "---------------------------"

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files
#tmpdir=`pwd`/${outdir}_$(basename $0).$$ ; mkdir $tmpdir

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

$(dirname $0)/split4D.sh z $mask [0:1:end] $tmpdir/$(basename $mask)
$(dirname $0)/split4D.sh z $input [0:1:end] $tmpdir/$(basename $input)

rm -f $tmpdir/meants ; outs_tmp=""
for n in `seq $n0min $n0max` ; do # for each "color"
  for i in `seq 0 $[$Z-1]` ; do # for each slice
    # segment
    cmd="$(dirname $0)/seg_mask.sh $tmpdir/$(basename $mask)_slice_$(zeropad $i 4) $n $tmpdir/$(basename $mask)_slice_$(zeropad $i 4)_$(zeropad $n 3)"
    echo $cmd ; $cmd #1 > /dev/null
    
    # extract
    cmd="fslmeants -i $tmpdir/$(basename $input)_slice_$(zeropad $i 4) -m $tmpdir/$(basename $mask)_slice_$(zeropad $i 4)_$(zeropad $n 3)"
    echo $cmd ; $cmd >> $tmpdir/meants_$(zeropad $n 3)   
  done
  # remove blank lines
  sed '/^$/d' $tmpdir/meants_$(zeropad $n 3) > $tmpdir/out_$(zeropad $n 3)
  # collect n outputs (n=number of colors or "nerves")
  outs_tmp=$outs_tmp" "$tmpdir/out_$(zeropad $n 3)
  echo ""
done

# horz-cat
echo "paste -d \" \" $outs_tmp > $out"
paste -d " " $outs_tmp > $out

# done.
echo "`basename $0` : done."
