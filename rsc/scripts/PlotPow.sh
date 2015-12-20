#!/bin/bash
#
# Script by T. Nichols. 
# [Slightly modified by A. Heckel (HKL 25/11/2012) to process 1x1x1xN pseudoimages (e.g. columns in motion parameter files), allow for arbitrary high-pass filter cutoffs and maximum y-value in final plot]
#
# Script:   PlotPow.sh
# Purpose:  Plot the average powerspectrum over voxels
# Author:   T. Nichols
# Version: $Id: PlotPow.sh,v 1.4 2012/03/26 18:51:52 nichols Exp $
#


###############################################################################
#
# Environment set up
#
###############################################################################

shopt -s nullglob # No-match globbing expands to null
TmpDir=/tmp
Tmp=$TmpDir/`basename $0`-${$}-
trap CleanUp INT
export LC_ALL=C # added by HKL
###############################################################################
#
# Functions
#
###############################################################################

Usage() {
cat <<EOF
Usage: `basename $0` [options] 4Dimage mask PlotNm

Within mask voxels, computes power spectrum at each point in 4Dimage, creating a
plot in file PlotNm.png.  Image is always demeaned before computing the powerspectrum; 
it can optionally be variance-standardized over space (see -std below)

If mask is an integer, it is take to be the threshold applied to the mean image used
to create a mask.

Options
   -std                  Standardize each voxel to have unit variance first.
   -tr <tr>              Specify TR, so plots have units of Hz instead of 1/TR
   -detrend              Remove linear trends from each voxel
   -highpass <cutoff>    Apply FEAT high pass filtering (TR must be set) 
   -mult <factor>        Multiply powerspectrum with scalar value
   -ymax <scalar>        Maximum y-value
_________________________________________________________________________
\$Id: PlotPow.sh,v 1.4 2012/03/26 18:51:52 nichols Exp $
EOF
exit
}

CleanUp () {
    /bin/rm -f ${Tmp}*
    exit 0
}

# begin HKL
function minmaxavg() # NB: min / max values are clamped to whole numbers
{
  awk 'NR == 1 { max=$1; min=$1; sum=0 }
  { if ($1>max) max=$1; if ($1<min) min=$1; sum+=$1;}
  END {printf "%f:%f:%f\n", min, max, sum/NR}'
}

function getMin() # finds minimum in column
{
  minmaxavg | cut -d ":" -f 1 
}

function getMax() # finds maximum in column
{
  minmaxavg | cut -d ":" -f 2 
}
# end HKL

###############################################################################
#
# Parse arguments
#
###############################################################################

TR=1
Units=""
mult=1
ymax=""
while (( $# > 1 )) ; do
    case "$1" in
        "-help")
            Usage
            ;;
        "-std")
            shift
            VarNorm=1
            ;;
        "-tr")
            shift
            TR="$1"
	    Units=" (Hz)"
	    shift
            ;;
        "-detrend")
            shift
            Detrend=1
            ;;
        "-highpass")
            shift
            HighPass=1
            hpf=$1 # added by HKL
            shift # added by HKL
            ;;
        "-mult") # added by HKL
            shift # added by HKL
            mult=$1 # added by HKL
            shift # added by HKL
            ;; # added by HKL
        "-ymax") # added by HKL
            shift # added by HKL
            ymax="--ymax=$1" # added by HKL
            shift # added by HKL
            ;; # added by HKL
        -*)
            echo "ERROR: Unknown option '$1'"
            exit 1
            break
            ;;
        *)
            break
            ;;
    esac
done
Tmp=$TmpDir/f2r-${$}-

if (( $# < 1 || $# > 3 )) ; then
    Usage
fi

Img="$1"
Mask="$2"
Plot="$3"
Nvol=$(fslnvols "$Img")

###############################################################################
#
# Script Body
#
###############################################################################

# Compute mean
fslmaths "$Img" -Tmean $Tmp-mean -odt float
# added by HKL
xdim=$(fslinfo "$Img" | grep ^dim1 | cut -d " " -f 2-)
ydim=$(fslinfo "$Img" | grep ^dim2 | cut -d " " -f 2-)
zdim=$(fslinfo "$Img" | grep ^dim3 | cut -d " " -f 2-)
# end HKL

# Create a mask on the fly?
if [[ "$Mask" =~ ^[0-9]*$ ]] ; then
    fslmaths "$Img" -thr "$Mask" -bin $Tmp-mask
    Mask=$Tmp-mask
fi

# Detrend ?
if [ "$Detrend" = "1" ] ; then
    touch $Tmp-reg
    for ((i=1;i<=Nvol;i++)) ; do 
	echo $i >> $Tmp-reg
    done
    fsl_glm -i "$Img" -d $Tmp-reg --out_res=$Tmp-Detrend -m $Mask --demean
    Img=$Tmp-Detrend
fi

# High pass?
if [ "$HighPass" = "1" ] ; then
    addmean="" # added by HKL
    version=$(cat $FSLDIR/etc/fslversion); echo $version > /tmp/version ; echo "5.0.7" >> /tmp/version # added by HKL
    if [ $(cat /tmp/version | $(dirname $0)/bin/sort8 -V | head -n 1) = 5.0.7 ] ; then isnew=1 ; else isnew=0 ; fi # added by HKL
    HPsigma=$(echo ${hpf}/2/$TR | bc -l)    
    if [ $isnew -eq 1 ] ; then # added by HKL
      fslmaths "$Img" -Tmean /tmp/mean-tmp
      addmean="-add /tmp/mean-tmp"
    fi
    cmd="fslmaths $Img -bptf $HPsigma -1 $addmean $Tmp-HPf" ; echo $cmd ; $cmd
    Img=$Tmp-HPf
    if [ $isnew -eq 1 ] ; then # added by HKL
      imrm /tmp/mean-tmp
      rm -f /tmp/version
    fi
fi

# Center and possibly variance normalize 
if [ "$VolNorm" = "1" ] ; then
    fslmaths "$Img" -Tstd $Tmp-sd -odt float
    fslmaths "$Img" -sub $Tmp-mean -div $Tmp-sd -mas "$Mask" $Tmp-img -odt float 
else
    fslmaths "$Img" -sub $Tmp-mean              -mas "$Mask" $Tmp-img -odt float 
fi

# Compute power spectrum... the slow part
fslpspec $Tmp-img  $Tmp-pspec

# Make the plot
# added by HKL
if [ $xdim = 1 -a $ydim = 1 -a $zdim = 1 ] ; then
  fslmeants -i $Tmp-pspec -o "$Plot".txt # due to some bug (?)
else
  fslmeants -i $Tmp-pspec -m $Tmp-mean -o "$Plot".txt
fi # end HKL
Len=$(cat "$Plot".txt | wc -l )
Nyq=$(echo "0.5/$TR/$Len" | bc -l);
$(dirname $0)/textcalc.sh "$Plot".txt "c*${mult}" "$Plot".txt # added by HKL
#ymax=$(cat "$Plot".txt | minmaxavg | getMax) # added by HKL
#ymin=$(cat "$Plot".txt | minmaxavg | getMin) # added by HKL
fsl_tsplot -i "$Plot".txt -u $Nyq -y "Power*${mult}" -x "Frequency$Units" $ymax -o "$Plot".png # adapted by HKL
#fsl_tsplot -i "$Plot".txt -u $Nyq -y "Power*${mult}" --ymin=$ymin --ymax=$ymax -x "Frequency$Units" -o "$Plot".png # adapted by HKL

###############################################################################
#
# Exit & Clean up
#
###############################################################################

CleanUp
