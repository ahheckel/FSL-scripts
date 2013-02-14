#!/bin/bash
# Applies EDDY (FSL v5) to a TOPUP directory, which was created with topup.sh.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 02/14/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

function row2col()
{
  local dat=`cat $1`
  local i=""
  for i in $dat ; do echo $i ; done
}

function minmaxavg() # NB: min / max values are clamped to whole numbers
{
  awk 'NR == 1 { max=$1; min=$1; sum=0 }
  { if ($1>max) max=$1; if ($1<min) min=$1; sum+=$1;}
  END {printf "%d:%d:%f\n", min, max, sum/NR}'
}

function getMin() # finds minimum in column
{
  minmaxavg | cut -d ":" -f 1 
}

function getIdx() 
{
  local i=0;
  local vals=`cat $1` ; local val=""
  local target=$2

  for val in $vals ; do
    if test $val -eq $target ; then
      echo "$i"
    fi
    i=$[$i+1]
  done
}

Usage() {
    echo ""
    echo "Usage: `basename $0` <topup-directory> <output-name>"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage

fldr="$1"
out=$(remove_ext $2)
wd="`pwd`"

# check version of FSL
fslversion=$(cat $FSLDIR/etc/fslversion | cut -d . -f 1)
if [ $fslversion -lt 5 ] ; then echo "`basename $0`: ERROR : 'eddy' only works in FSL >= 5 ! (FSL $(cat $FSLDIR/etc/fslversion) was detected.)  Exiting." ; exit 1 ; fi

# even number of volumes in merged DWI ?
nvols=$(fslinfo  ${out}  | grep ^dim4 | awk '{print $2}')
incr=$(echo "scale=0 ; $nvols/2" | bc -l)
check=$(echo "scale=0 ; $incr + $incr" | bc -l)
if [ $check -ne $nvols ] ; then echo "`basename $0`:  ERROR : unequal number of volumes in '${out}' ! Exiting." ; exit 1 ; fi

# concatenate bvals/bvecs (minus first)
paste -d " " $fldr/bvals-_concat.txt $fldr/bvals+_concat.txt > $fldr/eddy_bvals_concat.txt
paste -d " " $fldr/bvecs-_concat.txt $fldr/bvecs+_concat.txt > $fldr/eddy_bvecs_concat.txt

## get appropriate line in TOPUP low-b index file (containing parameters pertaining to the B0 images)
## referring to the b0 image adjacent to each dwi block.
#min=`row2col $fldr/eddy_bvals_concat.txt | getMin` # min value
#b0idces=`getIdx $fldr/eddy_bvals_concat.txt $min` # index of b0 images
#firstb0idx=$(echo $b0idces | cut -d " " -f 1)
## creating eddy_index.txt
#if [ $firstb0idx -eq 0 ] ; then k=0 ; b0first=1 ; else k=1 ; b0first=0 ; fi
#N=$(cat $fldr/eddy_bvals_concat.txt | wc -w)
#for i in `seq 1 $N` ; do
  #i_idx=$(echo "$i - 1" | bc)
  #if [ $b0first -eq 0 ] ; then indexlist=$indexlist" "$k ; fi
  #for b0idx in $b0idces ; do
    #if [ $i_idx -eq $b0idx ] ; then k=$[$k+1] ; break ; fi
  #done
  #if [ $b0first -eq 1 ] ; then indexlist=$indexlist" "$k ; fi
#done
#echo $indexlist > $fldr/eddy_index.txt

# get appropriate line in TOPUP low-b index file (containing parameters pertaining to the B0 images), 
# i.e. that line that refers to the first b0 volume in each DWI input file.
line_b0=1 ; j=0 ; lines_b0p=""; lines_b0m=""
for i in $(cat $fldr/bval-.files) ; do
  if [ $j -gt 0 ] ; then
    line_b0=$(echo "scale=0; $line_b0 + $nb0" | bc -l)
  fi
  min=`row2col $i | getMin`
  nb0=$(echo `getIdx $i $min` | wc -w)
  lines_b0m=$lines_b0m" "$line_b0
  j=$[$j+1]
done      
for i in $(cat $fldr/bval+.files) ; do
  line_b0=$(echo "scale=0; $line_b0 + $nb0" | bc -l)
  min=`row2col $i | getMin`
  nb0=$(echo `getIdx $i $min` | wc -w)
  lines_b0p=$lines_b0p" "$line_b0
done ; j=""
lines_b0="$lines_b0m $lines_b0p"
# create eddy_index text file
N=$(for i in `seq 1 $(cat $fldr/diff.files | wc -l)` ; do cat $fldr/diff.files | sed -n ${i}p | cut -d : -f 2 ; done) # in diff.files: minus files must be listed before plus files ! (!)
indexlist=$(k=1 ; for i in $N ; do for j in `seq 1 $i` ; do echo $lines_b0 | cut -d " " -f $k ; done ; k=$[$k+1] ;  done)
echo $indexlist > $fldr/eddy_index.txt

# display eddy_index file
echo "`basename $0`: content of file 'eddy_index.txt' (N=$(cat $fldr/eddy_index.txt | wc -w), min:$min) is:"
cat $fldr/eddy_index.txt

# change to TOPUP directory
cd $fldr
  
  # bet unwarped b0 and create mask
  echo "`basename $0`: betting unwarped lowb image:"
  cmd="bet fm/uw_lowb_merged_chk fm/uw_lowb_merged_chk_brain -f 0.3 -m"
  echo "    $cmd" ; $cmd
  
  # define variables
  bvecs=eddy_bvecs_concat.txt
  bvals=eddy_bvals_concat.txt
  dwi=diffs_merged.nii.gz
  #mask=uw_nodif_brain_mask.nii.gz
  mask=fm/uw_lowb_merged_chk_brain_mask.nii.gz
  acqp=$(ls *_acqparam_lowb.txt)
  topup_basename=$(ls *_movpar.txt)
  topup_basename=$(echo ${topup_basename%_mov*})
  eddy_index=eddy_index.txt

  # display info
  echo ""
  echo "`basename $0`: bvals          : $bvals"
  echo "`basename $0`: bvecs          : $bvecs"
  echo "`basename $0`: dwi            : $dwi"
  echo "`basename $0`: mask           : $mask"
  echo "`basename $0`: acqp           : $acqp"
  echo "`basename $0`: topup_basename : $topup_basename"
  echo "`basename $0`: eddy_index     : $eddy_index"
  echo ""

  # execute eddy...
  echo "`basename $0`: executing eddy:"
  cmd="eddy --imain=${dwi} --mask=${mask} --bvecs=${bvecs} --bvals=${bvals} --out=${out} --acqp=${acqp} --topup=${topup_basename} --index=${eddy_index} --fwhm=0 -v"
  echo "    $cmd" ; $cmd
  
  # pairwise averaging
  echo "`basename $0`: pairwise averaging within 4D ('${out}', $nvols volumes, increment: $incr)..."  
  cmd="fslroi ${out} tmp_${out}_0 0 $incr"
  echo "    $cmd" ; $cmd
  cmd="fslroi ${out} tmp_${out}_1 $incr $incr"
  echo "    $cmd" ; $cmd
  imrm ${out}
  cmd="fslmaths tmp_${out}_0 -add tmp_${out}_1 -div 2 tmp_${out}"
  echo "    $cmd" ; $cmd
  
  # zeroing negative values
  echo "`basename $0`: zeroing negative values..." # see mailing list
  fslmaths ${out} -thr 0 ${out}
 
  # cleanup
  echo "`basename $0`: cleaning up..."
  imrm tmp_${out}_0 tmp_${out}_1

# change to prev. working directory
cd $wd
