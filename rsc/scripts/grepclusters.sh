#!/bin/bash
# Finds significant activation clusters in directory tree.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

trap 'echo "$0 : An ERROR has occured."' ERR


Usage() {
    echo ""
    echo "Usage: `basename $0` <atlas:-tbss|-vbm> <dir> <search-pttrn> <thres> <fslview 1|0>"
    echo "Example: `basename $0` -vbm ./stats \"*_corrp_*\" 0.95 1"
    echo "         `basename $0` -vbm ./stats \"*_tfce_corrp_*\" -1"
    echo "         NOTE: thres=-1 reports only the most significant result."
    echo ""
    exit 1
}

if [ $# -lt 4 ] ; then Usage ; fi
if [ $(echo $1 | grep ^- | wc -l) -eq 0 ] ; then Usage ; fi
anal=$1
dir=$2
pttrn=$3
thres=$4
if [ -z $5 ] ; then fslview=0 ; else fslview=$5 ; fi
if [ "$thres" = "-1" ] ; then reportfirst=1 ; thres=0.01 ; else reportfirst=0 ; fi

collect=""
logfile="./findClusters.log"
tmpfile="./findClusters.tmp"

rm -f $logfile
rm -f $tmpfile

files=`find $dir -name "$pttrn" | grep -v SEED | $(dirname $0)/bin/sort8 -V`

echo "*** thres > $thres ***" | tee -a $logfile

for f in $files ; do 
  cluster --in=$f -t $thres --mm > $tmpfile
  nl=$(cat $tmpfile | wc -l)
  if [ $nl -gt 1 ] ; then
    echo "------------------------------" | tee -a $logfile
    echo "${f}" | tee -a $logfile
    echo "------------------------------" | tee -a $logfile
    collect=$collect" "$f
    for i in `seq 2 $nl` ; do
      line=$(cat $tmpfile | sed -n ${i}p)
      size="$(echo $line | cut -d " " -f 2)"
      max="$(echo $line | cut -d " " -f 3)"
      x="$(echo $line | cut -d " " -f 4)"
      y="$(echo $line | cut -d " " -f 5)"
      z="$(echo $line | cut -d " " -f 6)"
      
      max=$(printf '%0.3f' $max)
      #tval=$(fslmeants -i $(echo $f | sed "s|tfce_||g" | sed "s|corrp_||g" | sed "s|p_||g" | sed "s|vox_||g") --usemm -c $x $y $z) # query t-value
      tval=$(fslmeants -i $(echo $f | sed "s|_tfce_|_|g" | sed "s|_corrp_|_|g" | sed "s|_p_|_|g" | sed "s|_vox_|_|g") --usemm -c $x $y $z) # query t-value
      
      if [ $anal = "-tbss" ] ; then
        JHU1=$(atlasquery  -a "JHU ICBM-DTI-81 White-Matter Labels" -c ${x},${y},${z} | cut -d ">" -f 4)
        JHU2=$(atlasquery  -a "JHU White-Matter Tractography Atlas" -c ${x},${y},${z} | cut -d ">" -f 4)      
        printf '   %5.3f t/f=%4.2f (%5i) at [ %5.1f %5.1f %5.1f ] (mm) \n' $max $tval $size $x $y $z | tee -a $logfile
        printf '\t JHU1: %s\n' "$JHU1" | tee -a $logfile
        printf '\t JHU2: %s\n' "$JHU2" | tee -a $logfile
      fi
      if [ $anal = "-vbm" ] ; then
        HAV1=$(atlasquery  -a "Harvard-Oxford Cortical Structural Atlas" -c ${x},${y},${z} | cut -d ">" -f 4)
        HAV2=$(atlasquery  -a "Harvard-Oxford Subcortical Structural Atlas" -c ${x},${y},${z} | cut -d ">" -f 4)
        TAL=$(atlasquery  -a "Talairach Daemon Labels" -c ${x},${y},${z} | cut -d ">" -f 4)
        printf '   %5.3f t/f=%4.2f (%5i) at [ %5.1f %5.1f %5.1f ] (mm) \n' $max $tval $size $x $y $z | tee -a $logfile
        printf '\t TAL:  %s \n' "$TAL" | tee -a $logfile
        printf '\t HAV1: %s \n' "$HAV1" | tee -a $logfile
        printf '\t HAV2: %s \n' "$HAV2" | tee -a $logfile
      fi
      
      if [ $reportfirst -eq 1 ] ; then break ; fi
      
    done
  else
    echo "------------------------------" | tee -a $logfile
    echo "${f}" | tee -a $logfile  
    echo "------------------------------" | tee -a $logfile
  fi
done

rm -f $tmpfile

if [ $anal = "-tbss" ] ; then
  if [ $fslview -eq 1 ] ; then
    for f in $collect ; do
      statsdir=$(dirname $f);
      if [ "$statsdir" = "." ] ; then statsdir=".." ; else statsdir=$(dirname $(dirname $f)) ; fi
      res=$(fslinfo $f | grep pixdim1 | awk {'print $2'}) ; res=$(printf '%.0f' $res)
      fslview $statsdir/mean_FA.nii.gz $statsdir/mean_FA_skeleton_mask.nii.gz -l "Blue" -t 0.2 $f -l "Red" -b 0.75,0.9
      #fslview ${FSLDIR}/data/standard/MNI152_T1_${res}mm_brain $statsdir/mean_FA_skeleton_mask.nii.gz -l "Blue" -t 0.2 $f -l "Red" -b 0.75,0.9
    done
  fi
fi

if [ $anal = "-vbm" ] ; then
  if [ $fslview -eq 1 ] ; then
    for f in $collect ; do
      statsdir=$(dirname $f);
      if [ "$statsdir" = "." ] ; then statsdir=".." ; else statsdir=$(dirname $(dirname $f)) ; fi
      res=$(fslinfo $f | grep pixdim1 | awk {'print $2'}) ; res=$(printf '%.0f' $res)
      fslview $statsdir/mean_GM_mod_merg_smoothed.nii.gz $f -l "Red" -b 0.75,0.9
    done
  fi
fi

echo "`basename $0`: done."



