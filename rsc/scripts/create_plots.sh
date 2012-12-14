#!/bin/bash
# Gather plots from directory tree ans save as .png.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 12/14/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Usage:   `basename $0` <-dwimc|-dwiuw|-boldmc|-bolduw|-bold2T1|-bold2MNI> [featdir] <outname> [subj] [sess]"
    echo "Example: `basename $0` -dwiuw uwDWI_+y.feat ./checkdir/uwdwi \"subj01 subj02\" \"sessa sessb\""
    echo ""

    exit 1
}

[ "$2" = "" ] && Usage

if [ x"$(which montage)" = "x" ] ; then echo "$(basename $0): ERROR: Imagemagick must be installed... exiting." ; exit 1 ; fi

source `pwd`/globalvars
source $(dirname $0)/globalfuncs

PLOT_DWI_UNWARP=0;
PLOT_EC=0
PLOT_BOLD_MC=0;
PLOT_BOLD_T1REG=0;
PLOT_BOLD_UNWARP=0;
PLOT_BOLD_MNIREG=0;

while (( $# > 1 )) ; do
    case "$1" in
        "-help")
            Usage
            ;;
        "-dwimc")
            PLOT_EC=1
            shift
            ;;
        "-boldmc")
            PLOT_BOLD_MC=1
            PLOT_BOLD_MC_DIRNAMES="$2"
            shift 2
            ;;
        "-bolduw")
            PLOT_BOLD_UNWARP=1
            PLOT_BOLD_UNWARP_DIRNAMES="$2"
            shift 2
            ;;
        "-dwiuw")
            PLOT_DWI_UNWARP=1
            PLOT_DWI_UNWARP_DIRNAMES="$2"
            shift 2
            ;;
        "-bold2T1")
            PLOT_BOLD_T1REG=1
            PLOT_BOLD_T1REG_DIRNAMES="$2"
            shift 2
            ;;
        "-bold2MNI")
            PLOT_BOLD_MNIREG=1
            PLOT_BOLD_MNIREG_DIRNAMES="$2"
            shift 2
            ;;
        -*)
            echo "ERROR: Unknown option '$1'"
            Usage
            exit 1
            break
            ;;
        *)
            break
            ;;
    esac
done

out="$1" ; outdir=$(dirname $out)
subjects="$2"
sessions="$3"

wd=`pwd`
if [ ! -d $outdir ] ; then echo "$(basename $0): '$outdir not present... creating it." ; mkdir -p $outdir ; fi

###########################
# ----- BEGIN PLOT EC -----
###########################      
# plotting eddy-correct motion parameters
if [ $PLOT_EC -eq 1 ] ; then
  echo "----- BEGIN PLOT_EC -----"
  ec_disp=""  # initialise
  ec_rot=""   # initialise
  ec_trans="" # initialise
  if [ x"$subjects" = "x" ] ; then subjects=`cat $subjdir/subjects` ; fi
  for  subj in $subjects ; do
    if [ x"$sessions" = "x" ] ; then sessions=`cat $subjdir/$subj/sessions_struc` ; fi
    for sess in $sessions ; do
        
      fldr=$subjdir/$subj/$sess/fdt
    
      if [ -f $fldr/ec_diff_merged.ecclog ] ; then
        cd $fldr        
          # cleanup previous runs...
          rm -fv ec_rot.txt ; rm -fv ec_disp.txt ; rm -fv ec_trans.txt
          
          # plot...
          echo "ECPLOT : subj $subj , sess $sess : plotting motion parameters from ec-log file..." 
          eddy_correct_plot ec_diff_merged.ecclog $(subjsess)
          
          # accumulate
          ec_disp=$ec_disp" "$fldr/ec_disp.png
          ec_rot=$ec_rot" "$fldr/ec_rot.png
          ec_trans=$ec_trans" "$fldr/ec_trans.png
        cd $wd
      fi   
   
    done
  done
  
  # Creating overall image
  echo "ECPLOT : creating overall plot..."
  n1=`echo $ec_disp  | wc -w`
  n2=`echo $ec_rot   | wc -w`
  n3=`echo $ec_trans | wc -w`
  
  if [ $n1 -gt 0 ] ; then montage -tile 1x${n1} -mode Concatenate $ec_disp  $outdir/ec_disp_concat.png ; fi
  if [ $n2 -gt 0 ] ; then montage -tile 1x${n2} -mode Concatenate $ec_rot   $outdir/ec_rot_concat.png ; fi
  if [ $n3 -gt 0 ] ; then montage -tile 1x${n3} -mode Concatenate $ec_trans $outdir/ec_trans_concat.png ; fi

  if [ $n1 -gt 0 -o $n2 -gt 0 -o $n3 -gt 0 ] ; then
    echo "ECPLOT : saving composite file to '$out'." 
    montage -adjoin -geometry ^ $outdir/ec_disp_*.png $outdir/ec_rot_*.png $outdir/ec_trans_*.png $out.ec.png
  
    # deleting intermediate files
    rm -f $outdir/ec_disp_*.png $outdir/ec_rot_*.png $outdir/ec_trans_*.png
  else
    echo "ECPLOT : nothing to plot." 
  fi
