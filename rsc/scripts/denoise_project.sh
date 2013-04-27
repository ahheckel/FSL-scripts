#!/bin/bash
# displays list of fsl_regfilt calls (artefact removal).

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:  `basename $0` <textfile> <root-dir> <bold/featdir>"
    echo "Examle: `basename $0` artfefacts.txt /mnt/nas/data/fmrtkiralutz/subj bold/preprocBOLD_uw+y_st0_s4_hpf100.feat"
    echo "Note:   'artefacts.txt' must be formatted this way:"
    echo "  multisession designs:"
    echo "  01 a 1,5,9"
    echo "  01 b 2,3,4"
    echo "  ..."
    echo "  single session designs:"
    echo "  01 . 1,5,9"
    echo "  02 . 2,3,4"
    echo "  ..."
   
    echo ""
    exit 1
}


[ "$3" = "" ] && Usage

textfile="$1"
commondir="$2"
featdir="$3"

input=filtered_func_data
output=filtered_func_data_dnICA

for i in `seq 1 $(cat $textfile | wc -l)` ; do
  subj=$(cat $textfile | sed -n ${i}p | cut -d " " -f 1)
  sess=$(cat $textfile | sed -n ${i}p | cut -d " " -f 2)
  bads=$(cat $textfile | sed -n ${i}p | cut -d " " -f 3)
  path=$commondir/$subj/$sess/$featdir

  if [ "$bads" = "keine" -o "$bads" = "none" -o "$bads" = "na" ] ; then 
    cmd="fslmaths $path/$input $path/$output" 
    echo $cmd 
  else
    cmd="fsl_regfilt -i $path/$input -d $path/${input}.ica/melodic_mix -f "$bads" -o $path/$output"
    echo $cmd
  fi
  i=$[$i+1]
done
