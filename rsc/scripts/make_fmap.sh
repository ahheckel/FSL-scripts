#!/bin/bash
# make fieldmap

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <magn> <deltaphase> <deltaTEphase> <fi-thresh> <output> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$5" = "" ] && Usage
fm_m=`remove_ext "$1"`
fm_p=`remove_ext "$2"`
deltaTEphase="$3"
f="$4"
out=`remove_ext "$5"`
subj="$6"  # optional
sess="$7"  # optional

outdir=`dirname $out`
PI=$(echo "scale=10; 4*a(1)" | bc -l) # define pi

# FIELDMAP prepare
# split magnitude
echo "`basename $0` : subj $subj , sess $sess : extracting magnitude image ${fm_m}..."
fslroi $fm_m $outdir/magn 0 1 # extract first of the two magnitude images

echo "`basename $0` : subj $subj , sess $sess : betting magnitude image with fi=${f}..."
bet $outdir/magn $outdir/magn_brain -m -f $f

# define stats for the phase image
range=`fslstats $fm_p -R` 
min=`echo $range | cut -d " " -f1`
max=`echo $range | cut -d " " -f2`
add=$(echo "-($min + $max)/2" | bc -l)
div=$(echo "$max + $add" | bc -l)

# display info
printf "`basename $0` : subj $subj , sess $sess : phase image $fm_p - info: min: %.2f max: %.2f add: %.2f div: %.2f pi: %.5f \n" $min $max $add $div $PI

# erode by one voxel (default kernel 3x3x3)
echo "`basename $0` : subj $subj , sess $sess : eroding brain mask a bit..."
fslmaths $outdir/magn_brain_mask -ero $outdir/magn_brain_mask_ero

# scale to -pi ... +pi
fslmaths $fm_p -add $add -div $div -mul $PI $outdir/phase_rad -odt float
echo "`basename $0` : subj $subj , sess $sess : phase image is scaled to `fslstats $outdir/phase_rad -R`"

# unwrap
echo "`basename $0` : subj $subj , sess $sess : unwrapping phase image..."
prelude -p $outdir/phase_rad -m $outdir/magn_brain_mask_ero -a $outdir/magn_brain -o $outdir/uphase_rad

# divide by echo time difference
echo "`basename $0` : subj $subj , sess $sess : normalizing phase image to dTE (${deltaTEphase}) and centering to median (P50)..."
fslmaths $outdir/uphase_rad -div $deltaTEphase $outdir/fmap_rads
# center to median
p50=`fslstats $outdir/fmap_rads -k $outdir/magn_brain_mask_ero -P 50`
echo "`basename $0` : subj $subj , sess $sess : P50: $p50"
fslmaths $outdir/fmap_rads -sub $p50 -mas $outdir/magn_brain_mask_ero $out

# jetzt noch swi ohne swi:
# smooth with gauss kernel of s=xx mm and subtract to get filtered image
fslmaths $outdir/uphase_rad -s 10 $outdir/uphase_rad_s10 
fslmaths $outdir/uphase_rad -sub $outdir/uphase_rad_s10 $outdir/uphase_rad_filt 

echo "`basename $0` : subj $subj , sess $sess : done."
