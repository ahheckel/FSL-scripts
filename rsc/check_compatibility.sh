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

# clear screen
clear

# check for differences...
if [ $v5 -eq 1 ] ; then
  cmd="diff $fwdir/fsl/fsl5/fsl_sub_patched $FSLDIR/bin/fsl_sub" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."
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

cmd="diff $fwdir/fs/orig_read_label.m $FREESURFER_HOME/matlab/read_label.m" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."

#cmd="diff $fwdir/fs/trac-all $FREESURFER_HOME/bin/trac-all" ; $cmd ;  echo "`basename $0` : ************************** $cmd **************************" ; read -p "Press Key..."

# are all required progs / files installed ?
$(dirname $0)/scripts/_check_progs.sh

# done
echo "`basename $0` : done."
