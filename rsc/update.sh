#!/bin/bash
# CAVE: for AFNI tools: may need to install or link /usr/lib[64]/libXp.so.6

#set -e

if [ $# -lt 1 ] ; then echo "Usage: update [32|64]" ; exit ; fi

if [ x$FSL_DIR = "x" ] ; then echo "FSL_DIR variable is not defined ! Exiting." ; exit 1 ; fi
if [ x$FREESURFER_HOME = "x" ] ; then echo "FREESURFER_HOME variable is not defined ! Exiting." ; exit 1 ; fi

v5=$(cat $FSL_DIR/etc/fslversion | grep ^5 | wc -l)
if [ $v5 -eq 1 ] ; then
  echo "FSL v.5 detected. Replacing fsl_sub..."
  cp -iv fsl/fsl_sub_v5 $FSL_DIR/bin/fsl_sub # contains a RAM limit
fi

cp -iv fs/trac-all $FREESURFER_HOME/bin/trac-all
cp -iv fsl/MNI152*.nii.gz $FSL_DIR/data/standard/
cp -iv fsl/avg152T1_white_bin.nii.gz $FSL_DIR/data/standard/
cp -iv fsl/avg152T1_csf_bin.nii.gz $FSL_DIR/data/standard/

if [ $v5 -eq 0 ] ; then
  #echo "Don't overwrite for FSL ver. 5 if asked !"
  cp -iv fsl/fsl_sub $FSL_DIR/bin/fsl_sub # contains a RAM limit
  #echo "Don't overwrite for FSL ver. 5 if asked !"
  cp -iv fsl/tbss_x/tbss_x $FSL_DIR/bin/tbss_x # dont overwrite for fsl ver. 5
  #echo "Don't overwrite for FSL ver. 5 if asked!"
  cp -iv fsl/topup/b02b0.cnf $FSL_DIR/etc/flirtsch/b02b0.cnf # dont overwrite for fsl ver. 5
  #echo "Don't overwrite for FSL ver. 5 if asked!"
  cp -iv fsl/featlib.tcl $FSL_DIR/tcl/featlib.tcl # dont overwrite for fsl ver. 5
fi

if [ $1 -eq 64 ] ; then
  if [ $v5 -eq 0 ] ; then
    #echo "Don't overwrite for FSL ver. 5 if asked!"
    cp -iv fsl/topup/topup_64 $FSL_DIR/bin/topup # dont overwrite for fsl ver. 5
    #echo "Don't overwrite for FSL ver. 5 if asked!"
    cp -iv fsl/topup/applytopup_64 $FSL_DIR/bin/applytopup # dont overwrite for fsl ver. 5
    #echo "Don't overwrite for FSL ver. 5 if asked!"
    cp -iv fsl/tbss_x/swap_voxelwise_64 $FSL_DIR/bin/swap_voxelwise # dont overwrite for fsl ver. 5
    #echo "Don't overwrite for FSL ver. 5 if asked!"
    cp -iv fsl/tbss_x/swap_subjectwise_64 $FSL_DIR/bin/swap_subjectwise # dont overwrite for fsl ver. 5
  fi
  
  cp -iv afni/3dDespike_64 $FSL_DIR/bin/3dDespike
  cp -iv afni/3dTcat_64 $FSL_DIR/bin/3dTcat
  cp -iv afni/3dTstat_64 $FSL_DIR/bin/3dTstat
  cp -iv afni/3dcalc_64 $FSL_DIR/bin/3dcalc
  cp -iv afni/3dDetrend_64 $FSL_DIR/bin/3dDetrend
fi

if [ $1 -eq 32 ] ; then
  if [ $v5 -eq 0 ] ; then
    #echo "Don't overwrite for FSL ver. 5 if asked!"
    cp -iv fsl/topup/topup_32 $FSL_DIR/bin/topup # dont overwrite for fsl ver. 5
    #echo "Don't overwrite for FSL ver. 5 if asked!"
    cp -iv fsl/topup/applytopup_32 $FSL_DIR/bin/applytopup # dont overwrite for fsl ver. 5
    #echo "Don't overwrite for FSL ver. 5 if asked!"
    cp -iv fsl/tbss_x/swap_voxelwise_32 $FSL_DIR/bin/swap_voxelwise # dont overwrite for fsl ver. 5
    #echo "Don't overwrite for FSL ver. 5 if asked!"
    cp -iv fsl/tbss_x/swap_subjectwise_32 $FSL_DIR/bin/swap_subjectwise # dont overwrite for fsl ver. 5
  fi 
  
  cp -iv afni/3dDespike_32 $FSL_DIR/bin/3dDespike 
  cp -iv afni/3dTcat_32 $FSL_DIR/bin/3dTcat
  cp -iv afni/3dTstat_32 $FSL_DIR/bin/3dTstat
  cp -iv afni/3dcalc_32 $FSL_DIR/bin/3dcalc
  cp -iv afni/3dDetrend_32 $FSL_DIR/bin/3dDetrend
fi

chmod +x $FSL_DIR/bin/topup
chmod +x $FSL_DIR/bin/applytopup
chmod +x $FSL_DIR/bin/swap_voxelwise
chmod +x $FSL_DIR/bin/swap_subjectwise
chmod +x $FSL_DIR/bin/tbss_x
chmod +x $FREESURFER_HOME/bin/trac-all
chmod +x $FSL_DIR/bin/3dTcat
chmod +x $FSL_DIR/bin/3dDespike
chmod +x $FSL_DIR/bin/3dTstat
chmod +x $FSL_DIR/bin/3dcalc
chmod +x $FSL_DIR/bin/3dDetrend
chmod +x $FSL_DIR/bin/fsl_sub
