#!/bin/bash
# Searches directory tree for significant activation clusters.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 02/01/2013

trap 'echo "$0 : An ERROR has occured."' ERR


Usage() {
    echo ""
    echo "Usage: `basename $0` <atlas:-tbss|-vbm|-ica|-na> <dir> <search-pttrn> <thres> [<sort 0|1>] [<showall 0|1>] [<fslview 0|1>]"
    echo "Example: `basename $0` -vbm ./stats \"*_corrp_*\" 0.95"
    echo "         `basename $0` -ica ./stats \"*_tfce_corrp_*\" -0.95"
    echo "         `basename $0` -na ./stats \"*_corrp_*\" -1"
    echo "         NOTE: sort[0|1]    sort according to p-val (0) or cluster-size (1)."
    echo "               thres=-1     reports only the most significant cluster."
    echo "               thres=-0.95  reports only clusters with p > 0.95."
    echo ""
    exit 1
}

if [ $# -lt 4 ] ; then Usage ; fi

# define input arguments
if [ $(echo $1 | grep ^- | wc -l) -eq 0 ] ; then Usage ; fi
anal=$1
dir=$2
pttrn=$3
thres=$4
if [ -z $5 ] ; then smode=0 ; else smode=$5 ; fi
if [ -z $6 ] ; then showall=0 ; else showall=$6 ; fi
if [ -z $7 ] ; then fslview=0 ; else fslview=$7 ; fi
reportfirst=0
if [ "$thres" = "-1" ] ; then reportfirst=1 ; thres=0.01 ; fi
if [ "$(echo $thres | cut -c 1)" = "-" ] ; then reportfirst=1 ; thres=$(echo $thres | cut -d - -f2) ; fi

# define additional vars
collect=""
logfile="./findClusters.log"
tmpfile="./findClusters.tmp"

# delete temporary files from prev. run
rm -f $logfile ${logfile}.xls
rm -f $tmpfile

# gather input files
files=`find $dir -name "$pttrn" | grep -v SEED | $(dirname $0)/bin/sort8 -V`

# display cluster-information
echo "*** thres > $thres ***" | tee -a $logfile

for f in $files ; do # for each collected file execute 'cluster'
  f=$(remove_ext $f)
  if [ $(imtest $f) -eq 0 ] ; then continue ; fi
  if [ $smode -eq 0 ] ; then
    cluster --in=$f -t $thres --mm  | tail -n+2 | sort -k +3 -r > $tmpfile # sort according to p-value    
  else
    cluster --in=$f -t $thres --mm  | tail -n+2 > $tmpfile # sort according to cluster size    
  fi
  nl=$(cat $tmpfile | wc -l)
  if [ $nl -gt 0 ] ; then
    echo "------------------------------" | tee -a $logfile
    echo "${f}" | tee -a $logfile
    echo "------------------------------" | tee -a $logfile
    collect=$collect" "$f
    for i in `seq 1 $nl` ; do # for each line in 'cluster' output execute atlasquery
      line=$(cat $tmpfile | sed -n ${i}p)
      size="$(echo $line | cut -d " " -f 2)"
      max="$(echo $line | cut -d " " -f 3)"
      x="$(echo $line | cut -d " " -f 4)"
      y="$(echo $line | cut -d " " -f 5)"
      z="$(echo $line | cut -d " " -f 6)"
      max=$(printf '%0.3f' $max)
      tvalfile=$(echo $f | sed "s|_tfce_|_|g" | sed "s|_corrp_|_|g" | sed "s|_p_|_|g" | sed "s|_vox_|_|g")
      
      # query t-value
      if [ $(imtest $tvalfile) -eq 1 ] ; then
        tval=$(fslmeants -i $tvalfile --usemm -c $x $y $z) 2>/dev/null
      else
        tval=-999
      fi
      
      # extract contrast (fstat or tstat) and type of significance (vox or tfce)
      if [ $(echo $f | grep _tstat | wc -l) -eq 1 ] ; then
        n_test=$(zeropad ${f#*tstat} 2)
        stat=tstat${n_test}
      elif [ $(echo $f | grep _fstat | wc -l) -eq 1 ] ; then
        n_test=$(zeropad ${f#*fstat} 2)
        stat=fstat${n_test}
      else
        stat="X"
      fi
      if [ $(echo $f | grep _tfce_ | wc -l) -eq 1 ] ; then
        type=$(echo tfce_${f#*_tfce_} | cut -d _ -f 1-2)
      elif [ $(echo $f | grep _vox_ | wc -l) -eq 1 ] ; then
        type=$(echo vox_${f#*_vox_} | cut -d _ -f 1-2)
      else
        type="X"
      fi
      type1=$(echo $type | cut -d _ -f 1) # tfce or vox
      type2=$(echo $type | cut -d _ -f 2) # corrp or p
      
      # display
      printf '   %5.3f t/f=%4.2f (%5i) at [ %5.1f %5.1f %5.1f ] (mm) \n' $max $tval $size $x $y $z | tee -a $logfile
      if [ $anal = "-tbss" ] ; then
        JHU1=$(atlasquery  -a "JHU ICBM-DTI-81 White-Matter Labels" -c ${x},${y},${z} | cut -d ">" -f 4)
        JHU2=$(atlasquery  -a "JHU White-Matter Tractography Atlas" -c ${x},${y},${z} | cut -d ">" -f 4)        
        printf '\t JHU1: %s\n' "$JHU1" | tee -a $logfile
        printf '\t JHU2: %s\n' "$JHU2" | tee -a $logfile
        printf '%s\t %s\t %s\t %s\t %5.3f\t t/f=%4.2f\t %5i\t [ %5.1f %5.1f %5.1f ]\t %s\t %s \n'           $f $stat $type1 $type2 $max $tval $size $x $y $z "$JHU1" "$JHU2" >> ${logfile}.xls
      elif [ $anal = "-vbm" ] ; then
        HAV1=$(atlasquery  -a "Harvard-Oxford Cortical Structural Atlas" -c ${x},${y},${z} | cut -d ">" -f 4)
        HAV2=$(atlasquery  -a "Harvard-Oxford Subcortical Structural Atlas" -c ${x},${y},${z} | cut -d ">" -f 4)
        TAL=$(atlasquery  -a "Talairach Daemon Labels" -c ${x},${y},${z} | cut -d ">" -f 4)        
        printf '\t TAL:  %s \n' "$TAL" | tee -a $logfile
        printf '\t HAV1: %s \n' "$HAV1" | tee -a $logfile
        printf '\t HAV2: %s \n' "$HAV2" | tee -a $logfile
        printf '%s\t %s\t %s\t %s\t %5.3f\t t/f=%4.2f\t %5i\t [ %5.1f %5.1f %5.1f ]\t %s\t %s\t %s \n'      $f $stat $type1 $type2 $max $tval $size $x $y $z "$HAV1" "$HAV2" "$TAL" >> ${logfile}.xls
      elif [ $anal = "-ica" ] ; then
        ic=$(echo $(basename $f) | grep -o 'ic[[:digit:]]*' | head -n1)
        HAV1=$(atlasquery  -a "Harvard-Oxford Cortical Structural Atlas" -c ${x},${y},${z} | cut -d ">" -f 4)
        HAV2=$(atlasquery  -a "Harvard-Oxford Subcortical Structural Atlas" -c ${x},${y},${z} | cut -d ">" -f 4)
        TAL=$(atlasquery  -a "Talairach Daemon Labels" -c ${x},${y},${z} | cut -d ">" -f 4)        
        printf '\t TAL:  %s \n' "$TAL" | tee -a $logfile
        printf '\t HAV1: %s \n' "$HAV1" | tee -a $logfile
        printf '\t HAV2: %s \n' "$HAV2" | tee -a $logfile
        printf '%s\t %s\t %s\t %s\t %s\t %5.3f\t t/f=%4.2f\t %5i\t [ %5.1f %5.1f %5.1f ]\t %s\t %s\t %s \n' $f $ic $stat $type1 $type2 $max $tval $size $x $y $z "$HAV1" "$HAV2" "$TAL" >> ${logfile}.xls
      else
        if [ $(echo $f | grep /netmat | wc -l) -eq 1 ] ; then
          type=$(echo netmat${f#*/netmat} | cut -d / -f 1)
          netmat=$(echo $type | cut -d _ -f 1)
          tthres=$(echo $type | cut -d _ -f 2)
        else
          netmat="X"
          tthres="X"
        fi
        printf '%s\t %s\t %s\t %s\t %s\t %s\t %5.3f\t t/f=%4.2f\t %5i\t [ %5.1f %5.1f %5.1f ] \n'           $f $netmat $tthres $stat $type1 $type2 $max $tval $size $x $y $z >> ${logfile}.xls
      fi
            
      if [ $reportfirst -eq 1 ] ; then break ; fi
      
    done # end atlasquery loop
  else
    if [ $showall -eq 1 ] ; then
      echo "------------------------------" | tee -a $logfile
      echo "${f}" | tee -a $logfile  
      echo "------------------------------" | tee -a $logfile
    fi
  fi
done # end file loop

# rm temporary files
rm -f $tmpfile

# display section 1
if [ $anal = "-tbss" ] ; then
  if [ $fslview -eq 1 ] ; then
    for f in $collect ; do
      statsdir=$(dirname $f);
      if [ "$statsdir" = "." ] ; then statsdir=".." ; else statsdir=$(dirname $(dirname $f)) ; fi
      res=$(fslinfo $f | grep pixdim1 | awk {'print $2'}) ; res=$(printf '%.0f' $res)
      fslview $statsdir/mean_FA.nii.gz $statsdir/mean_FA_skeleton_mask.nii.gz -l "Blue" -t 0.2 $f -l "Red" -b ${thres},1 
      #fslview ${FSLDIR}/data/standard/MNI152_T1_${res}mm_brain $statsdir/mean_FA_skeleton_mask.nii.gz -l "Blue" -t 0.2 $f -l "Red" -b 0.75,0.9
    done
  fi
fi

# display section 2
if [ $anal = "-vbm" ] ; then
  if [ $fslview -eq 1 ] ; then
    for f in $collect ; do
      statsdir=$(dirname $f);
      if [ "$statsdir" = "." ] ; then statsdir=".." ; else statsdir=$(dirname $(dirname $f)) ; fi
      res=$(fslinfo $f | grep pixdim1 | awk {'print $2'}) ; res=$(printf '%.0f' $res)
      fslview $statsdir/mean_GM_mod_merg_smoothed.nii.gz $f -l "Red" -b ${thres},1     
    done
  fi
fi

# display section 3
if [ $anal = "-ica" ] ; then
  if [ $fslview -eq 1 ] ; then
    for f in $collect ; do
      # check if size / resolution matches
      MNItemplates="${FSLDIR}/data/standard/MNI152_T1_4mm_brain ${FSLDIR}/data/standard/MNI152_T1_2mm_brain"
      for MNI in $MNItemplates ; do        
        fslmeants -i $f -m $MNI &>/dev/null
        if [ $? -gt 0 ] ; then 
          echo "$(basename $0) : WARNING : size / resolution does not match btw. '$f' and '$MNI' (ignore error above) - continuing loop..."
          continue
        else
          if [ $(echo $MNI | grep _4mm_ | wc -l) -eq 1 ] ; then rsn=${FSLDIR}/data/standard/rsn10_CSFWM_4mm.nii.gz ; fi
          if [ $(echo $MNI | grep _2mm_ | wc -l) -eq 1 ] ; then rsn=${FSLDIR}/data/standard/rsn10_CSFWM_2mm.nii.gz ; fi
          fslview $MNI $rsn -t 0 -l "Blue-Lightblue" -b 1,2.1372 $f -l "Red" -b ${thres},1 -t 1
          break
        fi        
      done # end MNI    
    done # end f
  fi
fi

echo "`basename $0`: done."



