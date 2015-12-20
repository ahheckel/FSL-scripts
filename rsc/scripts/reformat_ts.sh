#!/bin/bash
# Reformats fslmeants output for within subjects ROI analysis (1 col. per condition / 1 col. per subject) for ANOVA.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 09/21/2014

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

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# additional vars
txtin_tmp=$tmpdir/txtin.txt
header_tmp=$tmpdir/header.txt

# remove blanks and text header
istext=1 ; iscomment=1
cat $txtin | sed '/^$/d' | grep -v ^[[:blank:]] > $txtin_tmp
for i in `seq 1 $(cat $txtin_tmp | wc -l)` ; do
  istext=$(sed -n ${i}p $txtin_tmp | grep "[[:alpha:]]" | wc -l)
  iscomment=$(sed -n ${i}p $txtin_tmp | grep ^# | wc -l)
  if [ $istext -eq 0 -a $iscomment -eq 0 ] ; then break ; fi
done
j=$[$i-1]
if [ $j -gt 0 ] ; then head -n${j} $txtin_tmp > $header_tmp ; else touch $header_tmp ; fi
tail -n+${i} $txtin_tmp > $tmpdir/_txtin.txt ; mv $tmpdir/_txtin.txt $txtin_tmp
echo "`basename $0`: discarding ${j} header lines"
i="" ; j=""

# consistency check
rois=$(awk '{print NF}' $txtin_tmp | sort -nu | head -n 1) # count number of columns
nvols=$(cat $txtin_tmp  | wc -l) # number of values (volumes)
reps=$(echo "scale=0 ; $nvols / $ncond" | bc -l) # number of repeats (=subjects)
check=$(echo "scale=0 ; $ncond * $reps" | bc -l) # gehts auf ?
if [ $check -ne $nvols ] ; then echo "`basename $0`: ERROR : number of volumes $nvols != ${reps}*${ncond}. Exiting." ; exit 1 ; fi
echo "`basename $0`: '$txtin' has $nvols lines and $rois columns."

# shall we use headings ?
useheading=0
heading=$(tail -n 1 $header_tmp)
heading_col=$(echo $heading | wc -w)
if [ $rois -eq $heading_col ] ; then
  echo "`basename $0`: using heading:"
  echo "$heading"
  useheading=1
fi

# re-format...
roifiles=""
for roi in `seq 1 $rois` ; do
  txtfiles=""
  # re-format textfile: subjects first
  if [ $order -eq 1 ] ; then
    for i in `seq 1 $ncond` ; do
      rm -f ${txtout}_tmp_${i}
      for j in `seq 1 $reps` ; do
        
        line=$(echo "scale=0 ; $i + $ncond * ($j-1)" | bc -l)
        cat $txtin_tmp | awk -v c=${roi} '{print $c}' | sed -n ${line}p >> ${txtout}_tmp_${i}
        
      done
      if [ $mean -eq 1 ] ; then
        cat ${txtout}_tmp_${i} | getAvg  > ${txtout}_tmp_mean_${i}
        cat ${txtout}_tmp_mean_${i} > ${txtout}_tmp_${i}
        rm ${txtout}_tmp_mean_${i}
      fi
      if [ $useheading -eq 1 ] ; then
        _heading=$(echo $heading | awk -v c=${roi} '{print $c}')
        sed -i "1i $_heading" ${txtout}_tmp_${i}
      fi
      txtfiles=$txtfiles" "${txtout}_tmp_${i}
    done
  fi
  
  # re-format textfile: conditions first
  if [ $order -eq 2 ] ; then
    for i in `seq 1 $reps` ; do
      rm -f ${txtout}_tmp_${i}
      for j in `seq 1 $ncond` ; do
        
        line=$(echo "scale=0 ; $j + $ncond * ($i-1)" | bc -l)
        cat $txtin_tmp | awk -v c=${roi} '{print $c}' | sed -n ${line}p >> ${txtout}_tmp_${i}
        
      done
      if [ $mean -eq 1 ] ; then
        cat ${txtout}_tmp_${i} | getAvg  > ${txtout}_tmp_mean_${i}
        cat ${txtout}_tmp_mean_${i} > ${txtout}_tmp_${i}
        rm ${txtout}_tmp_mean_${i}
      fi
      if [ $useheading -eq 1 ] ; then
        _heading=$(echo $heading | awk -v c=${roi} '{print $c}')
        sed -i "1i $_heading" ${txtout}_tmp_${i}
      fi
      txtfiles=$txtfiles" "${txtout}_tmp_${i}
    done  
  fi

  # paste
  paste $txtfiles > ${txtout}_$(zeropad $roi 3)
  roifiles=$roifiles" "${txtout}_$(zeropad $roi 3)

  # cleanup
  rm $txtfiles
done

paste $roifiles > ${txtout}

# display result
for roi in `seq 1 $rois` ; do
  echo "${txtout}_$(zeropad $roi 3): "
  cat ${txtout}_$(zeropad $roi 3)
done

# cleanup
rm $roifiles
rm $txtin_tmp
rm $header_tmp
