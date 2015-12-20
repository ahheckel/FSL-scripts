#!/bin/bash

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

wdir=`pwd`/.plot$$ ; mkdir -p $wdir
trap "echo -e \"\ncleanup: erasing '$wdir'\" ; rm -f $wdir/* ; rmdir $wdir ; exit" EXIT

source $(dirname $0)/globalfuncs

Usage() {
    echo ""
    echo "Usage: `basename $0` <out-png> <\"subdir/filename\"> <subjectsdir> <\"01 02 ...\"|-> <\"sessa sessb ...\">"
    echo "Example: `basename $0` mc-par.png fdt/ec_diff_merged.ecclog subj/ \"01 02 03\" \"a c e\""    
    echo ""
    exit 1
}


[ "$4" = "" ] && Usage
out="$1"
input="$2"
subjdir="$3"
if [ "$4" = "-" ] ; then
  subjects=$(find $subjdir -mindepth 1 -maxdepth 1 -type d | grep -v FS_ | sort)
  subjects=$(echo $subjects | sed "s|$subjdir||g" | sed "s|/||g")
else
  subjects="$4"
fi
sessions="$5"

sdir=`pwd`
infile=$(basename $input)
indir=$(dirname $input)


echo "----- BEGIN PLOT_EC -----"
ec_disp_subj="" ; ec_disp_subjsess=""  # initialise
ec_rot_subj="" ; ec_rot_subjsess=""  # initialise
ec_trans_subj="" ; ec_trans_subjsess=""  # initialise

for subj in $subjects ; do     
  fldr=$subjdir/$subj/$indir
  

  if [ -f $fldr/$infile ] ; then
    cd $fldr
    
    # cleanup previous runs...
    rm -f ec_rot.txt ; rm -f ec_disp.txt ; rm -f ec_trans.txt
    
    # plot...
    echo "ECPLOT : subj $subj : plotting motion parameters from ec-log file..." 
    eddy_correct_plot $infile $subj
    
    # accumulate
    ec_disp_subj=$ec_disp_subj" "$fldr/ec_disp.png
    ec_rot_subj=$ec_rot_subj" "$fldr/ec_rot.png
    ec_trans_subj=$ec_trans_subj" "$fldr/ec_trans.png

    cd $sdir
  fi
  
  for sess in $sessions ; do
    # skip if single session design
    if [ $sess = '.' ] ; then continue ; fi
    
    fldr=$subjdir/$subj/$sess/$indir
    if [ -f $fldr/$infile ] ; then		
      cd $fldr
      
      # cleanup previous runs...
      rm -f ec_rot.txt ; rm -f ec_disp.txt ; rm -f ec_trans.txt
      
      # plot...
      echo "ECPLOT : subj $subj , sess $sess : plotting motion parameters from ec-log file..." 
      eddy_correct_plot $infile $(subjsess)
      
      # accumulate
      ec_disp_subjsess=$ec_disp_subjsess" "$fldr/ec_disp.png
      ec_rot_subjsess=$ec_rot_subjsess" "$fldr/ec_rot.png
      ec_trans_subjsess=$ec_trans_subjsess" "$fldr/ec_trans.png
      
      cd $sdir
    fi
  done
done

# Creating overall image
echo "ECPLOT : creating overall plot..."
n1=`echo $ec_disp_subj | wc -w`
n2=`echo $ec_disp_subjsess | wc -w`
n3=`echo $ec_rot_subj | wc -w`
n4=`echo $ec_rot_subjsess | wc -w`
n5=`echo $ec_trans_subj | wc -w`
n6=`echo $ec_trans_subjsess | wc -w`

if [ $n1 -gt 0 ] ; then montage -tile 1x${n1} -mode Concatenate $ec_disp_subj $wdir/ec_disp_subj.png ; fi
if [ $n2 -gt 0 ] ; then montage -tile 1x${n2} -mode Concatenate $ec_disp_subjsess $wdir/ec_disp_subjsess.png ; fi
if [ $n3 -gt 0 ] ; then montage -tile 1x${n3} -mode Concatenate $ec_rot_subj $wdir/ec_rot_subj.png ; fi
if [ $n4 -gt 0 ] ; then montage -tile 1x${n4} -mode Concatenate $ec_rot_subjsess $wdir/ec_rot_subjsess.png ; fi
if [ $n5 -gt 0 ] ; then montage -tile 1x${n5} -mode Concatenate $ec_trans_subj $wdir/ec_trans_subj.png ; fi
if [ $n6 -gt 0 ] ; then montage -tile 1x${n6} -mode Concatenate $ec_trans_subjsess $wdir/ec_trans_subjsess.png ; fi

if [ $n1 -gt 0 -o $n2 -gt 0 -o $n3 -gt 0 -o $n4 -gt 0 -o $n5 -gt 0 -o $n6 -gt 0 ] ; then
  echo "ECPLOT : saving composite file..." 
  montage -adjoin -geometry ^ $wdir/ec_disp_*.png $wdir/ec_rot_*.png $wdir/ec_trans_*.png $out

  # deleting intermediate files
  rm -f $wdir/ec_disp_*.png $wdir/ec_rot_*.png $wdir/ec_trans_*.png
else
  echo "ECPLOT : nothing to plot." 
fi

