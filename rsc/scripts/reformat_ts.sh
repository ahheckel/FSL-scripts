#!/bin/bash
# Reformats fslmeants output for within subjects ROI analysis (1 col. per condition / 1 col. per subject).

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 02/25/2013

trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR

set -e

function minmaxavg() # NB: min / max values are clamped to whole numbers
{
  awk 'NR == 1 { max=$1; min=$1; sum=0 }
  { if ($1>max) max=$1; if ($1<min) min=$1; sum+=$1;}
  END {printf "%d:%d:%f\n", min, max, sum/NR}'
}

function getAvg() # averages column
{
  minmaxavg | cut -d ":" -f 3
}

Usage() {
    echo ""
    echo "Usage:   `basename $0` [-m] <txt_input> <increment> <txt_output> [order:1(=def.)|2]"
    echo "Options: -m     displays mean for each column"
    echo ""
    echo "       order 1: Assumption is that the 4D input to fslmeants was in the order:"
    echo "                 subj01condA.nii.gz"
    echo "                 subj01condB.nii.gz"
    echo "                 ..."
    echo "                 subj02condA.nii.gz"
    echo "                 ..."
    echo "       order 2: Assumption is that the 4D input to fslmeants was in the order:"
    echo "                 subj01condA.nii.gz"
    echo "                 subj02condA.nii.gz"
    echo "                 ..."
    echo "                 subj01condB.nii.gz"
    echo "                 ..."
    echo ""
    echo "Example: `basename $0` meants.txt 3 meants3col"
    echo ""
    exit 1
}

# arguments 
if [ "$1" = "-m" ] ; then mean=1 ; shift ; else mean=0 ; fi
[ "$3" = "" ] && Usage
txtin="$1"
ncond="$2"
txtout="$3"
order="$4" ; if [ x${order} = "x" ] ; then order=1 ; fi

# consistency check
rois=$(awk '{print NF}' $txtin | sort -nu | head -n 1) # count number of columns
nvols=$(cat $txtin  | wc -l) # number of values (volumes)
reps=$(echo "scale=0 ; $nvols / $ncond" | bc -l) # number of repeats (=subjects)
check=$(echo "scale=0 ; $ncond * $reps" | bc -l) # gehts auf ?
if [ $check -ne $nvols ] ; then echo "`basename $0`: ERROR : number of volumes $nvols != ${reps}*${ncond}. Exiting." ; exit 1 ; fi

# re-format...
for roi in `seq 1 $rois` ; do
  txtfiles=""
  # re-format textfile: subjects first
  if [ $order -eq 1 ] ; then
    for i in `seq 1 $ncond` ; do
      rm -f ${txtout}_tmp_${i}
      for j in `seq 1 $reps` ; do
        
        line=$(echo "scale=0 ; $i + $ncond * ($j-1)" | bc -l)
        cat $txtin | sed -n ${line}p >> ${txtout}_tmp_${i}
        
      done
      txtfiles=$txtfiles" "${txtout}_tmp_${i}
      if [ $mean -eq 1 ] ; then
        cat ${txtout}_tmp_${i} | getAvg  > ${txtout}_tmp_mean_${i}
        cat ${txtout}_tmp_mean_${i} > ${txtout}_tmp_${i}
      fi
    done
  fi
  
  # re-format textfile: conditions first
  if [ $order -eq 2 ] ; then
    for i in `seq 1 $reps` ; do
      rm -f ${txtout}_tmp_${i}
      for j in `seq 1 $ncond` ; do
        
        line=$(echo "scale=0 ; $j + $ncond * ($i-1)" | bc -l)
        cat $txtin | sed -n ${line}p >> ${txtout}_tmp_${i}
        
      done
      txtfiles=$txtfiles" "${txtout}_tmp_${i}
      if [ $mean -eq 1 ] ; then
        cat ${txtout}_tmp_${i} | getAvg  > ${txtout}_tmp_mean_${i}
        cat ${txtout}_tmp_mean_${i} > ${txtout}_tmp_${i}
      fi
    done  
  fi

  # paste
  paste $txtfiles > ${txtout}_$(zeropad $roi 3)
  

  # cleanup
  rm $txtfiles
done

# display result
for roi in `seq 1 $rois` ; do
  echo "${txtout}_$(zeropad $roi 3): "
  cat ${txtout}_$(zeropad $roi 3)
done
