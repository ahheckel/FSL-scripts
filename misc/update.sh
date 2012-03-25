#!/bin/bash

#set -e

if [ $# -lt 1 ] ; then echo "Usage: update [32|64]" ; exit ; fi

cp -iv fsl/tbss_x/tbss_x $FSL_DIR/bin/tbss_x
cp -iv fs/trac-all $FREESURFER_HOME/bin/trac-all
cp -iv fsl/topup/b02b0.cnf $FSL_DIR/etc/flirtsch/b02b0.cnf
cp -iv fsl/MNI_T1_4mm_brain.nii.gz $FSL_DIR/data/standard/

if [ $1 -eq 64 ] ; then

  cp -iv fsl/topup/topup_blade $FSL_DIR/bin/topup
  cp -iv fsl/topup/applytopup_blade $FSL_DIR/bin/applytopup
  cp -iv fsl/tbss_x/swap_voxelwise_64 $FSL_DIR/bin/swap_voxelwise
  cp -iv fsl/tbss_x/swap_subjectwise_64 $FSL_DIR/bin/swap_subjectwise

fi

if [ $1 -eq 32 ] ; then

  cp -iv fsl/topup/topup_32 $FSL_DIR/bin/topup
  cp -iv fsl/topup/applytopup_32 $FSL_DIR/bin/applytopup
  cp -iv fsl/tbss_x/swap_voxelwise_32 $FSL_DIR/bin/swap_voxelwise
  cp -iv fsl/tbss_x/swap_subjectwise_32 $FSL_DIR/bin/swap_subjectwise

fi
