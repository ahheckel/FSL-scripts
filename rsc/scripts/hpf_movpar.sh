#!/bin/bash
# Create pseudoimage from motion paramaters and apply high-pass filter on it.

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <movpar> <output> <hpf(s)> <TR(s)> [<subj_idx>] [<sess_idx>]"
    echo "Example: `basename $0` prefiltered_func_data_mcf.par movpar.hpf 150 3.30"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage
data="$1"
out="$2"
hpf="$3"
TR="$4"
subj="$5"  # optional
sess="$6"  # optional

if [ ! -f $data ] ; then echo "`basename $0`: subj $subj , sess $sess : ERROR: '$data' not found - exiting." exit 1 ; fi

echo "`basename $0`: subj $subj , sess $sess : high-pass filtering '$data'."

# count number of columns
n_cols=$(awk '{print NF}' $data | sort -nu | head -n 1)

# count number of data points
n=$(cat $data | wc -l)

echo "`basename $0`: subj $subj , sess $sess : $n data points in $n_cols columns."

fil=""
for i in `seq 1 $n_cols` ; do
  # extract column
  cat $data | awk -v c=${i} '{print $c}' > ${out}_$(zeropad $i 4)
  # create pseudoimage
  fslascii2img ${out}_$(zeropad $i 4) 1 1 1 $n 1 1 1 $TR ${out}_$(zeropad $i 4).nii.gz
  # hpf pseudoimage
  feat_hpf.sh ${out}_$(zeropad $i 4).nii.gz ${out}_$(zeropad $i 4)_hpf.nii.gz $hpf $TR $subj $sess
  # convert to ascii
  fsl2ascii ${out}_$(zeropad $i 4)_hpf.nii.gz ${out}_$(zeropad $i 4)_hpf
  # concatenate ascii
  cat ${out}_$(zeropad $i 4)_hpf????? | sed '/^\s*$/d' > ${out}_$(zeropad $i 4)_hpf
  # collect hpf'ed ascii files
  fil=$fil" "${out}_$(zeropad $i 4)_hpf
  # cleanup
  rm ${out}_$(zeropad $i 4)_hpf????? ${out}_$(zeropad $i 4)
  rm ${out}_$(zeropad $i 4).nii.gz ${out}_$(zeropad $i 4)_hpf.nii.gz 
done

# create final output
#echo $fil
paste -d " " $fil > ${out}

# cleanup
rm $fil 

echo "`basename $0`: subj $subj , sess $sess : done."
