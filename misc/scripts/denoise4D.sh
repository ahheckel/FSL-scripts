#!/bin/bash
# removes nuisance confounds from 4D functional using masks

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage: `basename $0` <input4D> <masks> <movpar|0> <output> <subj_idx> <sess_idx>"
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

[ "$4" = "" ] && Usage
input=$(remove_ext "$1")
masks="$2"
movpar="$3" ; if [ $movpar = "0" ] ; then movpar="" ; fi
output=$(remove_ext "$4")
subj="$5"  # optional
sess="$6"  # optional

outdir=`dirname $output`
indir=`dirname $input`
formula1="output_precision(8); c" # formula1="c-mean(c)" # for WM / CSF / WB signal
formula2="output_precision(8); c" # formula2="c-mean(c)" # for movpars

ts_list=""
ts_list_proc=""
for mask in $masks ; do
  mask=$indir/$mask 
  ts=${output}_$(basename $(remove_ext $mask))_meants
  echo "`basename $0` : subj $subj , sess $sess : extracting timecourse for '$mask' -> '$ts'..."
  
  if [ ! -f $mask ] ; then echo "`basename $0` : subj $subj , sess $sess : ERROR: '$mask' not found - exiting..." ; exit 1 ; fi
  
  fslmeants -i $input -m $mask -o $ts
  
  # process using octave
  rm -f ${ts}_proc
  vals=$(cat $ts)
  c=$(octave -q --eval "c=[$vals] ; $formula1")
  echo $c | cut -d "=" -f 2- |  row2col > ${ts}_proc

  ts_list=$ts_list" "${ts}
  ts_list_proc=$ts_list_proc" "${ts}_proc
done

if [ x$movpar != "x" ] ; then 
  if [ ! -f $movpar ] ; then 
    echo "`basename $0` : subj $subj , sess $sess : motion parameter file '$movpar' not found - exiting..."
    exit 1
  else  
    cat $movpar > ${output}_movpar

    # process using octave
    movpar_proc=${output}_movpar_proc
    rm -f ${movpar_proc}_?

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
        
    paste -d " " ${movpar_proc}_1 ${movpar_proc}_2 ${movpar_proc}_3 ${movpar_proc}_4 ${movpar_proc}_5 ${movpar_proc}_6 > $movpar_proc
    rm -f ${movpar_proc}_?
  fi
fi

ones=$outdir/ones
for i in $ts_list ; do n=$(cat $i | wc -l) ; break ; done
c=$(octave -q --eval "ones($n,1)") ; echo $c | cut -d "=" -f 2- |  row2col > $ones

confounds="${output}_nuisance_meants.mat"
echo "`basename $0` : subj $subj , sess $sess : creating nuisance matrix '$confounds' and '${confounds%.mat}_proc.mat'..."
paste -d " " $ts_list_proc $movpar_proc $ones > ${confounds%.mat}_proc.mat
paste -d " " $ts_list $movpar $ones > $confounds

# denoise
echo "`basename $0` : subj $subj , sess $sess : denoising..."
#cmd="fsl_glm -i $input -d ${confounds%.mat}_proc.mat --demean --out_res=${output}"
#echo $cmd ; $cmd
#fslmaths $input -Tmean ${input}_mean
#fslmaths ${output} -add ${input}_mean ${output} # otw. speckled results...

n_movpar=$(awk '{print NF}' $movpar | sort -nu | head -n 1)
n_masks=$(echo $masks | wc -w)
n_total=$(echo "scale=0; $n_movpar + $n_masks + 1" | bc) # add 1 for the mean regressor (!)
comps=$(echo `seq 1 $n_total` | sed "s| |","|g")

cmd="fsl_regfilt -i $input -o ${output} -d ${confounds%.mat}_proc.mat -f $comps"
echo $cmd | tee ${output}.cmd ; $cmd

# cleanup
rm -f $ones $ts_list_proc $movpar_proc
imrm ${input}_mean



