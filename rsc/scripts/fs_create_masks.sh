#!/bin/bash
# Extracts nuisance confounds from 4D functional in native space using Freesurfer recons & Freesurfer's bbregister.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 01/12/2015

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "`basename $0` is creating WM / CSF / GM masks in native space of functionals using Freesurfer's bbregister. Freesurfer recons must be available."
    echo "Usage: `basename $0` <FREESURFER SUBJECTS_DIR> <subject-ID> <example_func|none> <outdir> <subj_idx> <sess_idx>"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage
SUBJECTS_DIR="$1"
subjID="$2"
exfunc=`remove_ext "$3"`
outdir="$4"
subj="$5"  # optional
sess="$6"  # optional

GMctx_labels="3 42"
GMinfra_labels="8 47"
GMsubctx_labels="10 11 12 13 17 18 26 28 49 50 51 52 53 54 58 60"    
CSF_labels="4 5 14 15 43 44 24" # (no basal cisterns / subarachnoidal space in FS labeled segmentations found) (!)
WM_labels="2 41 7 46" # include cerebellar WM also (7 46) ? (?)
WMsupra_labels="2 41" 
WMinfra_labels="7 46" 

## delete unfinished bbreg runs
#rm -rf "$outdir"/tmp.bbregister.*

echo "`basename $0` : subj $subj , sess $sess : checking if FREESURFER recons for ID '$subjID' are present..."
if [ ! -f $SUBJECTS_DIR/$subjID/mri/aparc+aseg.mgz ] ; then echo "`basename $0` : ERROR : 'aparc+aseg.mgz' not found in '$SUBJECTS_DIR/$subjID/mri' -> you need to run recon-all first. Exiting..." ; exit 1 ; fi

#echo "`basename $0` : subj $subj , sess $sess : converting orig.mgz to nifti format..."
#cmd="mri_convert $SUBJECTS_DIR/$subjID/mri/orig.mgz $outdir/T1_bbr_ref.nii.gz" ; $cmd 1>/dev/null

echo "`basename $0` : subj $subj , sess $sess : extracting binary labels from FS segmentation (note that WM-mask is eroded a bit)..."
cmd="mri_binarize --i $SUBJECTS_DIR/$subjID/mri/aparc+aseg.mgz --match $WM_labels --erode 2 --o $outdir/T1_WM.nii.gz" ; $cmd 1>/dev/null
cmd="mri_binarize --i $SUBJECTS_DIR/$subjID/mri/aparc+aseg.mgz --match $WMsupra_labels --erode 2 --o $outdir/T1_WMsupra.nii.gz" ; $cmd 1>/dev/null
cmd="mri_binarize --i $SUBJECTS_DIR/$subjID/mri/aparc+aseg.mgz --match $WMinfra_labels --erode 2 --o $outdir/T1_WMinfra.nii.gz" ; $cmd 1>/dev/null
cmd="mri_binarize --i $SUBJECTS_DIR/$subjID/mri/aparc+aseg.mgz --match $WM_labels --o $outdir/T1_WMfull.nii.gz" ; $cmd 1>/dev/null
cmd="mri_binarize --i $SUBJECTS_DIR/$subjID/mri/aparc+aseg.mgz --match $CSF_labels --o $outdir/T1_CSF.nii.gz" ; $cmd 1>/dev/null
cmd="mri_binarize --i $SUBJECTS_DIR/$subjID/mri/aseg.mgz --match $GMctx_labels $GMsubctx_labels --o $outdir/T1_GM.nii.gz" ; $cmd 1>/dev/null
cmd="mri_binarize --i $SUBJECTS_DIR/$subjID/mri/aseg.mgz --match $GMinfra_labels --o $outdir/T1_GMinfra.nii.gz" ; $cmd 1>/dev/null
cmd="mri_binarize --i $SUBJECTS_DIR/$subjID/mri/aseg.mgz --match $GMsubctx_labels --o $outdir/T1_GMsubctx.nii.gz" ; $cmd 1>/dev/null
cmd="mri_binarize --i $SUBJECTS_DIR/$subjID/mri/aseg.mgz --match $GMctx_labels --o $outdir/T1_GMctx.nii.gz" ; $cmd 1>/dev/null

if [ $exfunc != "none" ] ; then
  echo "`basename $0` : subj $subj , sess $sess : boundary-based registration '$exfunc' to T1..."
  cmd="bbregister --s $subjID --mov ${exfunc}.nii.gz --init-fsl --reg $outdir/EF2T1_bbr.dat --t2 --fslmat $outdir/EF2T1_bbr.fslmat" ; $cmd 1>/dev/null
  #tkregister2 --mov ${exfunc}.nii.gz --reg $outdir/EF2T1_bbr.dat --surf

  echo "`basename $0` : subj $subj , sess $sess : mapping binary labels to functional space..."
  cmd="mri_label2vol --reg $outdir/EF2T1_bbr.dat --seg $outdir/T1_WM.nii.gz --temp ${exfunc}.nii.gz --o $outdir/EF_WM.nii.gz" ; $cmd 1>/dev/null
  cmd="mri_label2vol --reg $outdir/EF2T1_bbr.dat --seg $outdir/T1_CSF.nii.gz --temp ${exfunc}.nii.gz --o $outdir/EF_CSF.nii.gz" ; $cmd 1>/dev/null
  cmd="mri_label2vol --reg $outdir/EF2T1_bbr.dat --seg $outdir/T1_GM.nii.gz --temp ${exfunc}.nii.gz --o $outdir/EF_GM.nii.gz" ; $cmd 1>/dev/null

  echo "`basename $0` : subj $subj , sess $sess : creating also a whole brain mask from '$exfunc'..."
  bet $exfunc ${exfunc}_betted_$$ -f 0.3
  #min=`fslstats ${exfunc}_betted_$$ -P 15`
  min=0
  fslmaths ${exfunc}_betted_$$ -thr $min -bin -ero $outdir/EF_WB.nii.gz
  
  # cleanup
  imrm ${exfunc}_betted_$$ $outdir/T1_GM.nii.gz $outdir/T1_GMctx.nii.gz $outdir/T1_GMsubctx.nii.gz $outdir/T1_GMinfra.nii.gz $outdir/T1_WM.nii.gz $outdir/T1_WMsupra.nii.gz $outdir/T1_WMinfra.nii.gz $outdir/T1_WMfull.nii.gz $outdir/T1_CSF.nii.gz
fi

echo "`basename $0` : subj $subj , sess $sess : done."
