#!/bin/bash
# removes nuisance confounds from 4D functional using masks

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` [-m] <input4D> <"mask1 mask2 ..." |none> <movpar|none> <movpar_calcs 0:none|1:orig|2:^2|3:abs|4:diff+|5:diff-> <output> <subj_idx> <sess_idx>"
    echo "        Options:      -m     just create confound matrix, don't denoise"
    echo ""
    exit 1
}

function row2col()
{
  local dat=`cat $1`
  local i=""
  for i in $dat ; do echo $i ; done
}

if [ x$(which octave) = "x" ] ; then echo "`basename $0` : ERROR : OCTAVE does not seem to be installed on your system ! Exiting..." ; exit 1 ; fi

if [ "$1" = "-m" ] ; then 
  denoise=0
  shift
else
  denoise=1
fi

[ "$5" = "" ] && Usage
input=$(remove_ext "$1")
masks="$2"
movpar="$3" ; 
movpar_calcs="$4"
output=$(remove_ext "$5")
subj="$6"  # optional
sess="$7"  # optional

outdir=`dirname $output`
indir=`dirname $input`
formula1="output_precision(8); c" # formula1="c-mean(c)" # for WM / CSF / WB signal
formula2="output_precision(8); c" # formula2="c-mean(c)" # for movpars

# extract nuisance regressors from masks
ts_list=""
ts_list_proc=""
if [ "$masks" != "none" ] ; then 
  for mask in $masks ; do
    mask=$indir/$mask 
    ts=${output}_$(basename $(remove_ext $mask))_meants
    echo "`basename $0` : subj $subj , sess $sess : extracting timecourse for '$mask' -> '$ts'..."
    
    if [ $(imtest $mask) -eq 0 ] ; then echo "`basename $0` : subj $subj , sess $sess : ERROR: '$mask' not found - exiting..." ; exit 1 ; fi
    
    fslmeants -i $input -m $mask -o $ts
    
    # process using octave
    rm -f ${ts}_proc
    vals=$(cat $ts)
    c=$(octave -q --eval "c=[$vals] ; $formula1")
    echo $c | cut -d "=" -f 2- |  row2col > ${ts}_proc

    ts_list=$ts_list" "${ts}
    ts_list_proc=$ts_list_proc" "${ts}_proc
  done
fi

# create motion related regressors
if [ "$movpar_calcs" != 0 ] ; then 
  if [ ! -f $movpar ] ; then 
    echo "`basename $0` : subj $subj , sess $sess : motion parameter file '$movpar' not found - exiting..."
    exit 1
  else  
    cat $movpar > ${output}_movpar

    # process using octave
    movpar_proc=${output}_movpar_proc
    rm -f ${movpar_proc}_?
    
    movpar_calc_list=""
    for calc in $movpar_calcs ; do
      if [ $calc -eq 0 ] ; then continue ; fi
      if [ $calc -eq 1 ] ; then formula2="output_precision(8); c" ; fi
      if [ $calc -eq 2 ] ; then formula2="output_precision(8); c.*c" ; fi
      if [ $calc -eq 3 ] ; then formula2="output_precision(8); abs(c)" ; fi
      if [ $calc -eq 4 ] ; then formula2="output_precision(8); c=diff(c); c=[0 ; c]" ; fi
      if [ $calc -eq 5 ] ; then formula2="output_precision(8); c=diff(c); c=[c ; 0]" ; fi

      echo "`basename $0` : subj $subj , sess $sess : applied OCTAVE formula for motion parameter regressors: '$formula2'" 

      vals=$(cat $movpar | awk '{print $1}')
      c=$(octave -q --eval "c=[$vals] ; $formula2") ; echo $c | cut -d "=" -f 2- |  row2col > ${movpar_proc}_1
      vals=$(cat $movpar | awk '{print $2}')
      c=$(octave -q --eval "c=[$vals] ; $formula2") ; echo $c | cut -d "=" -f 2- |  row2col > ${movpar_proc}_2
      vals=$(cat $movpar | awk '{print $3}')
      c=$(octave -q --eval "c=[$vals] ; $formula2") ; echo $c | cut -d "=" -f 2- |  row2col > ${movpar_proc}_3
      vals=$(cat $movpar | awk '{print $4}')
      c=$(octave -q --eval "c=[$vals] ; $formula2") ; echo $c | cut -d "=" -f 2- |  row2col > ${movpar_proc}_4
      vals=$(cat $movpar | awk '{print $5}')
      c=$(octave -q --eval "c=[$vals] ; $formula2") ; echo $c | cut -d "=" -f 2- |  row2col > ${movpar_proc}_5
      vals=$(cat $movpar | awk '{print $6}')
      c=$(octave -q --eval "c=[$vals] ; $formula2") ; echo $c | cut -d "=" -f 2- |  row2col > ${movpar_proc}_6

      paste -d " " ${movpar_proc}_1 ${movpar_proc}_2 ${movpar_proc}_3 ${movpar_proc}_4 ${movpar_proc}_5 ${movpar_proc}_6 > ${movpar_proc}_calc${calc}
      movpar_calc_list=$movpar_calc_list" "${movpar_proc}_calc${calc}
      rm -f ${movpar_proc}_?
    done
    paste -d " " $movpar_calc_list > ${movpar_proc}
    rm -f ${movpar_proc}_calc*
  fi
else
  movpar=""
  movpar_proc=""
fi

# create matrix - mean regressor
ones=$outdir/ones
#for i in $ts_list ; do n=$(cat $i | wc -l) ; break ; done
n=`fslinfo  $input| grep ^dim4 | awk '{print $2}'`
c=$(octave -q --eval "ones($n,1)") ; echo $c | cut -d "=" -f 2- |  row2col > $ones

# create matrix - confounds
confounds="${output}_nuisance_meants.mat"
echo "`basename $0` : subj $subj , sess $sess : creating nuisance matrix '$confounds' and '${confounds%.mat}_proc.mat'..."
paste -d " " $ts_list_proc $movpar_proc $ones > ${confounds%.mat}_proc.mat
paste -d " " $ts_list $movpar $ones > $confounds

# denoise
if [ $denoise -eq 1 ] ; then
  echo "`basename $0` : subj $subj , sess $sess : denoising..."
  #cmd="fsl_glm -i $input -d ${confounds%.mat}_proc.mat --demean --out_res=${output}"
  #echo $cmd ; $cmd
  #fslmaths $input -Tmean ${input}_mean
  #fslmaths ${output} -add ${input}_mean ${output} # otw. speckled results...

  if [ x$movpar = "x" ] ; then 
    n_movpar=0
  else
    n_movpar=$(awk '{print NF}' $movpar_proc | sort -nu | head -n 1)
  fi
  if [ "$masks" = "none" ] ; then
    n_masks=0
  else
    n_masks=$(echo $masks | wc -w)
  fi
  n_total=$(echo "scale=0; $n_movpar + $n_masks + 1" | bc) # add 1 for the mean regressor (!)
  comps=$(echo `seq 1 $n_total` | sed "s| |","|g")

  cmd="fsl_regfilt -i $input -o ${output} -d ${confounds%.mat}_proc.mat -f $comps"
  echo $cmd | tee ${output}.cmd ; $cmd
fi

# cleanup
rm -f $ones $ts_list_proc $movpar_proc
imrm ${input}_mean

echo "`basename $0` : subj $subj , sess $sess : done."

