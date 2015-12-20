#!/bin/bash
# For internal use only.

# are all required progs / files installed ?
echo "`basename $0` : checking for required progs..."
progs="$FSLDIR/bin/tbss_x $FSLDIR/bin/swap_voxelwise $FSLDIR/bin/swap_subjectwise $FREESURFER_HOME/bin/trac-all $FSLDIR/etc/flirtsch/b02b0.cnf $FSLDIR/bin/topup $FSLDIR/bin/applytopup $FSLDIR/data/standard/avg152T1_white_bin.nii.gz $FSLDIR/data/standard/avg152T1_csf_bin.nii.gz"
for prog in $progs ; do
  if [ ! -f $prog ] ; then echo "`basename $0` : ERROR : '$prog' is not installed. Exiting." ; exit 1 ; fi
done
for prog in xterm octave mktemp dos2unix paste sed awk diff touch tar ; do
  if [ x$(which $prog) = "x" ] ; then echo "`basename $0` : ERROR : '$prog' does not seem to be installed on your system ! Exiting..." ; exit 1 ; fi
done

# is sh linked to bash ?
if [ ! -z $(which sh) ] ; then
  if [ $(basename $(readlink `which sh`)) != "bash" ] ; then read -p "WARNING : 'sh' is linked to $(readlink `which sh`), but should be linked to 'bash' for fsl compatibility. Press key to continue or abort with CTRL-C." ; fi
fi

# done.
echo "`basename $0` : ...done."
