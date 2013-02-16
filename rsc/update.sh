#!/bin/bash
# Installs required files.
# CAVE: for AFNI tools: may need to install or link /usr/lib[64]/libXp.so.6

#set -e

if [ $# -lt 1 ] ; then echo "Usage: update [32|64]" ; exit 1 ; fi

if [ x$FSLDIR = "x" ] ; then echo "FSLDIR variable is not defined ! Exiting." ; exit 1 ; fi
if [ x$FREESURFER_HOME = "x" ] ; then echo "FREESURFER_HOME variable is not defined ! Exiting." ; exit 1 ; fi

v5=$(cat $FSLDIR/etc/fslversion | grep ^5 | wc -l)
#if [ $v5 -eq 1 ] ; then
  #echo "FSL v.5 detected. Replacing fsl_sub..."
  #cp -iv fsl/fsl_sub_v5_patched $FSLDIR/bin/fsl_sub # contains a RAM limit and JOB-ID redirection
#fi

cp -iv fsl/fsl_sub_v5_patched $FSLDIR/bin/fsl_sub # contains a RAM limit and JOB-ID redirection, should also work for FSL < v.5
cp -iv fs/trac-all $FREESURFER_HOME/bin/trac-all
cp -iv fsl/templates/MNI152*.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/avg152T1_white_bin.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/avg152T1_csf_bin.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/rsn10*.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/rsn8*.nii.gz $FSLDIR/data/standard/

if [ $v5 -eq 0 ] ; then # dont overwrite for fsl ver. 5
  #cp -iv fsl/fsl_sub_v4 $FSLDIR/bin/fsl_sub # contains a RAM limit
  cp -iv fsl/tbss_x/tbss_x $FSLDIR/bin/tbss_x
  cp -iv fsl/topup/b02b0.cnf $FSLDIR/etc/flirtsch/b02b0.cnf
  cp -iv fsl/featlib_v4.tcl $FSLDIR/tcl/featlib.tcl
fi

if [ $1 -eq 64 ] ; then
  if [ $v5 -eq 0 ] ; then # dont overwrite for fsl ver. 5
    cp -iv fsl/topup/topup_64 $FSLDIR/bin/topup
    cp -iv fsl/topup/applytopup_64 $FSLDIR/bin/applytopup 
    cp -iv fsl/tbss_x/swap_voxelwise_64 $FSLDIR/bin/swap_voxelwise
    cp -iv fsl/tbss_x/swap_subjectwise_64 $FSLDIR/bin/swap_subjectwise
  fi  
  cp -iv afni/3dDespike_64 $FSLDIR/bin/3dDespike
  cp -iv afni/3dTcat_64 $FSLDIR/bin/3dTcat
  cp -iv afni/3dTstat_64 $FSLDIR/bin/3dTstat
  cp -iv afni/3dcalc_64 $FSLDIR/bin/3dcalc
  cp -iv afni/3dDetrend_64 $FSLDIR/bin/3dDetrend
fi

if [ $1 -eq 32 ] ; then
  if [ $v5 -eq 0 ] ; then # dont overwrite for fsl ver. 5
    cp -iv fsl/topup/topup_32 $FSLDIR/bin/topup 
    cp -iv fsl/topup/applytopup_32 $FSLDIR/bin/applytopup
    cp -iv fsl/tbss_x/swap_voxelwise_32 $FSLDIR/bin/swap_voxelwise
    cp -iv fsl/tbss_x/swap_subjectwise_32 $FSLDIR/bin/swap_subjectwise
  fi  
  cp -iv afni/3dDespike_32 $FSLDIR/bin/3dDespike 
  cp -iv afni/3dTcat_32 $FSLDIR/bin/3dTcat
  cp -iv afni/3dTstat_32 $FSLDIR/bin/3dTstat
  cp -iv afni/3dcalc_32 $FSLDIR/bin/3dcalc
  cp -iv afni/3dDetrend_32 $FSLDIR/bin/3dDetrend
fi

chmod +x $FSLDIR/bin/topup
chmod +x $FSLDIR/bin/applytopup
chmod +x $FSLDIR/bin/swap_voxelwise
chmod +x $FSLDIR/bin/swap_subjectwise
chmod +x $FSLDIR/bin/tbss_x
chmod +x $FREESURFER_HOME/bin/trac-all
chmod +x $FSLDIR/bin/3dTcat
chmod +x $FSLDIR/bin/3dDespike
chmod +x $FSLDIR/bin/3dTstat
chmod +x $FSLDIR/bin/3dcalc
chmod +x $FSLDIR/bin/3dDetrend
chmod +x $FSLDIR/bin/fsl_sub
