
#!/bin/bash
# The FEAT way of high pass filtering.

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <4dinput> <output> <hpf> <TR> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage
data=`remove_ext "$1"`
out=`remove_ext "$2"`
hpf="$3"
TR="$4"
subj="$5"  # optional
sess="$6"  # optional

hp_sigma_sec=$(echo "scale=10; $hpf / 2.0" | bc -l)
hp_sigma_vol=$(echo "scale=10; $hp_sigma_sec / $TR" | bc -l)
echo "`basename $0`: highpass temporal filtering of ${data} (Gaussian-weighted least-squares straight line fitting, with sigma=${hp_sigma_sec}s)..."
fslmaths $data -bptf $hp_sigma_vol -1 ${out}
