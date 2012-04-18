
#!/bin/bash
# The FEAT way of making the mask.

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <4dinput> <output> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage
data=`remove_ext "$1"`
out=`remove_ext "$2"`
subj="$3"  # optional
sess="$4"  # optional

echo "`basename $0`: subj $subj , sess $sess : generating mask for $data -> $out..." 

echo "`basename $0`: subj $subj , sess $sess :    generating `basename ${out}_mean_func`..." 
fslmaths ${data} -Tmean ${out}_mean_func

echo "`basename $0`: subj $subj , sess $sess :    betting `basename ${out}_mean_func` -> `basename ${out}`..."
bet2 ${out}_mean_func ${out} -f 0.3 -n -m ; immv ${out}_mask ${out}

echo "`basename $0`: subj $subj , sess $sess :    masking `basename ${data}` -> `basename ${out}_bet`..."
fslmaths ${data} -mas ${out} ${out}_bet
range=`fslstats ${out}_bet -p 2 -p 98`
int2=$(echo $range | cut -d " " -f 1)
int98=$(echo $range | cut -d " " -f 2) 
brain_thres=10
intensity_threshold=$(echo "scale=10; $int2 + ( ( $int98 - $int2 ) / 100.0 * $brain_thres )" | bc -l)
echo "`basename $0`: subj $subj , sess $sess :    -> p2:  $int2"
echo "`basename $0`: subj $subj , sess $sess :    -> p98: $int98"
echo "`basename $0`: subj $subj , sess $sess :    -> intensity threshold: $intensity_threshold"

echo "`basename $0`: subj $subj , sess $sess :    thresholding `basename ${out}_bet` with $intensity_threshold -> `basename ${out}`..."
fslmaths ${out}_bet -thr $intensity_threshold -Tmin -bin ${out} -odt char
median_intensity=`fslstats ${data} -k ${out} -p 50`
susan_int=$(echo "scale=10; ($median_intensity - $int2) * 0.75" | bc -l )
echo "`basename $0`: subj $subj , sess $sess :    -> median: $median_intensity"
echo "`basename $0`: subj $subj , sess $sess :    -> brightness threshold (susan_int): $susan_int"

echo "`basename $0`: subj $subj , sess $sess :    dilating `basename ${out}`..."
fslmaths ${out} -dilF ${out}

# cleanup
echo "`basename $0`: subj $subj , sess $sess :    cleanup..."
imrm ${out}_bet ${out}_mean_func

echo "$int2 $int98 $intensity_threshold $median_intensity $susan_int" > ${out}_vals


