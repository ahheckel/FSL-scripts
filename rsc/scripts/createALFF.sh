#!/bin/bash

## This is an adaptation of the 1000 Connectome script written by Xi-Nian Zuo, Maarten Mennes & Michael Milham.
## For more information see www.nitrc.org/projects/fcon_1000

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

Usage() {
    echo ""
    echo "Usage: `basename $0` <ALFF-out> <bold4D-in> <mask> <TR(s)> <freq-band:LP,HP(Hz)>"
    echo "Example: `basename $0` outdir/ALFF.nii.gz bold/resting.nii.gz bold/mask.nii.gz 3.33 0.01,0.1"
    echo "         NOTE: Input should be motion-corrected (perhaps also unwarped + slicetiming corrected) with drifts removed and Grand-Mean scaled."
    exit 1
}

[ "$5" = "" ] && Usage

out=$(remove_ext "$1")
input=$(remove_ext "$2")
mask=$(remove_ext "$3")
TR=$4
LP=$(echo $5 | cut -d "," -f 1)
HP=$(echo $5 | cut -d "," -f 2)

# checks
if [ ! -f ${input}.nii.gz ] ; then
  echo "`basename $0`: ERROR: file '$input' not found... exiting" ; exit 1
fi
if [ ! -f ${mask}.nii.gz ] ; then
  echo "`basename $0`: ERROR: file '$mask' not found... exiting" ; exit 1
fi

# create working dir.
wdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $wdir/* ; rmdir $wdir ; exit" EXIT

## CALCULATING ALFF AND fALFF
## 1. primary calculations
n_vols=`fslinfo  $input| grep ^dim4 | awk '{print $2}'`
echo "`basename $0`: there are ${n_vols} vols"
## decide whether n_vols is odd or even
MOD=$(echo "${n_vols} % 2" | bc ) ; echo "`basename $0`: Odd (1) or Even (0): ${MOD}"
## if odd, remove the first volume
N=$(echo "scale=0; ${n_vols}/2"|bc) ; N=$(echo "2*${N}"|bc)
if [ ${MOD} -eq 1 ]
then
    echo "`basename $0`: Deleting the first volume from bold data due to a bug in fslpspec"
    fslroi $input $wdir/prealff_func_data.nii.gz 1 ${N}
fi
if [ ${MOD} -eq 0 ]
then
    cp ${input}.nii.gz $wdir/prealff_func_data.nii.gz
fi

## 2. Computing power spectrum
echo "`basename $0`: Computing power spectrum"
fslpspec $wdir/prealff_func_data.nii.gz $wdir/prealff_func_data_ps.nii.gz
## copy power spectrum to keep it for later (i.e. it does not get deleted in the clean up at the end of the script)
cp $wdir/prealff_func_data_ps.nii.gz $(dirname $out)/power_spectrum_distribution.nii.gz
echo "`basename $0`: Computing square root of power spectrum"
fslmaths $wdir/prealff_func_data_ps.nii.gz -sqrt $wdir/prealff_func_data_ps_sqrt.nii.gz

## 3. Calculate ALFF
echo "`basename $0`: Extracting power spectrum at the slow frequency band"
## calculate the low frequency point
n_lp=$(echo "scale=10; ${LP}*${N}*${TR}"|bc)
n1=$(echo "${n_lp}-1"|bc|xargs printf "%1.0f") ; 
echo "`basename $0`: ${LP} Hz is around the ${n1} frequency point."
## calculate the high frequency point
n_hp=$(echo "scale=10; ${HP}*${N}*${TR}"|bc)
n2=$(echo "${n_hp}-${n_lp}+1"|bc|xargs printf "%1.0f") ; 
echo "`basename $0`: There are about ${n2} frequency points before ${HP} Hz."
## cut the low frequency data from the the whole frequency band
fslroi $wdir/prealff_func_data_ps_sqrt.nii.gz $wdir/prealff_func_ps_slow.nii.gz ${n1} ${n2}
## calculate ALFF as the sum of the amplitudes in the low frequency band
echo "`basename $0`: Computing amplitude of the low frequency fluctuations (ALFF)"
fslmaths $wdir/prealff_func_ps_slow.nii.gz -Tmean -mul ${n2} $wdir/prealff_func_ps_alff4slow.nii.gz
imcp $wdir/prealff_func_ps_alff4slow.nii.gz ${out}_ALFF

## 4. Calculate fALFF
echo "`basename $0`: Computing amplitude of total frequency"
fslmaths $wdir/prealff_func_data_ps_sqrt.nii.gz -Tmean -mul ${N} -div 2 $wdir/prealff_func_ps_sum.nii.gz
## calculate fALFF as ALFF/amplitude of total frequency
echo "`basename $0`: Computing fALFF"
fslmaths $wdir/prealff_func_ps_alff4slow.nii.gz -div $wdir/prealff_func_ps_sum.nii.gz ${out}_fALFF.nii.gz

## 5. Z-normalisation across whole brain
echo "`basename $0`: Normalizing ALFF/fALFF to Z-score across full brain"
fslstats ${out}_ALFF -k ${mask}.nii.gz -m > ${out}_mean_ALFF.txt ; mean=$( cat ${out}_mean_ALFF.txt )
fslstats ${out}_ALFF -k ${mask}.nii.gz -s > ${out}_std_ALFF.txt ; std=$( cat ${out}_std_ALFF.txt )
echo "    mean: $mean ; std: $std"
fslmaths ${out}_ALFF.nii.gz -sub ${mean} -div ${std} -mas ${mask}.nii.gz ${out}_ALFF_Z.nii.gz
fslstats ${out}_fALFF.nii.gz -k ${mask}.nii.gz -m > ${out}_mean_fALFF.txt ; mean=$( cat ${out}_mean_fALFF.txt )
fslstats ${out}_fALFF.nii.gz -k ${mask}.nii.gz -s > ${out}_std_fALFF.txt ; std=$( cat ${out}_std_fALFF.txt )
echo "    mean: $mean ; std: $std"
fslmaths ${out}_fALFF.nii.gz -sub ${mean} -div ${std} -mas ${mask}.nii.gz ${out}_fALFF_Z.nii.gz

## 6. Register Z-transformed ALFF and fALFF maps to standard space

## 7. Clean up
echo "`basename $0`: Clean up temporary files"
rm -f $wdir/prealff_*.nii.gz


