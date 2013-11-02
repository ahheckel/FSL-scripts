#!/bin/bash
# Checks currently installed FSL/Freesurfer core files for differences with the files used/expected by the framework.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/01/2013

fwdir="$(dirname $0)"

# check version
v5=$(cat $FSLDIR/etc/fslversion | grep ^5 | wc -l)

# check for differences...
if [ $v5 -eq 1 ] ; then
  cmd="diff $fwdir/fsl/fsl5/fsl_sub_v5_patched $FSLDIR/bin/fsl_sub" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
fi

if [ $v5 -eq 0 ] ; then
  cmd="diff $fwdir/fsl/fsl4/featlib_v4.tcl $FSLDIR/tcl/featlib.tcl" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
  cmd="diff $fwdir/fsl/fsl4/fsl_sub_v4 $FSLDIR/bin/fsl_sub" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
  cmd="diff $fwdir/fsl/fsl4/topup/b02b0.cnf $FSLDIR/etc/flirtsch/b02b0.cnf" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
fi

cmd="diff $fwdir/fsl/orig/fslvbm_1_bet $FSLDIR/bin/fslvbm_1_bet" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
cmd="diff $fwdir/fsl/orig/fslvbm_2_template $FSLDIR/bin/fslvbm_2_template" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
cmd="diff $fwdir/fsl/orig/fslvbm_3_proc $FSLDIR/bin/fslvbm_3_proc" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."

cmd="diff $fwdir/fsl/orig/tbss_1_preproc $FSLDIR/bin/tbss_1_preproc" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
cmd="diff $fwdir/fsl/orig/tbss_2_reg $FSLDIR/bin/tbss_2_reg" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
cmd="diff $fwdir/fsl/orig/tbss_3_postreg $FSLDIR/bin/tbss_3_postreg" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
cmd="diff $fwdir/fsl/orig/tbss_4_prestats $FSLDIR/bin/tbss_4_prestats" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."

cmd="diff $fwdir/fsl/orig/tbss_x $FSLDIR/bin/tbss_x" ; $cmd ; echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."

cmd="diff $fwdir/fsl/orig/dual_regression $FSLDIR/bin/dual_regression" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."

#cmd="diff $fwdir/fs/trac-all $FREESURFER_HOME/bin/trac-all" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."

# are all progs / files installed ?
echo "`basename $0` : checking for required progs..."
progs="$FSLDIR/bin/tbss_x $FSLDIR/bin/swap_voxelwise $FSLDIR/bin/swap_subjectwise $FREESURFER_HOME/bin/trac-all $FSLDIR/etc/flirtsch/b02b0.cnf $FSLDIR/bin/topup $FSLDIR/bin/applytopup $FSLDIR/data/standard/avg152T1_white_bin.nii.gz $FSLDIR/data/standard/avg152T1_csf_bin.nii.gz"
for prog in $progs ; do
  if [ ! -f $prog ] ; then echo "`basename $0` : ERROR : '$prog' is not installed. Exiting." ; exit 1 ; fi
done
for prog in octave 3dDespike 3dDetrend 3dTcat mktemp dos2unix ; do
  if [ x$(which $prog) = "x" ] ; then echo "`basename $0` : ERROR : '$prog' does not seem to be installed on your system ! Exiting..." ; exit 1 ; fi
done

# is sh linked to bash ?
if [ ! -z $(which sh) ] ; then
  if [ $(basename $(readlink `which sh`)) != "bash" ] ; then read -p "`basename $0` : WARNING : 'sh' is linked to $(readlink `which sh`), but should be linked to 'bash' for fsl compatibility. Press key to continue or abort with CTRL-C." ; fi
fi

# done
echo "`basename $0` : done."