fi
#########################
# ----- END PLOT EC -----
#########################


###################################
# ----- BEGIN PLOT_DWI_UNWARP -----
###################################
if [ $PLOT_DWI_UNWARP -eq 1 ] ; then
  echo "----- BEGIN PLOT_DWI_UNWARP -----"
  
  if [ -z "$PLOT_DWI_UNWARP_DIRNAMES" ] ; then echo "PLOT_DWI_UNWARP : ERROR : no directory specified." ; exit 1 ; fi
  
  for dirnm in $PLOT_DWI_UNWARP_DIRNAMES ; do
    appends=""
    
    if [ x"$subjects" = "x" ] ; then subjects=`cat $subjdir/subjects` ; fi
    for subj in $subjects ; do
      j=0
      if [ x"$sessions" = "x" ] ; then sessions=`cat $subjdir/$subj/sessions_struc` ; fi
      for sess in $sessions ; do
        
        # gather files
        n=$(find $subjdir/$subj/$sess/fdt -mindepth 3 -maxdepth 3 -name EF_UD_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | wc -l)
        if [ $n -gt 1 ] ; then
          echo "WARNING : search pattern matches more than one directory:"
          echo "$(find $subjdir/$subj/$sess/fdt -mindepth 3 -maxdepth 3 -name EF_UD_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | xargs ls -rt | xargs -I {} dirname {} )"
          echo "...taking the last one, because it is newer."
        fi
        
        # define distorted      
        dwi_D=$(find $subjdir/$subj/$sess/fdt -mindepth 3 -maxdepth 3 -name EF_D_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | xargs ls -rt | grep EF_D_example_func.nii.gz | tail -n 1)
        # define undistorted
        dwi_UD=$(find $subjdir/$subj/$sess/fdt -mindepth 3 -maxdepth 3 -name EF_UD_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | xargs ls -rt | grep EF_UD_example_func.nii.gz | tail -n 1)
        if [ -z $dwi_UD ] ; then echo "PLOT_DWI_UNWARP : subj $subj , sess $sess : WARNING : no 'EF_UD_example_func.nii.gz' file found under '$subjdir/$subj/$sess/fdt/*${dirnm}*' - continuing loop..." ; continue ; fi
        
        # extract 2D-images and outline
        echo "PLOT_DWI_UNWARP : subj $subj , sess $sess : processing '$dwi_D'..."
        cmd="slicer -s 2 $dwi_D $(dirname $dwi_UD)/EF_UD_fmap_mag_brain.nii.gz -a $outdir/$(subjsess)_dwi_D2fmap.png"
        $cmd
        echo "PLOT_DWI_UNWARP : subj $subj , sess $sess : processing '$dwi_UD'..."
        cmd="slicer -s 2 $dwi_UD $(dirname $dwi_UD)/EF_UD_fmap_mag_brain.nii.gz -a $outdir/$(subjsess)_dwi_UD2fmap.png"
        $cmd
        
        # montage
        dirnm_base0=$(basename $(dirname $(dirname $(dirname $dwi_UD)))) ; dirnm_base1=$(basename $(dirname $(dirname $dwi_UD)))
        montage -adjoin $outdir/$(subjsess)_dwi_D2fmap.png $outdir/$(subjsess)_dwi_UD2fmap.png -geometry ^ $outdir/$(subjsess)_dwi2mag.png
        montage -label "D vs UD \n$(subjsess) ($dirnm_base0/\n$dirnm_base1)" -pointsize 9 -geometry ^ $outdir/$(subjsess)_dwi2mag.png $outdir/$(subjsess)_dwi2mag.png
        rm -f $outdir/$(subjsess)_dwi_D2fmap.png $outdir/$(subjsess)_dwi_UD2fmap.png
        
        # accumulate montaged files
        if [ -z "$appends" ] ; then 
          appends=$outdir/$(subjsess)_dwi2mag.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$outdir/$(subjsess)_dwi2mag.png
        else
          appends=$appends" - "$outdir/$(subjsess)_dwi2mag.png
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done
    
    # creating overall plot
    if [ ! -z "$appends" ] ; then
      echo "PLOT_DWI_UNWARP : creating overall plot..."
      cmd="pngappend $appends $out.diff2mag.fdt.${dirnm}.png"
      echo $cmd ; $cmd        
      echo "PLOT_DWI_UNWARP : cleaning up..."
      rm -f $outdir/*_dwi2mag.png
    else 
      echo "PLOT_DWI_UNWARP : nothing to plot."
    fi

  done
fi
#################################
# ----- END PLOT_DWI_UNWARP -----
#################################

################################
# ----- BEGIN PLOT_BOLD_MC -----
################################
if [ $PLOT_BOLD_MC -eq 1 ] ; then
  echo "----- BEGIN PLOT_BOLD_MC -----"
  
  if [ -z "$PLOT_BOLD_MC_DIRNAMES" ] ; then echo "PLOT_BOLD_MC : ERROR : no directory specified." ; exit 1 ; fi
  
  for dirnm in $PLOT_BOLD_MC_DIRNAMES ; do
    appends=""
    
    if [ x"$subjects" = "x" ] ; then subjects=`cat $subjdir/subjects` ; fi
    for subj in $subjects ; do
      j=0
      if [ x"$sessions" = "x" ] ; then sessions=`cat $subjdir/$subj/sessions_func` ; fi
      for sess in $sessions ; do
        
        n=$(find $subjdir/$subj/$sess -mindepth 3 -maxdepth 4 -name disp.png -type f | grep $dirnm | grep /mc | wc -l)
        if [ $n -gt 1 ] ; then
          echo "WARNING : search pattern matches more than one directory:"
          echo "$(find $subjdir/$subj/$sess -mindepth 3 -maxdepth 4 -name disp.png -type f | grep $dirnm | grep /mc | xargs ls -rt | xargs -I {} dirname {} )"
          echo "...taking the last one, because it is newer."
        fi
        disp=$(find $subjdir/$subj/$sess -mindepth 3 -maxdepth 4 -name disp.png -type f | grep $dirnm | grep /mc | xargs ls -rt | grep disp.png | tail -n 1)
        rot=$(find $subjdir/$subj/$sess -mindepth 3 -maxdepth 4 -name rot.png -type f | grep $dirnm | grep /mc | xargs ls -rt | grep rot.png | tail -n 1)
        trans=$(find $subjdir/$subj/$sess -mindepth 3 -maxdepth 4 -name trans.png -type f | grep $dirnm | grep /mc | xargs ls -rt | grep trans.png | tail -n 1)
        if [ -z $disp ] ; then echo "PLOT_BOLD_MC : subj $subj , sess $sess : WARNING : no 'disp.png' file found under '$subjdir/$subj/$sess/bold/*${dirnm}*' - continuing loop..." ; continue ; fi
        
        echo "PLOT_BOLD_MC : subj $subj , sess $sess : processing..."
        cmd="pngappend $disp + $rot + $trans $outdir/$(subjsess)_mc.png"
        echo $cmd ; $cmd

        dirnm_base0=$(basename $(dirname $(dirname $(dirname $disp)))) ; dirnm_base1=$(basename $(dirname $(dirname $disp)))
        montage -label "$(subjsess) ($dirnm_base1)" -pointsize 10 -geometry ^ $outdir/$(subjsess)_mc.png  $outdir/$(subjsess)_mc.png
        
        if [ -z "$appends" ] ; then 
          appends=$outdir/$(subjsess)_mc.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$outdir/$(subjsess)_mc.png 
        else
          appends=$appends" - "$outdir/$(subjsess)_mc.png
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done    

    if [ ! -z "$appends" ] ; then
      echo "PLOT_BOLD_MC : creating overall plot..."
      cmd="pngappend $appends $out.mc.bold.${dirnm}.png"
      echo $cmd ; $cmd
      echo "PLOT_BOLD_MC : cleaning up..."
      rm -f $outdir/*_mc.png
    else
      echo "PLOT_BOLD_MC : nothing to plot."
    fi    

  done
fi
##############################
# ----- END PLOT_BOLD_MC -----
##############################

####################################
# ----- BEGIN PLOT_BOLD_UNWARP -----
####################################
if [ $PLOT_BOLD_UNWARP -eq 1 ] ; then
  echo "----- BEGIN PLOT_BOLD_UNWARP -----"
  
  if [ -z "$PLOT_BOLD_UNWARP_DIRNAMES" ] ; then echo "PLOT_BOLD_UNWARP : ERROR : no directory specified." ; exit 1 ; fi
  
  for dirnm in $PLOT_BOLD_UNWARP_DIRNAMES ; do
    appends=""
    
    if [ x"$subjects" = "x" ] ; then subjects=`cat $subjdir/subjects` ; fi
    for subj in $subjects ; do
      j=0
      if [ x"$sessions" = "x" ] ; then sessions=`cat $subjdir/$subj/sessions_func` ; fi
      for sess in $sessions ; do
        
        n=$(find $subjdir/$subj/$sess/bold -mindepth 3 -maxdepth 3 -name EF_UD_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | wc -l)
        if [ $n -gt 1 ] ; then
          echo "WARNING : search pattern matches more than one directory:"
          echo "$(find $subjdir/$subj/$sess/bold -mindepth 3 -maxdepth 3 -name EF_UD_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | xargs ls -rt | xargs -I {} dirname {} )"
          echo "...taking the last one, because it is newer."
        fi      
        bold_D=$(find $subjdir/$subj/$sess/bold -mindepth 3 -maxdepth 3 -name EF_D_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | xargs ls -rt | grep EF_D_example_func.nii.gz | tail -n 1)
        bold_UD=$(find $subjdir/$subj/$sess/bold -mindepth 3 -maxdepth 3 -name EF_UD_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | xargs ls -rt | grep EF_UD_example_func.nii.gz | tail -n 1)
        if [ -z $bold_UD ] ; then echo "PLOT_BOLD_UNWARP : subj $subj , sess $sess : WARNING : no 'EF_UD_example_func.nii.gz' file found under '$subjdir/$subj/$sess/bold/*${dirnm}*' - continuing loop..." ; continue ; fi
        
        echo "PLOT_BOLD_UNWARP : subj $subj , sess $sess : processing '$bold_D'..."
        cmd="slicer -s 2 $bold_D $(dirname $bold_UD)/EF_UD_fmap_mag_brain.nii.gz -a $outdir/$(subjsess)_bold_D2fmap.png"
        $cmd
        echo "PLOT_BOLD_UNWARP : subj $subj , sess $sess : processing '$bold_UD'..."
        cmd="slicer -s 2 $bold_UD $(dirname $bold_UD)/EF_UD_fmap_mag_brain.nii.gz -a $outdir/$(subjsess)_bold_UD2fmap.png"
        $cmd
        
        dirnm_base0=$(basename $(dirname $(dirname $(dirname $bold_UD)))) ; dirnm_base1=$(basename $(dirname $(dirname $bold_UD)))
        montage -adjoin $outdir/$(subjsess)_bold_D2fmap.png $outdir/$(subjsess)_bold_UD2fmap.png -geometry ^ $outdir/$(subjsess)_bold2mag.png
        montage -label "D vs UD \n$(subjsess) ($dirnm_base0/\n$dirnm_base1)" -pointsize 9 -geometry ^ $outdir/$(subjsess)_bold2mag.png $outdir/$(subjsess)_bold2mag.png
        rm -f $outdir/$(subjsess)_bold_D2fmap.png $outdir/$(subjsess)_bold_UD2fmap.png
        
        if [ -z "$appends" ] ; then 
          appends=$outdir/$(subjsess)_bold2mag.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$outdir/$(subjsess)_bold2mag.png
        else
          appends=$appends" - "$outdir/$(subjsess)_bold2mag.png
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done
    
    if [ ! -z "$appends" ] ; then
      echo "PLOT_BOLD_UNWARP : creating overall plot..."
      cmd="pngappend $appends $out.bold2mag.${dirnm}.png"
      echo $cmd ; $cmd        
      echo "PLOT_BOLD_UNWARP : cleaning up..."
      rm -f $outdir/*_bold2mag.png
    else 
      echo "PLOT_BOLD_UNWARP : nothing to plot."
    fi

  done
fi
##################################
# ----- END PLOT_BOLD_UNWARP -----
##################################

###################################
# ----- BEGIN PLOT_BOLD_T1REG -----
###################################
if [ $PLOT_BOLD_T1REG -eq 1 ] ; then
  echo "----- BEGIN PLOT_BOLD_T1REG -----"
  
  if [ -z "$PLOT_BOLD_T1REG_DIRNAMES" ] ; then echo "PLOT_BOLD_T1REG : WARNING : no directory specified." ; fi
  
  for dirnm in $PLOT_BOLD_T1REG_DIRNAMES ; do
    appends=""
    
    if [ x"$subjects" = "x" ] ; then subjects=`cat $subjdir/subjects` ; fi
    for subj in $subjects ; do
      j=0
      if [ x"$sessions" = "x" ] ; then sessions=`cat $subjdir/$subj/sessions_func` ; fi
      for sess in $sessions ; do
              
        pngs=`find $subjdir/$subj/$sess -mindepth 4 -maxdepth 4 -name example_func2highres.png -type f`
        n=$(echo $pngs | row2col | grep $dirnm | grep /reg/ | wc -l)
        if [ $n -gt 1 ] ; then
          echo "WARNING : search pattern matches more than one directory:"
          echo "$(echo $pngs | row2col | grep $dirnm | grep /reg/ | xargs ls -rt | xargs -I {} dirname {} )"
          echo "...taking the last one, because it is newer."
        fi
        png=$(echo $pngs | row2col | grep $dirnm | grep /reg/ | xargs ls -rt | grep example_func2highres.png | tail -n 1)
        if [ -z $png ] ; then echo "PLOT_BOLD_T1REG : subj $subj , sess $sess : WARNING : no 'example_func2highres.png' file found under '*${dirnm}*' - continuing loop..." ; continue ; fi
        
        dirnm_base1=$(basename $(dirname $(dirname $png))) ; dirnm_base0=$(basename $(dirname $(dirname $(dirname $png))))
        montage -label "$(subjsess) ($dirnm_base0/\n$dirnm_base1)" -pointsize 42 $png -geometry ^ $outdir/$(subjsess)_func2t1.png 
        
        if [ -z "$appends" ] ; then 
          appends=$outdir/$(subjsess)_func2t1.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$outdir/$(subjsess)_func2t1.png
        else
          appends=$appends" + "$outdir/$(subjsess)_func2t1.png
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done
    
    if [ ! -z "$appends" ] ; then
      echo "PLOT_BOLD_T1REG : creating overall plot..."
      cmd="pngappend $appends $out.func2t1.bold.${dirnm}.png"
      echo $cmd ; $cmd    
      echo "PLOT_BOLD_T1REG : cleaning up..."
      rm -f $outdir/*_func2t1.png    
    else
      echo "PLOT_BOLD_T1REG : nothing to plot."
    fi
    
  done
fi
#################################
# ----- END PLOT_BOLD_T1REG -----
#################################

####################################
# ----- BEGIN PLOT_BOLD_MNIREG -----
####################################
if [ $PLOT_BOLD_MNIREG -eq 1 ] ; then
  echo "----- BEGIN PLOT_BOLD_MNIREG -----"
  
  if [ -z "$PLOT_BOLD_MNIREG_DIRNAMES" ] ; then echo "PLOT_BOLD_MNIREG : WARNING : no directory specified." ; fi
  
  for dirnm in $PLOT_BOLD_MNIREG_DIRNAMES ; do
    appends="" 
        
    if [ x"$subjects" = "x" ] ; then subjects=`cat $subjdir/subjects` ; fi
    for subj in $subjects ; do
      j=0
      if [ x"$sessions" = "x" ] ; then sessions=`cat $subjdir/$subj/sessions_func` ; fi
      for sess in $sessions ; do
 
        pngs=`find $subjdir/$subj/$sess -mindepth 4 -maxdepth 4 -name example_func2standard.png -type f`
        n=$(echo $pngs | row2col | grep $dirnm | grep /reg/ | wc -l)
        if [ $n -gt 1 ] ; then
          echo "WARNING : search pattern matches more than one directory:"
          echo "$(echo $pngs | row2col | grep $dirnm | grep /reg/ | xargs ls -rt | xargs -I {} dirname {} )"
          echo "...taking the last one, because it is newer."
        fi
        png=$(echo $pngs | row2col | grep $dirnm | grep /reg/ | xargs ls -rt | grep example_func2standard.png | tail -n 1)
        if [ -z $png ] ; then echo "PLOT_BOLD_MNIREG : subj $subj , sess $sess : WARNING : no 'example_func2standard.png' file found under '*${dirnm}*' - continuing loop..." ; continue ; fi
        
        dirnm_base1=$(basename $(dirname $(dirname $png))) ; dirnm_base0=$(basename $(dirname $(dirname $(dirname $png))))
        montage -label "$(subjsess) ($dirnm_base0/\n$dirnm_base1)" -pointsize 16 $png -geometry ^ $outdir/$(subjsess)_func2std.png 
        
        if [ -z "$appends" ] ; then 
          appends=$outdir/$(subjsess)_func2std.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$outdir/$(subjsess)_func2std.png
        else
          appends=$appends" + "$outdir/$(subjsess)_func2std.png
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done
    
    if [ ! -z "$appends" ] ; then
      echo "PLOT_BOLD_MNIREG : creating overall plot..."
      cmd="pngappend $appends $out.func2std.bold.${dirnm}.png"
      echo $cmd ; $cmd    
      echo "PLOT_BOLD_MNIREG : cleaning up..."
      rm -f $outdir/*_func2std.png    
    else
      echo "PLOT_BOLD_MNIREG : nothing to plot."
    fi
    
  done
fi
##################################
# ----- END PLOT_BOLD_MNIREG -----
##################################

echo "`basename $0`: done."
