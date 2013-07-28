#!/bin/bash
# Installs required files.
# CAVE: for AFNI tools: may need to install or link /usr/lib[64]/libXp.so.6

#set -e

if [ $# -lt 1 ] ; then echo "Usage: update [32|64]" ; exit 1 ; fi

if [ x$FSLDIR = "x" ] ; then echo "FSLDIR variable is not defined ! Exiting." ; exit 1 ; fi
if [ x$FREESURFER_HOME = "x" ] ; then echo "FREESURFER_HOME variable is not defined ! Exiting." ; exit 1 ; fi

clear

# display dir. variables
echo ""
echo "FSLDIR:                   '$FSLDIR'"
echo "FREESURFER_HOME:          '$FREESURFER_HOME'"
# display FSL version
fslversion=$(cat $FSLDIR/etc/fslversion)
echo "FSL version:              '${fslversion}'." ; # sleep 1
v5=$(cat $FSLDIR/etc/fslversion | grep ^5 | wc -l)
# display FREESURFER version
echo "FREESURFER build-stamp:   '`cat $FREESURFER_HOME/build-stamp.txt`'."
# wait to check
echo ""
read -p "press Key to continue..."
echo ""

#cp -iv fs/trac-all $FREESURFER_HOME/bin/trac-all
cp -iv fsl/fsl5/fsl_sub_v5_patched $FSLDIR/bin/fsl_sub # contains a RAM limit and JOB-ID redirection, should also work for FSL < v.5
cp -iv fsl/templates/MNI152*.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/avg152T1_white_bin.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/avg152T1_csf_bin.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/rsn10*.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/rsn8*.nii.gz $FSLDIR/data/standard/

if [ $v5 -eq 0 ] ; then # dont overwrite for fsl ver. 5
  #cp -iv fsl/fsl_sub_v4 $FSLDIR/bin/fsl_sub # contains a RAM limit
  cp -iv fsl/fsl4/tbss_x/tbss_x $FSLDIR/bin/tbss_x
  cp -iv fsl/fsl4/topup/b02b0.cnf $FSLDIR/etc/flirtsch/b02b0.cnf
  cp -iv fsl/fsl4/featlib_v4.tcl $FSLDIR/tcl/featlib.tcl
  cp -iv fsl/fsl4/slices_summary $FSLDIR/bin/ # this one is needed for FSLNets
fi

if [ $1 -eq 64 ] ; then
  if [ $v5 -eq 0 ] ; then # dont overwrite for fsl ver. 5
    cp -iv fsl/fsl4/topup/topup_64 $FSLDIR/bin/topup
    cp -iv fsl/fsl4/topup/applytopup_64 $FSLDIR/bin/applytopup 
    cp -iv fsl/fsl4/tbss_x/swap_voxelwise_64 $FSLDIR/bin/swap_voxelwise
    cp -iv fsl/fsl4/tbss_x/swap_subjectwise_64 $FSLDIR/bin/swap_subjectwise
  fi  
  cp -iv afni/3dDespike_64 $FSLDIR/bin/3dDespike
  cp -iv afni/3dTcat_64 $FSLDIR/bin/3dTcat
  cp -iv afni/3dTstat_64 $FSLDIR/bin/3dTstat
  cp -iv afni/3dcalc_64 $FSLDIR/bin/3dcalc
  cp -iv afni/3dDetrend_64 $FSLDIR/bin/3dDetrend
fi

if [ $1 -eq 32 ] ; then
  if [ $v5 -eq 0 ] ; then # dont overwrite for fsl ver. 5
    cp -iv fsl/fsl4/topup/topup_32 $FSLDIR/bin/topup 
    cp -iv fsl/fsl4/topup/applytopup_32 $FSLDIR/bin/applytopup
    cp -iv fsl/fsl4/tbss_x/swap_voxelwise_32 $FSLDIR/bin/swap_voxelwise
    cp -iv fsl/fsl4/tbss_x/swap_subjectwise_32 $FSLDIR/bin/swap_subjectwise
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
#chmod +x $FREESURFER_HOME/bin/trac-all
chmod +x $FSLDIR/bin/3dTcat
chmod +x $FSLDIR/bin/3dDespike
chmod +x $FSLDIR/bin/3dTstat
chmod +x $FSLDIR/bin/3dcalc
chmod +x $FSLDIR/bin/3dDetrend
chmod +x $FSLDIR/bin/fsl_sub
chmod +x $FSLDIR/bin/slices_summary
mkdir $FREESURFER_HOME/subjects/fsaverage/tmp ; chmod 777 $FREESURFER_HOME/subjects/fsaverage/tmp # need write access so that cursor postion in tksurfer/tkmedit can be saved ! (!)
if [ -f $FREESURFER_HOME/bin/fsl_sub_mgh ] ; then # for TRACULA
  if [ "$(readlink $FREESURFER_HOME/bin/fsl_sub_mgh)" != "$FSLDIR/bin/fsl_sub" ] ; then
    mv -iv $FREESURFER_HOME/bin/fsl_sub_mgh $FREESURFER_HOME/bin/fsl_sub_mgh_sav
    ln -vsi $FSLDIR/bin/fsl_sub $FREESURFER_HOME/bin/fsl_sub_mgh
  fi
fi
if [ -f $FREESURFER_HOME/bin/fsl_sub_seychelles ] ; then # for TRACULA
  if [ "$(readlink $FREESURFER_HOME/bin/fsl_sub_seychelles)" != "$FSLDIR/bin/fsl_sub" ] ; then
    mv -iv $FREESURFER_HOME/bin/fsl_sub_seychelles $FREESURFER_HOME/bin/fsl_sub_seychelles_sav
    ln -vsi $FSLDIR/bin/fsl_sub $FREESURFER_HOME/bin/fsl_sub_seychelles
  fi
fi
#ln -vsi ./bedpostx $FSLDIR/bin/bedpostx_seychelles # for TRACULA
