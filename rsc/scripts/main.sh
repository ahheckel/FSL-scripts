#!/bin/bash

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 12/01/2012

echo "---------------------------"

# check if superuser
if [ "$(id -u)" = "0" ]; then
   echo "$(basename $0): This script must not be run as root !" 1>&2
   exit 1
fi

# echo date
startdate=$(date) ; echo "'$0' started on ${startdate}."
startdate_sec=$(date +"%s")

# exit on error
set -e

# define error trap
trap 'finishdate_sec=$(date +"%s") ; diff=$(($finishdate_sec-$startdate_sec)) ; echo "$0 : An ERROR has occured on `date` (Job-Id : $$). Time elapsed since start: $(echo "scale=4 ; $diff / 3600" | bc -l) h ($(echo "scale=0 ; $diff / 60" | bc -l) min)"' ERR # don't exit on trap (!)

# define and change to working directory
wd=$(dirname $0); cd $wd ; wd=`pwd`

# display FSL version
if [ x$FSL_DIR = "x" ] ; then FSL_DIR="$FSLDIR" ; fi
if [ x$FSL_DIR = "x" ] ; then echo "ERROR : \$FSL_DIR and \$FSLDIR variable not defined - exiting."  ; exit 1 ; fi
fslversion=$(cat $(dirname $(dirname `which imglob`))/etc/fslversion)
echo ""; echo "FSL version is ${fslversion}." ; echo "" ; # sleep 1

# display Job-Id
echo "Job-Id : $$" ; echo ""

# source environment variables
if [ ! -f ./globalvars ] ; then echo "ERROR: 'globalvars' not found - exiting." ; exit 1 ; fi
source ./globalvars

# define subdirs
scriptdir=$studydir/rsc/scripts
tmpltdir=$studydir/rsc/templates
tmpdir=$studydir/.tmp

# source environment functions
source $scriptdir/globalfuncs

# check for RAM dumps
dumps=$(find ./ -maxdepth 2 -name "core*")
if [ $(echo $dumps | wc -w) -gt 0 ] ; then
  echo "ERROR: memory dumps (core-files) detected - you should look into this. Exiting... "
  echo $dumps | row2col
  exit 1
fi

# create and check lock
set +e
  lock="$wd/.lockdir121978"
  echo "creating lock [ '$lock' ]"
  mkdir $lock &>/dev/null  
  if [ $? -gt 0 ] ; then echo "$0 : --> another instance is already running - exiting." ; exit 1 ; fi
  lock=""
  echo ""
set -e

# export JOB-ID variable, if fsl_sub is patched accordingly
if [ $(cat `which fsl_sub` | grep GRID_JOB_ID_FILE | grep HKL | wc -l) -eq 3 -a x"$SGE_ROOT" != "x" ] ; then
  GRID_JOB_ID_FILE=$wd/.jid.grid.$$
  echo "touching job-ID file '$GRID_JOB_ID_FILE'" ; echo ""
  touch $GRID_JOB_ID_FILE
  export GRID_JOB_ID_FILE
fi

# create subjects-dir.
mkdir -p $subjdir

# remove lock on exit
trap "set +e ; delJIDs $GRID_JOB_ID_FILE ; save_config $studydir $subjdir \"$startdate\" ; rmdir $wd/.lockdir121978 ; echo \"Lock removed.\" ; time_elapsed $startdate_sec ; echo \"Exiting on `date`\" ; echo --------------------------- ; exit" EXIT

# remove duplicates in string arrays (to avoid collisions on the cluster)
FIRSTLEV_SUBJECTS=$(echo $FIRSTLEV_SUBJECTS | row2col | sort -u)
FIRSTLEV_SESSIONS_FUNC=$(echo $FIRSTLEV_SESSIONS_FUNC | row2col | sort -u)
FIRSTLEV_SESSIONS_STRUC=$(echo $FIRSTLEV_SESSIONS_STRUC | row2col | sort -u)
SECONDLEV_SUBJECTS_SUBJECTS=$(echo $SECONDLEV_SUBJECTS_SUBJECTS | row2col | sort -u)
SECONDLEV_SUBJECTS_SESSIONS_FUNC=$(echo $SECONDLEV_SUBJECTS_SESSIONS_FUNC | row2col | sort -u)
SECONDLEV_SUBJECTS_SESSIONS_STRUC=$(echo $SECONDLEV_SUBJECTS_SESSIONS_STRUC | row2col | sort -u)
BOLD_SLICETIMING_VALUES=$(echo $BOLD_SLICETIMING_VALUES | row2col | sort -u)
BOLD_SMOOTHING_KRNLS=$(echo $BOLD_SMOOTHING_KRNLS | row2col | sort -u)
BOLD_HPF_CUTOFFS=$(echo $BOLD_HPF_CUTOFFS | row2col | sort -u)
BOLD_DENOISE_SMOOTHING_KRNLS=$(echo $BOLD_DENOISE_SMOOTHING_KRNLS | row2col | sort -u)
BOLD_DENOISE_MASKS_NAT=$(echo $BOLD_DENOISE_MASKS_NAT | row2col | sort -u)
BOLD_DENOISE_MASKS_MNI=$(echo $BOLD_DENOISE_MASKS_MNI | row2col | sort -u)
BOLD_DENOISE_USE_MOVPARS_NAT=$(echo $BOLD_DENOISE_USE_MOVPARS_NAT | row2col | sort -u)
BOLD_DENOISE_USE_MOVPARS_MNI=$(echo $BOLD_DENOISE_USE_MOVPARS_MNI | row2col | sort -u)
BOLD_MNI_RESAMPLE_FUNCDATAS=$(echo $BOLD_MNI_RESAMPLE_FUNCDATAS | row2col | sort -u)
BOLD_MNI_RESAMPLE_RESOLUTIONS=$(echo $BOLD_MNI_RESAMPLE_RESOLUTIONS | row2col | sort -u)
ALFF_DENOISE_MASKS_NAT=$(echo $ALFF_DENOISE_MASKS_NAT | row2col | sort -u)
ALFF_DENOISE_USE_MOVPARS_NAT=$(echo $ALFF_DENOISE_USE_MOVPARS_NAT | row2col | sort -u)
ALFF_RESAMPLING_RESOLUTIONS=$(echo $ALFF_RESAMPLING_RESOLUTIONS | row2col | sort -u)
TBSS_INCLUDED_SUBJECTS=$(echo $TBSS_INCLUDED_SUBJECTS | row2col | sort -u)
TBSS_INCLUDED_SESSIONS=$(echo $TBSS_INCLUDED_SESSIONS | row2col | sort -u)
TBSS_THRES=$(echo $TBSS_THRES | row2col | sort -u)
FS_STATS_MEASURES=$(echo $FS_STATS_MEASURES | row2col | sort -u)
FS_STATS_SMOOTHING_KRNLS=$(echo $FS_STATS_SMOOTHING_KRNLS | row2col | sort -u)
VBM_INCLUDED_SUBJECTS=$(echo $VBM_INCLUDED_SUBJECTS | row2col | sort -u)
VBM_INCLUDED_SESSIONS=$(echo $VBM_INCLUDED_SESSIONS | row2col | sort -u)
VBM_SMOOTHING_KRNL=$(echo $VBM_SMOOTHING_KRNL | row2col | sort -u)
MELODIC_INCLUDED_SUBJECTS=$(echo $MELODIC_INCLUDED_SUBJECTS | row2col | sort -u)
MELODIC_INCLUDED_SESSIONS=$(echo $MELODIC_INCLUDED_SESSIONS | row2col | sort -u)
MELODIC_CMD_INPUT_FILES=$(echo $MELODIC_CMD_INPUT_FILES | row2col | sort -u)
MELODIC_CMD_INCLUDED_SUBJECTS=$(echo $MELODIC_CMD_INCLUDED_SUBJECTS | row2col | sort -u)
MELODIC_CMD_INCLUDED_SESSIONS=$(echo $MELODIC_CMD_INCLUDED_SESSIONS | row2col | sort -u)
DUALREG_INCLUDED_SUBJECTS=$(echo $DUALREG_INCLUDED_SUBJECTS | row2col | sort -u)
DUALREG_INCLUDED_SESSIONS=$(echo $DUALREG_INCLUDED_SESSIONS | row2col | sort -u)
DUALREG_INPUT_ICA_DIRNAMES=$(echo $DUALREG_INPUT_ICA_DIRNAMES | row2col | sort -u)
DUALREG_IC_FILENAMES=$(echo $DUALREG_IC_FILENAMES | row2col | sort -u)
DUALREG_INPUT_BOLD_FILES=$(echo $DUALREG_INPUT_BOLD_FILES | row2col | sort -u)
FSLNETS_DREGDIRS=$(echo $FSLNETS_DREGDIRS | row2col | sort -u)

# define denoise tags
_m=$(for i in $BOLD_DENOISE_MASKS_NAT ; do remove_ext $i | cut -d _ -f 2 ; done) ; dntag_boldnat=$(rem_blanks "$BOLD_DENOISE_USE_MOVPARS_NAT")$(rem_blanks "$_m")
_m=$(for i in $BOLD_DENOISE_MASKS_MNI ; do remove_ext $i | cut -d _ -f 2 ; done) ; dntag_boldmni=$(rem_blanks "$BOLD_DENOISE_USE_MOVPARS_MNI")$(rem_blanks "$_m")
_m=$(for i in $ALFF_DENOISE_MASKS_NAT ; do remove_ext $i | cut -d _ -f 2 ; done) ; dntag_alff=$(rem_blanks "$ALFF_DENOISE_USE_MOVPARS_NAT")$(rem_blanks "$_m")


# ----- create 1st level subject- and session files -----

if [ "x$FIRSTLEV_SUBJECTS" != "x" -a "x$FIRSTLEV_SESSIONS_FUNC" != "x" -a "x$FIRSTLEV_SESSIONS_STRUC" != "x" ] ; then
  echo "creating subjects file..."
  
  #errflag=0
  #for i in $FIRSTLEV_SUBJECTS ; do if [ ! -d ${subjdir}/$i ] ; then errflag=1 ; echo "ERROR: '${subjdir}/$i' does not exist!" ; fi ; done
  #if [ $errflag -eq 1 ] ; then echo "...exiting." ; exit 1 ; fi
  
  echo $FIRSTLEV_SUBJECTS | row2col > ${subjdir}/subjects
  cat -n ${subjdir}/subjects
  for subj in `cat ${subjdir}/subjects` ; do
    if [ ! -d ${subjdir}/$subj ] ; then mkdir -p ${subjdir}/$subj ; fi
    echo "creating functional session file for subject '$subj': "[ $FIRSTLEV_SESSIONS_FUNC ]""
    echo $FIRSTLEV_SESSIONS_FUNC | row2col > ${subjdir}/$subj/sessions_func
    echo "creating structural session file for subject '$subj': "[ $FIRSTLEV_SESSIONS_STRUC ]""
    echo $FIRSTLEV_SESSIONS_STRUC | row2col > ${subjdir}/$subj/sessions_struc
  done
  echo ""
fi

# ----- CHECKS -----

# are all progs / files installed ?
progs="$FSL_DIR/bin/tbss_x $FSL_DIR/bin/swap_voxelwise $FSL_DIR/bin/swap_subjectwise $FREESURFER_HOME/bin/trac-all $FSL_DIR/etc/flirtsch/b02b0.cnf $FSL_DIR/bin/topup $FSL_DIR/bin/applytopup $FSL_DIR/data/standard/avg152T1_white_bin.nii.gz $FSL_DIR/data/standard/avg152T1_csf_bin.nii.gz"
for prog in $progs ; do
  if [ ! -f $prog ] ; then echo "ERROR : '$prog' is not installed. Exiting." ; exit 1 ; fi
done
for prog in octave 3dDespike 3dDetrend 3dTcat ; do
  if [ x$(which $prog) = "x" ] ; then echo "ERROR : '$prog' does not seem to be installed on your system ! Exiting..." ; exit 1 ; fi
done

# is sh linked to bash ?
if [ ! -z $(which sh) ] ; then
  if [ $(basename $(readlink `which sh`)) != "bash" ] ; then read -p "WARNING : 'sh' is linked to $(readlink `which sh`), but should be linked to 'bash' for fsl compatibility. Press key to continue or abort with CTRL-C." ; fi
fi

## make scripts executable
#dos2unix -q $scriptdir/*
#chmod +x $scriptdir/*.sh

# check presence of info files
if [ $CHECK_INFOFILES = 1 ] ; then 
  # is subjects file present ?
  if [ ! -f ${subjdir}/subjects ] ; then 
    echo "Subjects file not present - proposal:"
    cd  $subjdir
      files=`find ./?* -maxdepth 0 -type d | sort | cut -d / -f 2 | grep -v $(basename $FS_subjdir) | grep -v $(basename $FS_sessdir)`
      for i in $files ; do echo $i ; done
      read -p "Press Key to accept these entries, otherwise abort with Conrol-C..."
      echo $files | row2col > subjects
      files=""
    cd $wd
  fi
  # is sessions file present ? (in case of multisession designs)
  for subj in `cat ${subjdir}/subjects` ; do
    if [ ! -f $subjdir/$subj/sessions_struc -o ! -f $subjdir/$subj/sessions_func ] ; then
      if [ $(find $subjdir/$subj/ -maxdepth 1 -type d | wc -l) -eq 1 ] ; then
        echo "WARNING : No session files detected. Since no subdirectories in $subjdir/$subj were detected -> assuming single session design. Now creating empty session files..."
        echo '.' > $subjdir/$subj/sessions_struc 
        echo '.' > $subjdir/$subj/sessions_func
        echo "done."
      fi
    fi
    if [ ! -f ${subjdir}/${subj}/sessions_struc ] ; then
      read -p "Session File for structural processing not present in ${subjdir}/${subj}. You will need to create that file. Exiting..." ; exit 1 ; 
    fi
    if [ ! -f ${subjdir}/${subj}/sessions_func ] ; then
      read -p "Session File for functional processing not present in ${subjdir}/${subj}. You will need to create that file. Exiting..." ; exit 1 ; 
    fi
  done

  # are bet info present ?
  if [ ! -f ${subjdir}/config_bet_lowb ] ; then
    read -p "Bet info file for the diffusion images not present in ${subjdir}. Press Key to create the default template."
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_struc` ; do echo "$(subjsess) $BETLOWB_INFO" | tee -a $subjdir/config_bet_lowb ; done ; done
  fi
  if [ ! -f ${subjdir}/config_bet_magn ] ; then
    read -p "Bet info file for the magnitude images not present in ${subjdir}. Press Key to create the default template."
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_* | sort | uniq` ; do echo "$(subjsess) $BETMAGN_INFO" | tee -a $subjdir/config_bet_magn ; done ; done
  fi
  if [ ! -f ${subjdir}/config_bet_struc0 ] ; then
    read -p "Bet info file for the structural images (prae - std. space masking) not present in ${subjdir}. Press Key to create the default template."
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_struc` ; do echo "$(subjsess) $BETSTRUC0_INFO" | tee -a $subjdir/config_bet_struc0 ; done ; done
  fi
  if [ ! -f ${subjdir}/config_bet_struc1 ] ; then
    read -p "Bet info file for the structural images (post - std. space masking) not present in ${subjdir}. Press Key to create the default template."
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_struc` ; do echo "$(subjsess) $BETSTRUC1_INFO" | tee -a $subjdir/config_bet_struc1 ; done ; done
  fi
  if [ ! -f ${subjdir}/config_unwarp_dwi ] ; then
    read -p "DWI-unwarp info file for diffusion images not present in ${subjdir}. Press Key to create the default template."
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_struc` ; do echo "$(subjsess) $DWIUNWARP_INFO" | tee -a $subjdir/config_unwarp_dwi ; done ; done
  fi
  if [ ! -f ${subjdir}/config_unwarp_bold ] ; then
    read -p "BOLD-unwarp info file not present in ${subjdir}. Press Key to create the default template."
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_func` ; do echo "$(subjsess) $BOLDUNWARP_INFO" | tee -a $subjdir/config_unwarp_bold ; done ; done
  fi
  
  # check acquisition-parameter files
  if [ ! -f ${subjdir}/config_acqparams_bold ] ; then
    read -p "BOLD acquisition parameter info file not present in ${subjdir}. Press Key to create a template."
    err=0 ;
    if [ x$TR_bold = x ] ; then echo "ERROR: TR not defined (need dummy at least)." ; err=1 ; fi
    if [ x$TE_bold = x ] ; then echo "ERROR: TE not defined (need dummy at least)." ; err=1 ; fi
    if [ x$EES_bold = x ] ; then echo "ERROR: ESP not defined (need dummy at least)." ; err=1 ; fi
    if [ $err -eq 1 ] ; then exit 1 ; fi
    printf "#ID\t TR (s)\t TE (ms)\t	EES (ms)\n" > ${subjdir}/config_acqparams_bold
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_func` ; do printf "$(subjsess)\t $TR_bold\t $TE_bold\t $EES_bold\n" | tee -a $subjdir/config_acqparams_bold ; done ; done
  fi    
  if [ ! -f ${subjdir}/config_acqparams_dwi ] ; then
    read -p "DWI acquisition parameter info file not present in ${subjdir}. Press Key to create a template."
    err=0 ;
    if [ x$TR_diff = x ] ; then echo "ERROR: TR not defined (need dummy at least)." ; err=1 ; fi
    if [ x$TE_diff = x ] ; then echo "ERROR: TE not defined (need dummy at least)." ; err=1 ; fi
    if [ x$EES_diff = x ] ; then echo "ERROR: ESP not defined (need dummy at least)." ; err=1 ; fi
    if [ x$TROT_topup = x ] ; then echo "ERROR: TROT (topup) not defined (need dummy at least)." ; err=1 ; fi
    if [ $err -eq 1 ] ; then exit 1 ; fi
    printf "#ID\t TR (s)\t TE (ms)\t	EES (ms)\t TOPUP-TROT (s)\n" > ${subjdir}/config_acqparams_dwi
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_struc` ; do printf "$(subjsess)\t $TR_diff\t $TE_diff\t $EES_diff\t $TROT_topup\n" | tee -a $subjdir/config_acqparams_dwi ; done ; done
  fi
  
  # are params defined as global variables ? if vars are empty -> set flag, so that params are retrieved from info files.
  getTR_bold=0 ; getTE_bold=0 ; getEES_bold=0
  getTR_diff=0 ; getTE_diff=0 ; getEES_diff=0 ; getTROT_topup=0
  if [ x$TR_bold = x ] ; then getTR_bold=1 ; fi
  if [ x$TE_bold = x ] ; then getTE_bold=1 ; fi
  if [ x$EES_bold = x ] ; then getEES_bold=1 ; fi
  if [ x$TR_diff = x ] ; then getTR_diff=1 ; fi
  if [ x$TE_diff = x ] ; then getTE_diff=1 ; fi
  if [ x$EES_diff = x ] ; then getEES_diff=1 ; fi
  if [ x$TROT_topup = x ] ; then getTROT_topup=1 ; fi
  echo "checking acquisition parameters in info files..."
  for subj in `cat $subjdir/subjects`; do 
    for sess in `cat $subjdir/$subj/sessions_func` ; do
      #echo "subj $subj , sess $sess : checking '$subjdir/config_acqparams_bold'"
      defineBOLDparams $subjdir/config_acqparams_bold $subj $sess 
    done
  done
  for subj in `cat $subjdir/subjects`; do 
    for sess in `cat $subjdir/$subj/sessions_struc` ; do
      #echo "subj $subj , sess $sess : checking '$subjdir/config_acqparams_dwi'"
      defineDWIparams $subjdir/config_acqparams_dwi $subj $sess 
    done
  done
  echo "done." ; echo ""
  
  # is registration mapping file present ? 
  if [ ! -f ${subjdir}/config_func2highres.reg ] ; then
    echo "Registration mapping between functionals and t1 structural not found. You may need to create that file..."
    subj=`head -n 1 $subjdir/subjects`
    if [ $(find $srcdir/$subj/ -maxdepth 1 -type d | wc -l) -eq 1 ] ; then
      read -p "No subdirectories in $subjdir/$subj detected - assuming single session design. Press Key to create default func->highres mapping for single session designs..."
      for i in $(cat $subjdir/subjects) ; do
        echo "$i ." >> $subjdir/config_func2highres.reg
      done
      echo "done."
    fi
    subj=""
  fi
  
  # are template files present?
  if [ ! -f ${tmpltdir}/template_tracula.rc ] ; then
    read -p "TRACULA template file not found. You may need to create that file..."  
  fi
  if [ ! -f ${tmpltdir}/template_preprocBOLD.fsf ] ; then
    read -p "FEAT template file for BOLD preprocessing not found. You may need to create that file..."  
  fi
  if [ ! -f ${tmpltdir}/template_unwarpDWI.fsf ] ; then
    read -p "FEAT template file for DWI unwarping not found. You may need to create that file..."  
  fi
  if [ ! -f ${tmpltdir}/template_makeXfmMatrix.m ] ; then 
    read -p "WARNING: OCTAVE file 'template_makeXfmMatrix.m' not found. You will need that file for TOPUP-related b-vector correction. Press key to continue..."
  fi
  if [ ! -f ${tmpltdir}/template_gICA.fsf ] ; then
    read -p "WARNING: MELODIC template file not found. You may need to create that file..." 
  fi
fi

# are all subjects registered in infofiles ?
errpause=0
# ...in func. infofiles
for infofile in config_bet_magn config_unwarp_bold config_func2highres.reg ; do
  for subj in `cat $subjdir/subjects` ; do
    errflag=0
    
    for sess in `cat $subjdir/$subj/sessions_func` ; do
      if [ $sess = "." ] ; then sess="" ; fi
      
      line=$(cat $subjdir/$infofile | awk '{print $1}' | grep -nx $(subjsess) || true)
      if [ "x$line" = "x" ] ; then 
        errflag=1
        #echo "WARNING : '$infofile' : entry for id '$(subjsess)' not found ! This may or may not be a problem depending on your setup."
      fi
    done
    
    if [ $errflag -eq 1 ] ; then
      line=$(cat $subjdir/$infofile | awk '{print $1}' | grep -nx ${subj} || true)
      if [ "x$line" = "x" ] ; then 
        errpause=1
        echo "WARNING : '$infofile' : entry for subject '${subj}' not found ! This may or may not be a problem depending on your setup."
        if [ $infofile = "config_bet_magn" ] ; then read -p "Press key to add default value." ; echo "$subj $BETMAGN_INFO" | tee -a ${subjdir}/$infofile ; fi
        if [ $infofile = "config_unwarp_bold" ] ; then read -p "Press key to add default value." ; echo "$subj $DWIUNWARP_INFO" | tee -a ${subjdir}/$infofile ; fi
        if [ $infofile = "config_func2highres.reg" -a "$(cat ${subjdir}/${subj}/sessions_* | sort | uniq)" = "." ] ; then read -p "Press key to add default value." ; echo "$subj ." | tee -a ${subjdir}/$infofile ; fi
      fi
    fi    
  done
done
# ...in struc. infofiles
for infofile in config_bet_lowb config_bet_struc0 config_bet_struc1 config_unwarp_dwi ; do
  for subj in `cat $subjdir/subjects` ; do
    errflag=0
    
    for sess in `cat $subjdir/$subj/sessions_struc` ; do
      if [ $sess = "." ] ; then sess="" ; fi
      
      line=$(cat $subjdir/$infofile | awk '{print $1}' | grep -nx $(subjsess) || true)
      if [ "x$line" = "x" ] ; then 
        errflag=1
        #echo "WARNING : '$infofile' : entry for id '$(subjsess)' not found ! This may or may not be a problem depending on your setup."
      fi
    done
    
    if [ $errflag -eq 1 ] ; then
      line=$(cat $subjdir/$infofile | awk '{print $1}' | grep -nx ${subj} || true)
      if [ "x$line" = "x" ] ; then
        errpause=1
        echo "WARNING : '$infofile' : entry for subject '${subj}' not found ! This may or may not be a problem depending on your setup."
        if [ $infofile = "config_bet_lowb" ] ; then read -p "Press key to add default value." ; echo "$subj $BETLOWB_INFO" | tee -a ${subjdir}/$infofile ; fi
        if [ $infofile = "config_bet_struc0" ] ; then read -p "Press key to add default value." ; echo "$subj $BETSTRUC0_INFO" | tee -a ${subjdir}/$infofile ; fi
        if [ $infofile = "config_bet_struc1" ] ; then read -p "Press key to add default value." ; echo "$subj $BETSTRUC1_INFO" | tee -a ${subjdir}/$infofile ; fi
        if [ $infofile = "config_unwarp_dwi" ] ; then read -p "Press key to add default value." ; echo "$subj $DWIUNWARP_INFO" | tee -a ${subjdir}/$infofile ; fi
      fi
    fi    
  done
done
if [ $errpause -eq 1 ] ; then echo "" ; echo "***CHECK*** (sleeping 2 seconds)..." ; sleep 2 ; echo "" ; fi

# list input files for each subject and session
checklist=""
if [ ! "x$pttrn_diffs" = "x" ] ;  then checklist=$checklist" "$pttrn_diffs  ; else checklist=$checklist" "0 ; fi
if [ ! "x$pttrn_bvals" = "x" ] ;  then checklist=$checklist" "$pttrn_bvals  ; else checklist=$checklist" "0 ; fi
if [ ! "x$pttrn_bvecs" = "x" ] ;  then checklist=$checklist" "$pttrn_bvecs  ; else checklist=$checklist" "0 ; fi
if [ ! "x$pttrn_strucs" = "x" ] ; then checklist=$checklist" "$pttrn_strucs ; else checklist=$checklist" "0 ; fi
if [ ! "x$pttrn_fmaps" = "x" ] ;  then checklist=$checklist" "$pttrn_fmaps  ; else checklist=$checklist" "0 ; fi
if [ ! "x$pttrn_bolds" = "x" ] ;  then checklist=$checklist" "$pttrn_bolds  ; else checklist=$checklist" "0 ; fi
# header line
for subj in `cat $subjdir/subjects` ; do
  for sess in `cat $subjdir/$subj/sessions_* | sort | uniq` ; do
    nchars=`printf "%3i subj %s , sess %s :" 1 $subj $sess`
    nchars=${#nchars}
    break
  done
done
printf "%${nchars}s   DWI  BVAL BVEC STRC FMAP BOLD \n"
# cycle through...
n=1
for subj in `cat $subjdir/subjects` ; do
  for sess in `cat $subjdir/$subj/sessions_* | sort | uniq` ; do
    out=""
    for i in $checklist ; do
      if [ $i = "0" ] ; then
        out=$out"    "0
      else
        out=$out"    "$(ls $srcdir/$subj/$sess/$i 2>/dev/null | wc -l)
      fi
    done
    printf "%3i subj %s , sess %s :%s \n" $n $subj $sess "$out"
    n=$[$n+1]
  done
done

# display selected modules
echo "" ; echo "1ST LEVEL processing streams selected:"
echo -n "--- Scratch   :    " ; [ $SCRATCH = 1 ] && echo -n "SCRATCH " ; echo ""
echo -n "--- FMAP      :    " ; [ $FIELDMAP_STG1 = 1 ] && echo -n "STG1 " ; [ $FIELDMAP_STG2 = 1 ] && echo -n "STG2 " ; echo ""
echo -n "--- TOPUP     :    " ; [ $TOPUP_STG1 = 1 ] && echo -n "STG1 " ; [ $TOPUP_STG2 = 1 ] && echo -n "STG2 " ; [ $TOPUP_STG3 = 1 ] && echo -n "STG3 " ; [ $TOPUP_STG4 = 1 ] && echo -n "STG4 " ; [ $TOPUP_STG5 = 1 ] && echo -n "STG5 " ; [ $TOPUP_STG6 = 1 ] && echo -n "STG6 " ; echo ""
echo -n "--- FDT       :    " ; [ $FDT_STG1 = 1 ] && echo -n "STG1 " ; [ $FDT_STG2 = 1 ] && echo -n "STG2 " ; [ $FDT_STG3 = 1 ] && echo -n "STG3 " ; [ $FDT_STG4 = 1 ] && echo -n "STG4 " ; echo ""
echo -n "--- BPX       :    " ; [ $BPX_STG1 = 1 ] && echo -n "STG1 "  ; echo ""
echo -n "--- RECON-ALL :    " ; [ $RECON_STG1 = 1 ] && echo -n "STG1 " ; [ $RECON_STG2 = 1 ] && echo -n "STG2 " ; [ $RECON_STG3 = 1 ] && echo -n "STG3 " ; [ $RECON_STG4 = 1 ] && echo -n "STG4 " ; [ $RECON_STG5 = 1 ] && echo -n "STG5 " ; echo ""
echo -n "--- VBM       :    " ; [ $VBM_STG1 = 1 ] && echo -n "STG1 " ; [ $VBM_STG2 = 1 ] && echo -n "STG2 " ; [ $VBM_STG3 = 1 ] && echo -n "STG3 " ; [ $VBM_STG4 = 1 ] && echo -n "STG4 " ; [ $VBM_STG5 = 1 ] && echo -n "STG5 " ; echo ""
echo -n "--- TRACULA   :    " ; [ $TRACULA_STG1 = 1 ] && echo -n "STG1 " ; [ $TRACULA_STG2 = 1 ] && echo -n "STG2 " ; [ $TRACULA_STG3 = 1 ] && echo -n "STG3 " ; [ $TRACULA_STG4 = 1 ] && echo -n "STG4 " ; echo ""
echo -n "--- BOLD      :    " ; [ $BOLD_STG1 = 1 ] && echo -n "STG1 " ; [ $BOLD_STG2 = 1 ] && echo -n "STG2 " ; [ $BOLD_STG3 = 1 ] && echo -n "STG3 " ; [ $BOLD_STG4 = 1 ] && echo -n "STG4 " ; [ $BOLD_STG5 = 1 ] && echo -n "STG5 " ; echo ""
echo -n "--- ALFF      :    " ; [ $ALFF_STG1 = 1 ] && echo -n "STG1 " ; [ $ALFF_STG2 = 1 ] && echo -n "STG2 " ; [ $ALFF_STG3 = 1 ] && echo -n "STG3 " ; echo ""
echo "2ND LEVEL processing streams selected:"
echo -n "--- TBSS           :    " ; [ $TBSS_STG1 = 1 ] && echo -n "STG1 " ; [ $TBSS_STG2 = 1 ] && echo -n "STG2 " ; [ $TBSS_STG3 = 1 ] && echo -n "STG3 " ; [ $TBSS_STG4 = 1 ] && echo -n "STG4 " ; [ $TBSS_STG5 = 1 ] && echo -n "STG5 " ; echo ""
echo -n "--- FS_STATS       :    " ; [ $FS_STATS_STG1 = 1 ] && echo -n "STG1 " ; [ $FS_STATS_STG2 = 1 ] && echo -n "STG2 " ; [ $FS_STATS_STG3 = 1 ] && echo -n "STG3 " ; [ $FS_STATS_STG4 = 1 ] && echo -n "STG4 " ; echo ""
echo -n "--- VBM_2NDLEV     :    " ; [ $VBM_2NDLEV_STG1 = 1 ] && echo -n "STG1 " ; [ $VBM_2NDLEV_STG2 = 1 ] && echo -n "STG2 " ; [ $VBM_2NDLEV_STG3 = 1 ] && echo -n "STG3 " ; echo ""
echo -n "--- MELODIC_2NDLEV :    " ; [ $MELODIC_2NDLEV_STG1 = 1 ] && echo -n "STG1 " ; [ $MELODIC_2NDLEV_STG2 = 1 ] && echo -n "STG2 " ; echo ""
echo -n "--- MELODIC_CMD    :    " ; [ $MELODIC_CMD_STG1 = 1 ] && echo -n "STG1 " ; echo ""
echo -n "--- DUALREG        :    " ; [ $DUALREG_STG1 = 1 ] && echo -n "STG1 " ; [ $DUALREG_STG2 = 1 ] && echo -n "STG2 " ; echo ""
echo -n "--- FSLNETS        :    " ; [ $FSLNETS_STG1 = 1 ] && echo -n "STG1 " ; echo ""
echo -n "--- ALFF_2NDLEV    :    " ; [ $ALFF_2NDLEV_STG1 = 1 ] && echo -n "STG1 " ; [ $ALFF_2NDLEV_STG2 = 1 ] && echo -n "STG2 " ; echo ""
echo ""
echo "***CHECK*** (sleeping 2 seconds)..."
sleep 2

# check SGE
if [ x"$SGE_ROOT" != "x" ] ; then 
  echo ""
  qstat -f
  echo ""
else
  echo ""
  echo "SGE_ROOT variable not set -> not using randomise_parallel."
  RANDOMISE_PARALLEL=0
  echo ""
fi

# check if source directory exists (where nifti originals are located)
if [ ! -d $srcdir ] ; then
  echo "ERROR: '$srcdir' (where nifti originals should be located) does not exist - creating it and exiting..."
  for subj in `cat $subjdir/subjects`; do 
    for sess in `cat $subjdir/$subj/sessions_struc` ; do
      mkdir -p $srcdir/$subj/$sess
    done   
  done
  exit 1
fi

# dos2unix bval/bvec textfiles (just in case...)
echo "Ensuring UNIX line endings in bval-/bvec textfiles..."
err=0
for subj in `cat $subjdir/subjects` ; do
  for sess in `cat $subjdir/$subj/sessions_struc` ; do
    dwi_txtfiles=""
    if [ x${pttrn_bvalsplus} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$srcdir/$subj/$sess/$pttrn_bvalsplus ; fi
    if [ x${pttrn_bvalsminus} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$srcdir/$subj/$sess/$pttrn_bvalsminus ; fi
    if [ x${pttrn_bvecsplus} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$srcdir/$subj/$sess/$pttrn_bvecsplus ; fi
    if [ x${pttrn_bvecsminus} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$srcdir/$subj/$sess/$pttrn_bvecsminus ; fi
    if [ x${pttrn_bvals} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$srcdir/$subj/$sess/$pttrn_bvals ; fi
    if [ x${pttrn_bvecs} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$srcdir/$subj/$sess/$pttrn_bvecs ; fi
    dwi_txtfiles=$(echo $dwi_txtfiles| row2col | sort | uniq)
    for i in $dwi_txtfiles ; do 
      #echo "    $i"
      if [ $(ls $i | wc -l) -eq 0 ] ; then echo "ERROR: 'ls $i' is empty." ; err=1 ; continue ; fi
      if [ $(ls $i | wc -l) -gt 1 ] ; then echo "ERROR: 'ls $i' is ambiguous (more than one result)." ; err=1 ; continue ; fi
      dos2unix -q $i
    done
  done
done
if [ $err -eq 1 ] ; then echo "an ERROR has occured - exiting..." ; exit 1 ; fi
echo "...done." ; echo ""

# check bvals, bvecs and diff. files for consistent number of entries
if [ $CHECK_CONSISTENCY_DIFFS = 1 ] ; then
  if [ x${pttrn_bvals} != "x" -a x${pttrn_bvecs} != "x" -a x${pttrn_diffs} != "x" ] ; then
    echo "Checking bvals/bvecs- and DWI files for consistent number of entries..."
    for subj in `cat $subjdir/subjects` ; do
      for sess in `cat $subjdir/$subj/sessions_struc` ; do
        fldr=$srcdir/$subj/$sess/
        echo -n "subj $subj , sess $sess : "
        checkConsistency "$fldr/$pttrn_diffs" "$fldr/$pttrn_bvals" "$fldr/$pttrn_bvecs"
      done
    done
    echo ""
  fi
fi

# make log directory for fsl_sub
mkdir -p $logdir
$scriptdir/delbrokenlinks.sh $logdir 1 # delete broken symlinks

# make temp directory
mkdir -p $tmpdir

# make directory for 2nd level GLMs
mkdir -p $glmdir_tbss
mkdir -p $glmdir_vbm

# create freesurfer subjects dir
for subj in `cat $subjdir/subjects`; do 
  for sess in `cat $subjdir/$subj/sessions_struc` ; do
    mkdir -p $FS_subjdir/$(subjsess)
  done   
done

# create freesurfer sessions dir
for subj in `cat $subjdir/subjects`; do 
  for sess in `cat $subjdir/$subj/sessions_func` ; do
    mkdir -p $FS_sessdir/$(subjsess)
  done   
done

# wait until cluster is ready...
waitIfBusy

# change to subjects directory...
cd $subjdir

###########################
# ----- BEGIN SCRATCH -----
###########################

if [ $SCRATCH -eq 1 ]; then
  echo "----- BEGIN SCRATCH -----"
  


 
  exit  
fi

#########################
# ----- END SCRATCH -----
#########################


waitIfBusy


############################
# ----- BEGIN FIELDMAP -----
############################

# FIELDMAP prepare
if [ $FIELDMAP_STG1 -eq 1 ]; then
  echo "----- BEGIN FIELDMAP_STG1 -----"
  for subj in `cat $subjdir/subjects` ; do
    for sess in `cat $subjdir/$subj/sessions_* | sort | uniq` ; do  
      fldr=$subjdir/${subj}/${sess}/fm
      
      # create fieldmap directory
      mkdir -p $fldr
   
      # find magnitude
      fm_m=`ls ${srcdir}/${subj}/${sess}/${pttrn_fmaps} | sed -n 1p` # first in listing is magnitude (second is phase-difference volume) (!)
      imcp $fm_m $fldr
      
      # split magnitude
      echo "FIELDMAP : subj $subj , sess $sess : extracting magnitude image ${fm_m}..."
      fslroi $fm_m ${fldr}/magn 0 1 # extract first of the two magnitude images, do not fsl_sub (!)
      #fslmaths $fm_m -Tmean ${fldr}/magn # the mean has better SNR

      # betting magnitude (with variable FI thresholds)
      for f in 0.50 0.40 0.30 ; do
        echo "FIELDMAP : subj $subj , sess $sess : betting magnitude image with fi=${f}..."
        fsl_sub -l $logdir -N fm_bet_$(subjsess) bet ${fldr}/magn ${fldr}/magn_brain_${f} -m -f $f      
      done
    done
  done
fi

waitIfBusy

# FIELDMAP create
if [ $FIELDMAP_STG2 -eq 1 ]; then
  echo "----- BEGIN FIELDMAP_STG2 -----"
  for subj in `cat $subjdir/subjects` ; do
    for sess in `cat $subjdir/$subj/sessions_* | sort | uniq` ; do
      fldr=$subjdir/${subj}/${sess}/fm

      # get bet threshold
      f=`getBetThres ${subjdir}/config_bet_magn $subj $sess`

      # bet, if necessary
      if [ $f = "mod" ] ; then
        if [ ! -f ${fldr}/magn_brain_${f}.nii.gz -o ! -f ${fldr}/magn_brain_${f}_mask.nii.gz ] ; then
          echo "FIELDMAP : subj $subj , sess $sess : ERROR : externally modified volume (magn_brain_${f}.nii.gz) & mask (magn_brain_${f}_mask.nii.gz) not found - exiting..." ; exit 1      
        fi
      else
        echo "FIELDMAP : subj $subj , sess $sess : betted magnitude image with fi=${f}..."
        bet ${fldr}/magn ${fldr}/magn_brain_${f} -m -f $f
      fi
          
      # find phase image
      fm_p=`ls ${srcdir}/${subj}/${sess}/${pttrn_fmaps}  | tail -n 1` # last in list is phase image, check pattern (!)
      
      # copy files to fieldmap folder
      imcp $fm_p $fldr
      echo "FIELDMAP : subj $subj , sess $sess : using magn_brain_${f}_mask"
      imcp $fldr/magn_brain_${f} $fldr/magn_brain
      imcp $fldr/magn_brain_${f}_mask $fldr/magn_brain_mask

      # define stats for the phase image
      range=`fslstats $fm_p -R` 
      min=`echo $range | cut -d " " -f1`
      max=`echo $range | cut -d " " -f2`
      add=$(echo "-($min + $max)/2" | bc -l)
      div=$(echo "$max + $add" | bc -l)
      
      # display info
      printf "FIELDMAP : subj $subj , sess $sess : phase image $fm_p - info: min: %.2f max: %.2f add: %.2f div: %.2f pi: %.5f \n" $min $max $add $div $PI
      
      # erode by one voxel (default kernel 3x3x3)
      echo "FIELDMAP : subj $subj , sess $sess : eroding brain mask a bit..."
      fslmaths $fldr/magn_brain_${f}_mask -ero $fldr/magn_brain_mask_ero

      # scale to -pi ... +pi
      fslmaths $fm_p -add $add -div $div -mul $PI $fldr/phase_rad -odt float
      echo "FIELDMAP : subj $subj , sess $sess : phase image is scaled to `fslstats $fldr/phase_rad -R`"
      
      # unwrap
      echo "FIELDMAP : subj $subj , sess $sess : unwrapping phase image..."
      prelude -p $fldr/phase_rad -m $fldr/magn_brain_mask_ero -a $fldr/magn_brain_${f} -o $fldr/uphase_rad

      # divide by echo time difference
      echo "FIELDMAP : subj $subj , sess $sess : normalizing phase image to dTE (${deltaTEphase}) and centering to median (P50)..."
      fslmaths $fldr/uphase_rad -div $deltaTEphase $fldr/fmap_rads
      
      # center to median
      p50=`fslstats $fldr/fmap_rads -k $fldr/magn_brain_mask_ero -P 50`
      echo "FIELDMAP : subj $subj , sess $sess : P50: $p50"
      fslmaths $fldr/fmap_rads -sub $p50 -mas $fldr/magn_brain_mask_ero $fldr/fmap_rads_masked

      # jetzt noch swi ohne swi:
      # smooth with gauss kernel of s=xx mm and subtract to get filtered image
      fslmaths $fldr/uphase_rad -s 10 $fldr/uphase_rad_s10 
      fslmaths $fldr/uphase_rad -sub $fldr/uphase_rad_s10 $fldr/uphase_rad_filt 
    done
  done
fi

##########################
# ----- END FIELDMAP -----
##########################


waitIfBusy


#########################
# ----- BEGIN TOPUP -----
#########################

# TOPUP prepare
if [ $TOPUP_STG1 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG1 -----"  
  
  # check bvals, bvecs and dwi files for consistent number of entries
  errflag=0
  echo "TOPUP : Checking bvals/bvecs- and DWI files for consistent number of entries..."
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$srcdir/$subj/$sess
      i=1
      for dwi_p in $(ls $fldr/$pttrn_diffsplus) ; do
        dwi_m=$(ls $fldr/$pttrn_diffsminus | sed -n ${i}p)
        n_bvalsplus=`ls $fldr/$pttrn_bvalsplus | sed -n ${i}p | xargs cat | wc -w` ; n_bvecsplus=`ls $fldr/$pttrn_bvecsplus | sed -n ${i}p | xargs cat | wc -w`
        n_bvalsminus=`ls $fldr/$pttrn_bvalsminus | sed -n ${i}p | xargs cat | wc -w` ; n_bvecsminus=`ls $fldr/$pttrn_bvecsminus | sed -n ${i}p | xargs cat | wc -w`
        nvolplus=`countVols "$dwi_p"` ; nvolminus=`countVols "$dwi_m"`
        if [ $n_bvalsplus -eq $nvolplus -a $n_bvecsplus=$(echo "scale=0 ; 3*$n_bvalsplus" | bc -l) ] ; then 
          echo "TOPUP : subj $subj , sess $sess : $(basename $dwi_p) : consistent number of entries in bval/bvec/dwi files ($n_bvalsplus)"
        else
          echo "TOPUP : subj $subj , sess $sess : $(basename $dwi_p) : ERROR : inconsistent number of entries in bval:$n_bvalsplus / bvec:$(echo "scale=0; $n_bvecsplus/3" | bc -l) / dwi:$nvolplus" ; errflag=1
        fi
        if [ $n_bvalsminus -eq $nvolminus -a $n_bvecsminus=$(echo "scale=0 ; 3*$n_bvalsminus" | bc -l) ] ; then 
          echo "TOPUP : subj $subj , sess $sess : $(basename $dwi_m) : consistent number of entries in bval/bvec/dwi files ($n_bvalsminus)"
        else
          echo "TOPUP : subj $subj , sess $sess : $(basename $dwi_m) : ERROR : inconsistent number of entries in bval:$n_bvalsminus / bvec:$(echo "scale=0; $n_bvecsminus/3" | bc -l) / dwi:$nvolminus" ; errflag=1
        fi
        if [ $n_bvalsplus -eq $n_bvalsminus ] ; then 
          echo "TOPUP : subj $subj , sess $sess : blip(+/-) : consistent number of entries ($n_bvalsminus)"
        else
          echo "TOPUP : subj $subj , sess $sess : blip(+/-) : ERROR : inconsistent number of entries (+: $n_bvalsplus -: $n_bvalsminus)" ; errflag=1
        fi
        i=$[$i+1]
      done
    done
  done
  if [ $errflag -eq 1 ] ; then echo "DWI consistency check : Exiting due to errors !" ; exit 1 ; fi
  fldr="" ; n_bvalsplus="" ; n_bvalsminus="" ; n_bvecsplus="" ; n_bvecsminus="" ; nvolplus="" ; nvolminus="" ; errflag="" ; subj="" ; sess="" ; i="" ; dwi_m="" ; dwi_p=""
  echo "TOPUP : ...done."
  # end check    
 
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
    
      # check if we have acquisition parameters
      defineDWIparams $subjdir/config_acqparams_dwi $subj $sess
    
      if [ "x$pttrn_diffsplus" = "x" -o "x$pttrn_diffsminus" = "x" -o "x$pttrn_bvalsplus" = "x" -o "x$pttrn_bvalsminus" = "x" -o "x$pttrn_bvecsplus" = "x" -o "x$pttrn_bvecsminus" = "x" ] ; then
        echo "TOPUP : subj $subj , sess $sess : ERROR : file search pattern for blipUp/blipDown DWIs not set..."
        continue
      fi
      
      fldr=${subjdir}/${subj}/${sess}/topup
      mkdir -p $fldr
      
      # display info
      echo "TOPUP : subj $subj , sess $sess : preparing TOPUP... "
      
      # are the +- diffusion files in equal number ?
      n_plus=`ls $srcdir/$subj/$sess/$pttrn_diffsplus | wc -l`
      n_minus=`ls $srcdir/$subj/$sess/$pttrn_diffsminus | wc -l`
      if [ ! $n_plus -eq $n_minus ] ; then 
        echo "TOPUP : subj $subj , sess $sess : ERROR : number of +blips diff. files ($n_plus) != number of -blips diff. files ($n_minus) - continuing loop..."
        continue
      elif [ $n_plus -eq 0 -a $n_minus -eq 0 ] ; then
        echo "TOPUP : subj $subj , sess $sess : ERROR : no blip-up/down diffusion files found for TOPUP (+/- must be part of the filename) - continuing loop..."
        continue
      fi
                        
      # count +/- bvec/bval-files
      ls $srcdir/$subj/$sess/$pttrn_bvecsplus > $fldr/bvec+.files
      ls $srcdir/$subj/$sess/$pttrn_bvecsminus > $fldr/bvec-.files
      cat $fldr/bvec-.files $fldr/bvec+.files > $fldr/bvec.files
      ls $srcdir/$subj/$sess/$pttrn_bvalsplus > $fldr/bval+.files
      ls $srcdir/$subj/$sess/$pttrn_bvalsminus > $fldr/bval-.files
      cat $fldr/bval-.files $fldr/bval+.files > $fldr/bval.files
      n_vec_plus=`cat $fldr/bvec+.files | wc -l`
      n_vec_minus=`cat $fldr/bvec-.files | wc -l`
      n_val_plus=`cat $fldr/bval+.files | wc -l`
      n_val_minus=`cat $fldr/bval-.files | wc -l`
      
      #  are the +/- bvec-files equal in number ?
      if [ ! $n_vec_plus -eq $n_vec_minus ] ; then 
        echo "TOPUP : subj $subj , sess $sess : ERROR : number of +blips bvec-files ($n_vec_plus) != number of -blips bvec-files ($n_vec_minus) - continuing loop..."
        continue
      elif [ $n_vec_plus -eq 0 -a $n_vec_minus -eq 0 ] ; then
        echo "TOPUP : subj $subj , sess $sess : ERROR : no blip-up/down bvec-files found for TOPUP (+/- must be part of the filename) - continuing loop..."
        continue
      fi
      
      #  are the +/- bval-files equal in number ?
      if [ ! $n_val_plus -eq $n_val_minus ] ; then 
        echo "TOPUP : subj $subj , sess $sess : ERROR : number of +blips bval-files ($n_val_plus) != number of -blips bval-files ($n_val_minus) - continuing loop..."
        continue
      elif [ $n_val_plus -eq 0 -a $n_val_minus -eq 0 ] ; then
        echo "TOPUP : subj $subj , sess $sess : ERROR : no blip-up/down bval-files found for TOPUP (+/- must be part of the filename) - continuing loop..."
        continue
      fi
      
      # concatenate +bvecs and -bvecs
      concat_bvals $srcdir/$subj/$sess/"$pttrn_bvalsminus" $fldr/bvals-_concat.txt
      concat_bvals $srcdir/$subj/$sess/"$pttrn_bvalsplus" $fldr/bvals+_concat.txt 
      concat_bvecs $srcdir/$subj/$sess/"$pttrn_bvecsminus" $fldr/bvecs-_concat.txt
      concat_bvecs $srcdir/$subj/$sess/"$pttrn_bvecsplus" $fldr/bvecs+_concat.txt 

      nbvalsplus=$(wc -w $fldr/bvals+_concat.txt | cut -d " " -f 1)
      nbvalsminus=$(wc -w $fldr/bvals-_concat.txt | cut -d " " -f 1)
      nbvecsplus=$(wc -w $fldr/bvecs+_concat.txt | cut -d " " -f 1)
      nbvecsminus=$(wc -w $fldr/bvecs-_concat.txt | cut -d " " -f 1)      
     
      # check number of entries in concatenated bvals/bvecs files
      n_entries=`countVols $srcdir/$subj/$sess/"$pttrn_diffsplus"` 
      if [ $nbvalsplus = $nbvalsminus -a $nbvalsplus = $n_entries -a $nbvecsplus = `echo "3*$n_entries" | bc` -a $nbvecsplus = $nbvecsminus ] ; then
        echo "TOPUP : subj $subj , sess $sess : number of entries in bvals- and bvecs files consistent ($n_entries entries)."
      else
        echo "TOPUP : subj $subj , sess $sess : ERROR : number of entries in bvals- and bvecs files NOT consistent - continuing loop..."
        echo "(diffs+: $n_entries ; bvals+: $nbvalsplus ; bvals-: $nbvalsminus ; bvecs+: $nbvecsplus /3 ; bvecs-: $nbvecsminus /3)"
        continue
      fi
      
      # check if +/- bval entries are the same
      i=1
      for bval in `cat $fldr/bvals+_concat.txt` ; do
        if [ $bval != $(cat $fldr/bvals-_concat.txt | cut -d " " -f $i)  ] ; then 
          echo "TOPUP : subj $subj , sess $sess : ERROR : +bval entries do not match -bval entries (they should have the same values !) - exiting..."
          exit
        fi        
        i=$[$i+1]
      done

      # getting unwarp direction
      uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_dwi $subj $sess`
      echo "TOPUP : subj $subj , sess $sess : unwarp direction is '$uw_dir'."
      x=0 ; y=0 ; z=0; 
      if [ "$uw_dir" = "+x" ] ; then x=1  ; fi
      if [ "$uw_dir" = "-x" ] ; then x=-1 ; fi
      if [ "$uw_dir" = "+y" ] ; then y=1  ; fi
      if [ "$uw_dir" = "-y" ] ; then y=-1 ; fi
      if [ "$uw_dir" = "+z" ] ; then z=1  ; fi
      if [ "$uw_dir" = "-z" ] ; then z=-1 ; fi
      mx=$(echo "scale=0; -1 * ${x}" | bc -l)
      my=$(echo "scale=0; -1 * ${y}" | bc -l)
      mz=$(echo "scale=0; -1 * ${z}" | bc -l)
      blipdownline="$mx $my $mz $TROT_topup"
      blipupline="$x $y $z $TROT_topup"
      
      # display info
      echo "TOPUP : subj $subj , sess $sess : example blip-down line:"
      echo "        $blipdownline"
      echo "TOPUP : subj $subj , sess $sess : example blip-up line:"
      echo "        $blipupline"
      
      # creating index file for TOPUP
      echo "TOPUP : subj $subj , sess $sess : creating index file for TOPUP..."      
      rm -f $fldr/$(subjsess)_acqparam.txt ; rm -f $fldr/$(subjsess)_acqparam_inv.txt ; rm -f $fldr/diff.files # clean-up previous runs...
      diffsminus=`ls ${srcdir}/${subj}/${sess}/${pttrn_diffsminus}`
      for file in $diffsminus ; do
        nvol=`fslinfo $file | grep ^dim4 | awk '{print $2}'`
        echo "$file n:${nvol}" | tee -a $fldr/diff.files
        for i in `seq 1 $nvol`; do
          echo "$blipdownline" >> $fldr/$(subjsess)_acqparam.txt
          echo "$blipupline" >> $fldr/$(subjsess)_acqparam_inv.txt
        done
      done
      
      diffsplus=`ls ${srcdir}/${subj}/${sess}/${pttrn_diffsplus}`
      for file in $diffsplus ; do
        nvol=`fslinfo $file | grep ^dim4 | awk '{print $2}'`
        echo "$file n:${nvol}" | tee -a $fldr/diff.files
        for i in `seq 1 $nvol`; do
          echo "$blipupline" >> $fldr/$(subjsess)_acqparam.txt
          echo "$blipdownline" >> $fldr/$(subjsess)_acqparam_inv.txt
        done
      done
                 
      # merging diffusion images for TOPUP    
      echo "TOPUP : subj $subj , sess $sess : merging diffs... "
      fsl_sub -l $logdir -N topup_fslmerge_$(subjsess) fslmerge -t $fldr/diffs_merged $(cat $fldr/diff.files | cut -d " " -f 1)
    done
  done
  
  waitIfBusy
  
  # perform eddy-correction, if applicable
  if [ $TOPUP_USE_EC -eq 1 ] ; then
    for subj in `cat subjects` ; do
      for sess in `cat ${subj}/sessions_struc` ; do
        fldr=${subjdir}/${subj}/${sess}/topup
        
        # cleanup previous runs...
        rm -f $fldr/ec_diffs_merged_???_*.nii.gz # removing temporary files from prev. run
        if [ ! -z "$(ls $fldr/ec_diffs_merged_???.ecclog 2>/dev/null)" ] ; then    
          echo "TOPUP : subj $subj , sess $sess : WARNING : eddy_correct logfile(s) from a previous run detected - deleting..."
          rm $fldr/ec_diffs_merged_???.ecclog # (!)
        fi
        # eddy-correct each run...
        for i in `seq -f %03g 001 $(cat $fldr/diff.files | wc -l)` ; do # note: don't use seq -w (bash compatibility issues!) (!)
          dwifile=$(cat $fldr/diff.files | sed -n ${i}p | cut -d " " -f 1)
          bvalfile=$(cat $fldr/bval.files | sed -n ${i}p)
          
          # get B0 index          
          b0img=`getB0Index $bvalfile $fldr/ec_ref_${i}.idx | cut -d " " -f 1` ; min=`getB0Index $bvalfile $fldr/ec_ref_${i}.idx | cut -d " " -f 2` 
          
          # create a task file for fsl_sub, which is needed to avoid accumulations when SGE does a re-run on error
          echo "rm -f $fldr/ec_diffs_merged_${i}*.nii.gz ; \
                rm -f $fldr/ec_diffs_merged_${i}.ecclog ; \
                $scriptdir/eddy_correct.sh $dwifile $fldr/ec_diffs_merged_${i} $b0img $TOPUP_EC_DOF $TOPUP_EC_COST trilinear" > $fldr/topup_ec_${i}.cmd
          
          # eddy-correct
          echo "TOPUP : subj $subj , sess $sess : eddy_correction of '$dwifile' (ec_diffs_merged_${i}) is using volume no. $b0img as B0 (val:${min})..."
          fsl_sub -l $logdir -N topup_eddy_correct_$(subjsess) -t $fldr/topup_ec_${i}.cmd
        done        
      done
    done
    
    waitIfBusy    
    
    # plot ecclogs...
    for subj in `cat subjects` ; do
      for sess in `cat ${subj}/sessions_struc` ; do
        fldr=${subjdir}/${subj}/${sess}/topup
        cd $fldr
        for i in `seq -f %03g 001 $(cat $fldr/diff.files | wc -l)` ; do # note: don't use seq -w (bash compatibility issues!) (!)
          echo "TOPUP : subj $subj , sess $sess : plotting ec_diffs_merged_${i}.ecclog..."
          eddy_correct_plot ec_diffs_merged_${i}.ecclog $(subjsess)-${i}
          # horzcat
          pngappend ec_disp.png + ec_rot.png + ec_trans.png ec_${i}.png
          # accumulate
          if [ $i -gt 1 ] ; then
            pngappend ec_plot.png - ec_${i}.png ec_plot.png
          else
            cp ec_${i}.png ec_plot.png
          fi
          # cleanup
          rm  ec_disp.png ec_rot.png ec_trans.png ec_${i}.png
        done
        cd $subjdir
      done
    done
      
  fi
fi

waitIfBusy

# TOPUP low-B images: create index and extract
if [ $TOPUP_STG2 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG2 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subjdir}/${subj}/${sess}/topup
      
      if [ ! -f $fldr/$(subjsess)_acqparam.txt ] ; then echo "TOPUP : subj $subj , sess $sess : ERROR : parameter file $fldr/$(subjsess)_acqparam.txt not found - continuing loop..." ; continue ; fi
      
      # display info
      echo "TOPUP : subj $subj , sess $sess : concatenate bvals and bvecs... "
      echo "`cat $fldr/bvals-_concat.txt`" "`cat $fldr/bvals+_concat.txt`" > $fldr/bvals_concat.txt
      paste -d " " $fldr/bvecs-_concat.txt $fldr/bvecs+_concat.txt > $fldr/bvecs_concat.txt

      # get B0 index
      min=`row2col $fldr/bvals_concat.txt | getMin` # find minimum value (usually representing the "B0" image)
      echo "TOPUP : subj $subj , sess $sess : minimum b-value in merged diff. is $min"
      b0idces=`getIdx $fldr/bvals_concat.txt $min`
      echo $b0idces | row2col > $fldr/lowb.idx
      
      # creating index file for topup (only low-B images)
      echo "TOPUP : subj $subj , sess $sess : creating index file for TOPUP (only low-B images)..."      
      rm -f $fldr/$(subjsess)_acqparam_lowb.txt ; rm -f $fldr/$(subjsess)_acqparam_lowb_inv.txt # clean-up previous runs...
      for b0idx in $b0idces ; do
        line=`echo "$b0idx + 1" | bc -l`
        cat $fldr/$(subjsess)_acqparam.txt | sed -n ${line}p >> $fldr/$(subjsess)_acqparam_lowb.txt
        cat $fldr/$(subjsess)_acqparam_inv.txt | sed -n ${line}p >> $fldr/$(subjsess)_acqparam_lowb_inv.txt
      done
          
      # extract B0 images
      lowbs=""
      for b0idx in $b0idces ; do    
        echo "TOPUP : subj $subj , sess $sess : found B0 image in merged diff. at pos. $b0idx (val:${min}) - extracting..."
        lowb="$fldr/b${min}_`printf '%05i' $b0idx`"
        fsl_sub -l $logdir -N topup_fslroi_$(subjsess) fslroi $fldr/diffs_merged $lowb $b0idx 1
        lowbs=$lowbs" "$lowb
      done
      
      # save filenames to text file
      echo "$lowbs" > $fldr/lowb.files; lowbs=""
      
      # wait here to prevent overload...
      waitIfBusy
    done
  done
fi

waitIfBusy

# TOPUP merge B0 images
if [ $TOPUP_STG3 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG3 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subjdir}/${subj}/${sess}/topup
      
      if [ ! -f $fldr/$(subjsess)_acqparam.txt ] ; then echo "TOPUP : subj $subj , sess $sess : ERROR : parameter file $fldr/$(subjsess)_acqparam.txt not found - continuing loop..." ; continue ; fi
      
      # merge B0 images
      echo "TOPUP : subj $subj , sess $sess : merging low-B volumes..."
      fsl_sub -l $logdir -N topup_fslmerge_$(subjsess) fslmerge -t $fldr/$(subjsess)_lowb_merged $(cat $fldr/lowb.files)
      
    done
  done
fi

waitIfBusy

# TOPUP execute TOPUP
if [ $TOPUP_STG4 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG4 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subjdir}/${subj}/${sess}/topup
      
      if [ ! -f $fldr/$(subjsess)_acqparam.txt ] ; then echo "TOPUP : subj $subj , sess $sess : ERROR : parameter file $fldr/$(subjsess)_acqparam.txt not found - continuing loop..." ; continue ; fi

      # execute TOPUP
      echo "TOPUP : subj $subj , sess $sess : executing TOPUP on merged low-B volumes..."
      mkdir -p $fldr/fm # dir. for fieldmap related stuff
      echo "topup -v --imain=$fldr/$(subjsess)_lowb_merged --datain=$fldr/$(subjsess)_acqparam_lowb.txt --config=b02b0.cnf --out=$fldr/$(subjsess)_field_lowb --fout=$fldr/fm/field_Hz_lowb --iout=$fldr/fm/uw_lowb_merged_chk ; \
      fslmaths $fldr/fm/field_Hz_lowb -mul 6.2832 $fldr/fm/fmap_rads" | tee $fldr/topup.cmd
      fsl_sub -l $logdir -N topup_topup_$(subjsess) -t $fldr/topup.cmd
       
    done
  done
fi

waitIfBusy

# TOPUP apply warp
if [ $TOPUP_STG5 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG5 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subjdir}/${subj}/${sess}/topup
      
      if [ ! -f $fldr/$(subjsess)_acqparam.txt ] ; then echo "TOPUP : subj $subj , sess $sess : ERROR : parameter file $fldr/$(subjsess)_acqparam.txt not found - continuing loop..." ; continue ; fi
      
      # for applywarp: get appropriate line in TOPUP index file (containing parameters pertaining to the B0 images) that refers to the first b0 volume in the respective DWI input file.
      line_b0=1 ; j=0 ; lines_b0p=""; lines_b0m=""
      for i in $(cat $fldr/bval-.files) ; do
        if [ $j -gt 0 ] ; then
          line_b0=$(echo "scale=0; $line_b0 + $nb0" | bc -l)
        fi
        min=`row2col $i | getMin`
        nb0=$(echo `getIdx $i $min` | wc -w)
        lines_b0m=$lines_b0m" "$line_b0
        j=$[$j+1]
      done      
      for i in $(cat $fldr/bval+.files) ; do
        line_b0=$(echo "scale=0; $line_b0 + $nb0" | bc -l)
        min=`row2col $i | getMin`
        nb0=$(echo `getIdx $i $min` | wc -w)
        lines_b0p=$lines_b0p" "$line_b0
      done
      j=""
      
      # generate commando without eddy-correction
      nplus=`ls $srcdir/$subj/$sess/$pttrn_diffsplus | wc -l`      
      rm -f $fldr/applytopup.cmd
      for i in `seq 1 $nplus` ; do
        j=`echo "$i + $nplus" | bc -l`

        blipdown=`ls $srcdir/$subj/$sess/$pttrn_diffsminus | sed -n ${i}p`
        blipup=`ls $srcdir/$subj/$sess/$pttrn_diffsplus | sed -n ${i}p`
        
        b0plus=$(echo $lines_b0p | cut -d " " -f $i)
        b0minus=$(echo $lines_b0m | cut -d " " -f $i)

        n=`printf %03i $i`
        imrm $fldr/${n}_topup_corr.* # delete prev. run
        echo "applytopup --imain=$blipdown,$blipup --datain=$fldr/$(subjsess)_acqparam_lowb.txt --inindex=${b0minus},${b0plus} --topup=$fldr/$(subjsess)_field_lowb --method=lsr --out=$fldr/${n}_topup_corr" >> $fldr/applytopup.cmd
      done
      
      # generate commando with eddy-correction
      nplus=`ls $srcdir/$subj/$sess/$pttrn_diffsplus | wc -l`      
      rm -f $fldr/applytopup_ec.cmd
      for i in `seq 1 $nplus` ; do
        j=`echo "$i + $nplus" | bc -l`
        
        blipdown=$fldr/ec_diffs_merged_$(printf %03i $i)
        blipup=$fldr/ec_diffs_merged_$(printf %03i $j)
        
        b0plus=$(echo $lines_b0p | cut -d " " -f $i)
        b0minus=$(echo $lines_b0m | cut -d " " -f $i)
        
        n=`printf %03i $i`
        imrm $fldr/${n}_topup_corr_ec.* # delete prev. run
        echo "applytopup --imain=$blipdown,$blipup --datain=$fldr/$(subjsess)_acqparam_lowb.txt --inindex=${b0minus},${b0plus} --topup=$fldr/$(subjsess)_field_lowb --method=lsr --out=$fldr/${n}_topup_corr_ec" >> $fldr/applytopup_ec.cmd
      done
                  
      # generate commando with EDDY
      echo "$scriptdir/eddy_topup.sh $fldr $fldr/$(subjsess)_topup_corr_eddy_merged.nii.gz" > $fldr/eddy.cmd
      
    done
  done
  
  # execute...
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subjdir}/${subj}/${sess}/topup
  
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : applying warps to native DWIs..."
        cat $fldr/applytopup.cmd
        fsl_sub -l $logdir -N topup_applytopup_$(subjsess) -t $fldr/applytopup.cmd
      fi
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : applying warps to eddy-corrected DWIs..."
        cat $fldr/applytopup_ec.cmd
        fsl_sub -l $logdir -N topup_applytopup_ec_$(subjsess) -t $fldr/applytopup_ec.cmd
      fi
      if [ $TOPUP_USE_EDDY -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : executing EDDY..."
        cat $fldr/eddy.cmd
        fsl_sub -l $logdir -N topup_eddy_$(subjsess) -t $fldr/eddy.cmd
      fi
      
    done
  done
       
  waitIfBusy
      
  # merge corrected files and remove negative values
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subjdir}/${subj}/${sess}/topup
      
      # merge corrected files
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : merging topup-corrected DWIs..."
        #fsl_sub -l $logdir -N topup_merge_corr_$(subjsess) fslmerge -t $fldr/$(subjsess)_topup_corr_merged $(imglob $fldr/*_topup_corr.nii.gz)
        fslmerge -t $fldr/$(subjsess)_topup_corr_merged $(imglob $fldr/*_topup_corr.nii.gz)
      fi
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : merging topup-corrected & eddy-corrected DWIs..."
        #fsl_sub -l $logdir -N topup_merge_corr_ec_$(subjsess) fslmerge -t $fldr/$(subjsess)_topup_corr_ec_merged $(imglob $fldr/*_topup_corr_ec.nii.gz)
        fslmerge -t $fldr/$(subjsess)_topup_corr_ec_merged $(imglob $fldr/*_topup_corr_ec.nii.gz)
      fi
    done
  done
  
  waitIfBusy

  # remove negative values  
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subjdir}/${subj}/${sess}/topup
  
      echo "TOPUP : subj $subj , sess $sess : zeroing negative values in topup-corrected DWIs..."
      if [ $TOPUP_USE_NATIVE -eq 1 -a -f $fldr/$(subjsess)_topup_corr_merged.nii.gz ] ; then fsl_sub -l $logdir -N topup_noneg_$(subjsess) fslmaths $fldr/$(subjsess)_topup_corr_merged -thr 0 $fldr/$(subjsess)_topup_corr_merged ; fi
      if [ $TOPUP_USE_EC -eq 1 -a -f $fldr/$(subjsess)_topup_corr_ec_merged.nii.gz ] ; then fsl_sub -l $logdir -N topup_noneg_ec_$(subjsess) fslmaths $fldr/$(subjsess)_topup_corr_ec_merged -thr 0 $fldr/$(subjsess)_topup_corr_ec_merged ; fi
      # eddy script already removed neg. values
      #if [ -f $fldr/$(subjsess)_topup_corr_eddy_merged.nii.gz ] ; then fsl_sub -l $logdir -N topup_noneg_eddy_$(subjsess) fslmaths $fldr/$(subjsess)_topup_corr_eddy_merged -thr 0 $fldr/$(subjsess)_topup_corr_eddy_merged ; fi
    done
  done
  
  waitIfBusy
  
  # create masked fieldmap
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subjdir}/${subj}/${sess}/topup

      echo "TOPUP : subj $subj , sess $sess : masking topup-derived fieldmap..."
      if [ -f $fldr/$(subjsess)_topup_corr_merged.nii.gz ] ; then corrfile=$fldr/$(subjsess)_topup_corr_merged.nii.gz ; fi
      if [ -f $fldr/$(subjsess)_topup_corr_ec_merged.nii.gz ] ; then corrfile=$fldr/$(subjsess)_topup_corr_ec_merged.nii.gz ; fi ;
      if [ -f $fldr/$(subjsess)_topup_corr_eddy_merged.nii.gz ] ; then corrfile=$fldr/$(subjsess)_topup_corr_eddy_merged.nii.gz ; fi ;
      if [ ! -f $fldr/fm/fmap_rads.nii.gz ] ; then  echo "TOPUP : subj $subj , sess $sess : ERROR : fieldmap not found in '$fldr/fm/' - exiting..." ; exit 1 ; fi
      min=`row2col $fldr/bvals_concat.txt | getMin`
      b0idces=`getIdx $fldr/bvals-_concat.txt $min` 
      lowbs=""
      for b0idx in $b0idces ; do 
        lowb="$fldr/fm/uw_b${min}_`printf '%05i' $b0idx`"
        echo "    found B0 image in merged diff. at pos. $b0idx (val:${min}) - extracting from '$corrfile'..."
        fslroi $corrfile $lowb $b0idx 1
        lowbs=$lowbs" "$lowb
      done
      echo "    creating mask..."
      fithres=`getBetThres ${subjdir}/config_bet_lowb $subj $sess` # get info for current subject
      echo "fslmerge -t $fldr/fm/uw_lowb_merged $lowbs ; \
      fslmaths $fldr/fm/uw_lowb_merged -Tmean $fldr/fm/uw_lowb_mean ; \
      bet $fldr/fm/uw_lowb_mean $fldr/fm/uw_lowb_mean_brain_${fithres} -f $fithres -m ; \
      fslmaths $fldr/fm/fmap_rads -mas $fldr/fm/uw_lowb_mean_brain_${fithres}_mask $fldr/fm/fmap_rads_masked" > $fldr/topup_b0mask.cmd
      fsl_sub -l $logdir -N topup_b0mask_$(subjsess) -t $fldr/topup_b0mask.cmd
      
      # link to mask
      echo "TOPUP : subj $subj , sess $sess : link to unwarped mask..."
      ln -sfv ./fm/uw_lowb_mean_brain_${fithres}.nii.gz $fldr/uw_nodif_brain.nii.gz
      ln -sfv ./fm/uw_lowb_mean_brain_${fithres}_mask.nii.gz $fldr/uw_nodif_brain_mask.nii.gz
      # link to mean lowb
      ln -sfv ./uw_lowb_mean_brain_${fithres}.nii.gz $fldr/fm/uw_lowb_mean_brain.nii.gz
      ln -sfv ./uw_lowb_mean_brain_${fithres}_mask.nii.gz $fldr/fm/uw_lowb_mean_brain_mask.nii.gz
      
    done
  done    
fi

waitIfBusy

# TOPUP estimate tensor model
if [ $TOPUP_STG6 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG6 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subjdir}/${subj}/${sess}/topup

      # averaging +/- bvecs & bvals...
      # NOTE: bvecs are averaged further below (following rotation)
      average $fldr/bvals-_concat.txt $fldr/bvals+_concat.txt > $fldr/avg_bvals.txt
      average $fldr/bvecs-_concat.txt $fldr/bvecs+_concat.txt > $fldr/avg_bvecs.txt # for EDDY no rotations are applied
      
      # rotate bvecs: get appropriate line in TOPUP index file (containing parameters pertaining to the B0 images) that refers to the first b0 volume in the respective DWI input file.
      line_b0=1 ; j=0 ; lines_b0p=""; lines_b0m=""
      for i in $(cat $fldr/bval-.files) ; do
        if [ $j -gt 0 ] ; then
          line_b0=$(echo "scale=0; $line_b0 + $nb0" | bc -l)
        fi
        min=`row2col $i | getMin`
        nb0=$(echo `getIdx $i $min` | wc -w)
        lines_b0m=$lines_b0m" "$line_b0
        j=$[$j+1]
      done      
      for i in $(cat $fldr/bval+.files) ; do
        line_b0=$(echo "scale=0; $line_b0 + $nb0" | bc -l)
        min=`row2col $i | getMin`
        nb0=$(echo `getIdx $i $min` | wc -w)
        lines_b0p=$lines_b0p" "$line_b0
      done
      j="" ; lines_b0=$lines_b0m" "$lines_b0p
      
      # rotate bvecs to compensate for eddy-correction, if applicable
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        if [ -z "$(ls $fldr/ec_diffs_merged_???.ecclog 2>/dev/null)" ] ; then 
          echo "TOPUP : subj $subj , sess $sess : ERROR : *.ecclog file(s) not found, but needed to rotate b-vectors -> skipping this part..." 
        
        else 
          for i in `seq -f %03g 001 $(cat $fldr/diff.files | wc -l)` ; do
            bvecfile=`sed -n ${i}p $fldr/bvec.files`
            echo "TOPUP : subj $subj , sess $sess : rotating '$bvecfile' according to 'ec_diffs_merged_${i}.ecclog'"
            xfmrot $fldr/ec_diffs_merged_${i}.ecclog $bvecfile $fldr/bvecs_ec_${i}.rot
          done
        fi
      fi
      
      # rotate bvecs to compensate for TOPUP 6 parameter rigid-body correction using OCTAVE (for each run)
      for i in `seq -f %03g 001 $(cat $fldr/diff.files | wc -l)` ; do # for each run do...        
        # copy OCTAVE template
        cp $tmpltdir/template_makeXfmMatrix.m $fldr/makeXfmMatrix_${i}.m
        
        # define vars
        line_b0=$(echo $lines_b0 | cut -d " " -f $i)
        rots=`sed -n ${line_b0}p $fldr/$(subjsess)_field_lowb_movpar.txt | awk '{print $4"  "$5"  "$6}'` # cut -d " " -f 7-11` # last three entries are rotations in radians 
        nscans=`sed -n ${i}p $fldr/diff.files | cut -d : -f 2` # number of scans in run
        fname_mat=$fldr/topup_diffs_merged_${i}.mat # filename with n 4x4 affine matrices
        
        # do run-specific substitutions in OCTAVE template
        sed -i "s|function M = .*|function M = makeXfmMatrix_${i}|g" $fldr/makeXfmMatrix_${i}.m
        sed -i "s|R=.*|R=[$rots]|g" $fldr/makeXfmMatrix_${i}.m
        sed -i "s|repeat=.*|repeat=$nscans|g" $fldr/makeXfmMatrix_${i}.m
        sed -i "s|filename=.*|filename='$fname_mat'|g" $fldr/makeXfmMatrix_${i}.m
        
        # change directory and unset error flag because of strange OCTAVE behavior and unclear error 'error: matrix cannot be indexed with .' - but seems to work anyhow
        cd $fldr
          set +e # unset exit on error bc. octave always throws an error (?)
          echo "TOPUP : subj $subj , sess $sess : create rotation matrices '$(basename $fname_mat)' ($nscans entries) for 6-parameter TOPUP motion correction (angles: $rots)..."
          echo "NOTE: Octave may throw an error here for reasons unknown."
          octave -q --eval makeXfmMatrix_${i}.m >& /dev/null
          set -e
        cd $subjdir
        
        # check the created rotation matrix
        head -n8 $fname_mat > $fldr/check.mat
        echo "TOPUP : subj $subj , sess $sess : CHECK rotation angles - topup input: $(printf ' %0.6f' $rots)"
        echo "TOPUP : subj $subj , sess $sess : CHECK rotation angles - avscale out: $(avscale --allparams $fldr/check.mat | grep "Rotation Angles" | cut -d '=' -f2)"
        rm $fldr/check.mat
        
        # apply the rotation matrix to b-vector file
        if [ $TOPUP_USE_NATIVE -eq 1 ] ; then 
          bvecfile=`sed -n ${i}p $fldr/bvec.files`
          echo "TOPUP : subj $subj , sess $sess : apply rotation matrices '$(basename $fname_mat)' to '`basename $bvecfile`' -> 'bvecs_topup_${i}.rot'"
          xfmrot $fname_mat $bvecfile $fldr/bvecs_topup_${i}.rot
        fi        
        if [ $TOPUP_USE_EC -eq 1 ] ; then
          bvecfile=$fldr/bvecs_ec_${i}.rot
          echo "TOPUP : subj $subj , sess $sess : apply rotation matrices '$(basename $fname_mat)' to '`basename $bvecfile`' -> 'bvecs_topup_ec_${i}.rot'"
          xfmrot $fname_mat $bvecfile $fldr/bvecs_topup_ec_${i}.rot
        fi
      done
      
      # average rotated bvecs
      nplus=`cat $fldr/bvec+.files | wc -l`
      for i in `seq -f %03g 001 $nplus` ; do
        j=`echo "$i + $nplus" | bc -l` ; j=`printf %03i $j`
        if [ $TOPUP_USE_NATIVE -eq 1 ] ; then 
          echo "TOPUP : subj $subj , sess $sess : averaging rotated blip+/blip- b-vectors (no eddy-correction)..."
          average $fldr/bvecs_topup_${i}.rot $fldr/bvecs_topup_${j}.rot > $fldr/avg_bvecs_topup_${i}.rot
        fi
        if [ $TOPUP_USE_EC -eq 1 ] ; then
          echo "TOPUP : subj $subj , sess $sess : averaging rotated blip+/blip- b-vectors (incl. eddy-correction)..."
          average $fldr/bvecs_topup_ec_${i}.rot $fldr/bvecs_topup_ec_${j}.rot > $fldr/avg_bvecs_topup_ec_${i}.rot
        fi
      done
      
      # concatenate averaged and rotated bvecs
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then      
       echo "TOPUP : subj $subj , sess $sess : concatenate averaged and rotated b-vectors (no eddy-correction)..."
       concat_bvecs "$fldr/avg_bvecs_topup_???.rot" $fldr/avg_bvecs_topup.rot
      fi      
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : concatenate averaged and rotated b-vectors (incl. eddy-correction)..."
        concat_bvecs "$fldr/avg_bvecs_topup_ec_???.rot" $fldr/avg_bvecs_topup_ec.rot
      fi
      
      # display info
      echo "TOPUP : subj $subj , sess $sess : dtifit is estimating tensor model..."
      
      # estimate tensor model (rotated bvecs)
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then           
        echo "TOPUP : subj $subj , sess $sess : dtifit is estimating tensor model with rotated b-vectors (no eddy-correction)..."
        fsl_sub -l $logdir -N topup_dtifit_noec_bvecrot_$(subjsess) dtifit -k $fldr/$(subjsess)_topup_corr_merged -m $fldr/uw_nodif_brain_mask -r $fldr/avg_bvecs_topup.rot -b $fldr/avg_bvals.txt  -o $fldr/$(subjsess)_dti_topup_noec_bvecrot
      fi
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : dtifit is estimating tensor model with rotated b-vectors (incl. eddy-correction)..."
        fsl_sub -l $logdir -N topup_dtifit_ec_bvecrot_$(subjsess) dtifit -k $fldr/$(subjsess)_topup_corr_ec_merged -m $fldr/uw_nodif_brain_mask -r $fldr/avg_bvecs_topup_ec.rot  -b $fldr/avg_bvals.txt  -o $fldr/$(subjsess)_dti_topup_ec_bvecrot
      fi
      if [ $TOPUP_USE_EDDY -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : dtifit is estimating tensor model w/o rotated b-vectors (incl. EDDY-correction)..."
        fsl_sub -l $logdir -N topup_dtifit_eddy_norot_$(subjsess) dtifit -k $fldr/$(subjsess)_topup_corr_eddy_merged -m $fldr/uw_nodif_brain_mask -r $fldr/avg_bvecs.txt  -b $fldr/avg_bvals.txt  -o $fldr/$(subjsess)_dti_topup_eddy_norot
      fi
    done
  done
fi
      
#######################
# ----- END TOPUP -----
#######################


waitIfBusy


#######################
# ----- BEGIN FDT -----
#######################

# FDT merging
if [ $FDT_STG1 -eq 1 ] ; then
  echo "----- BEGIN FDT_STG1 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do    
      fldr=$subjdir/$subj/$sess/fdt ; mkdir -p $fldr
      
      if [ -z $pttrn_diffs ] ; then echo "FDT : ERROR : search pattern for DWI files not defined - exiting..." ; exit 1 ; fi
      
      # merge diffs...
      echo "FDT : subj $subj , sess $sess : merging diffs..."
      ls $srcdir/$subj/$sess/$pttrn_diffs | tee $fldr/diff.files
      fsl_sub -l $logdir -N fdt_fslmerge_$(subjsess) fslmerge -t $fldr/diff_merged $(cat $fldr/diff.files)      
    done    
  done
fi

waitIfBusy

# FDT eddy-correct
if [ $FDT_STG2 -eq 1 ] ; then
  echo "----- BEGIN FDT_STG2 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/fdt
      
      # cleanup previous runs...
      rm -f $fldr/ec_diff_merged_*.nii.gz # removing temporary files from prev. run
      if [ -f $fldr/ec_diff_merged.ecclog  ] ; then    
        echo "FDT : subj $subj , sess $sess : WARNING : eddy_correct logfile from a previous run detected... deleting it."
        rm $fldr/ec_diff_merged.ecclog # (!)
      fi
      
      # get B0 index
      b0img=`getB0Index $srcdir/$subj/$sess/"$pttrn_bvals" $fldr/ec_ref.idx | cut -d " " -f 1` ; min=`getB0Index $srcdir/$subj/$sess/"$pttrn_bvals" $fldr/ec_ref.idx | cut -d " " -f 2`

      # eddy-correct in test mode ? (don't apply eddy_correction)
      if [ $FDT_EC_TEST -eq 1 ] ; then 
        ecswitch="-t" ; echo "FDT : subj $subj , sess $sess : NOTE: eddy_correct is in 'testing' mode."
      else
        ecswitch=""
        #ecswitch="-n" ; echo "FDT : subj $subj , sess $sess : NOTE: eddy_correct is in 'no-write-out' mode." 
      fi
      
      # eddy-correct
      echo "FDT : subj $subj , sess $sess : eddy_correct is using volume no. $b0img as B0 (val:${min})..."
      
      # creating task file for fsl_sub, the deletions are needed to avoid accumulations when sge is doing a re-run on error
      echo "rm -f $fldr/ec_diff_merged_*.nii.gz ; \
            rm -f $fldr/ec_diff_merged.ecclog ; \
            $scriptdir/eddy_correct.sh $ecswitch $fldr/diff_merged $fldr/ec_diff_merged $b0img $FDT_EC_DOF $FDT_EC_COST trilinear" > $fldr/fdt_ec.cmd
      fsl_sub -l $logdir -N fdt_eddy_correct_$(subjsess) -t $fldr/fdt_ec.cmd
      
    done
  done
  
  waitIfBusy
  
  # extract b0 reference image from 4D (note: you can use these for both eddy-corrected and non eddy-corrected streams, bc. these b0 images were used as reference for eddy_correct)
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/fdt
      echo "FDT : subj $subj , sess $sess : extract b0 reference image from merged DWIs..."
      fsl_sub -l $logdir -N fdt_fslroi_$(subjsess) fslroi $fldr/diff_merged $fldr/nodif $(cat $fldr/ec_ref.idx) 1  
    done
  done
  
  waitIfBusy
  
  # bet b0 reference image
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/fdt
      
      # get info for current subject
      f=`getBetThres ${subjdir}/config_bet_lowb $subj $sess`

      # bet, if necessary
      if [ $f = "mod" ] ; then
        if [ ! -f $fldr/nodif_brain_${f}.nii.gz  -o ! -f $fldr/nodif_brain_${f}_mask.nii.gz ] ; then   
          echo "FDT : subj $subj , sess $sess : ERROR : externally modified volume (nodif_brain_${f}) & mask (nodif_brain_${f}_mask) not found - exiting..." ; exit 1         
        fi
      else
        echo "FDT : subj $subj , sess $sess : betting B0 image with fi=${f}..."
        bet $fldr/nodif $fldr/nodif_brain_${f} -m -f $f
      fi
      ln -sf nodif_brain_${f}.nii.gz $fldr/nodif_brain.nii.gz
      ln -sf nodif_brain_${f}_mask.nii.gz $fldr/nodif_brain_mask.nii.gz
    done
  done  
fi

waitIfBusy

# FDT unwarp eddy-corrected DWIs
if [ $FDT_STG3 -eq 1 -a $FDT_UNWARP -eq 1 ] ; then
  echo "----- BEGIN FDT_STG3 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do    
      fldr=$subjdir/$subj/$sess/fdt
      
      # check if we have acquisition parameters
      defineDWIparams $subjdir/config_acqparams_dwi $subj $sess
      
      # define magnitude and fieldmap
      fmap=$subjdir/$subj/$sess/$(remove_ext $FDT_FMAP).nii.gz
      fmap_magn=$subjdir/$subj/$sess/$(remove_ext $FDT_MAGN).nii.gz
      if [ $(_imtest $fmap) -eq 0 ] ; then echo "FDT : subj $subj , sess $sess : ERROR : Fieldmap image '$fmap' not found ! Exiting..." ; exit 1 ; fi
      if [ $(_imtest $fmap_magn) -eq 0 ] ; then echo "FDT : subj $subj , sess $sess : ERROR : Fieldmap magnitude image '$fmap_magn' not found ! Exiting..." ; exit 1 ; fi
      
      # get unwarp dir.
      uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_dwi $subj $sess`
      if [ $uw_dir = "-y" ] ; then dir=y- ; fi
      if [ $uw_dir = "+y" ] ; then dir=y ; fi
      
      # unwarp
      echo "FDT : subj $subj , sess $sess : execute unwarp..."
      echo "$scriptdir/feat_unwarp.sh $fldr/nodif_brain.nii.gz $fmap $fmap_magn $dir $TE_diff $EES_diff $FDT_SIGNLOSS_THRES $fldr/uwDWI_${uw_dir}.feat/unwarp ; \
      $scriptdir/apply_mc+unwarp.sh $fldr/diff_merged $fldr/uw_ec_diff_merged $fldr/ec_diff_merged.ecclog $fldr/uwDWI_${uw_dir}.feat/unwarp/EF_UD_shift.nii.gz $dir trilinear" > $fldr/feat_unwarp.cmd
      #cat $fldr/feat_unwarp.cmd
      fsl_sub -l $logdir -N fdt_feat_unwarp_$(subjsess) -t $fldr/feat_unwarp.cmd
    done
  done
  
  waitIfBusy
  
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/fdt
      
      # link to unwarped brainmask
      uwdir=`getUnwarpDir ${subjdir}/config_unwarp_dwi $subj $sess`
      ln -sf ./uwDWI_${uwdir}.feat/unwarp/EF_UD_example_func.nii.gz $fldr/uw_nodif.nii.gz
      ln -sf ./uwDWI_${uwdir}.feat/unwarp/EF_UD_fmap_mag_brain_mask.nii.gz $fldr/uw_nodif_brain_mask.nii.gz  
    done
  done  
fi
    
waitIfBusy

# FDT estimate tensor model
if [ $FDT_STG4 -eq 1 ] ; then
  echo "----- BEGIN FDT_STG4 -----"
  n=0 ; _npts=0 ; npts=0 # variables for counting and comparing number of volumes in the 4Ds
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do    
      fldr=$subjdir/$subj/$sess/fdt
                  
      # number of volumes in 4D
      echo -n "FDT : counting number of volumes in '$fldr/ec_diff_merged.nii.gz'..."
      npts=`countVols $fldr/ec_diff_merged.nii.gz`
      echo " ${npts}."
      if [ $n -gt 0 ] ; then
        if [ ! $npts -eq $_npts ] ; then
          echo "FDT : subj $subj , sess $sess : WARNING : Number of volumes does not match with previous image file in the loop!" 
        fi
      fi
      _npts=$npts
      n=$[$n+1] 

      # display info
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model using nodif_brain_${f}_mask..."
      
      # concatenate bvals and bvecs within session
      concat_bvals $srcdir/$subj/$sess/"$pttrn_bvals" $fldr/bvals_concat.txt
      concat_bvecs $srcdir/$subj/$sess/"$pttrn_bvecs" $fldr/bvecs_concat.txt 
    
      # number of entries in bvals- and bvecs files consistent ?
      checkConsistency "$srcdir/$subj/$sess/$pttrn_diffs" $fldr/bvals_concat.txt $fldr/bvecs_concat.txt
      
      # rotate bvecs
      xfmrot $fldr/ec_diff_merged.ecclog $fldr/bvecs_concat.txt $fldr/bvecs_concat.rot
      
      # estimate tensor model (rotated bvecs)
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - eddy-corr. & corrected b-vectors..."
      fsl_sub -l $logdir -N fdt_dtifit_ec_bvecrot_$(subjsess) dtifit -k $fldr/ec_diff_merged -m $fldr/nodif_brain_mask -r $fldr/bvecs_concat.rot -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_ec_bvecrot
         
      # estimate tensor model (native bvecs)
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - eddy-corr. & native b-vectors..."
      fsl_sub -l $logdir -N fdt_dtifit_ec_norot_$(subjsess) dtifit -k $fldr/ec_diff_merged -m $fldr/nodif_brain_mask -r $fldr/bvecs_concat.txt -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_ec_norot
                    
      # estimate tensor model - no eddy-correction
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - no eddy-correction..."
      fsl_sub -l $logdir -N fdt_dtifit_noec_$(subjsess) dtifit -k $fldr/diff_merged -m $fldr/nodif_brain_mask -r $fldr/bvecs_concat.txt -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_noec   
      
      # did we also unwarp ? If so, then...
      if [ -f $fldr/uw_ec_diff_merged.nii.gz ] ; then
        # estimate tensor model - unwarped and eddy-corrected DWIs (rotated bvecs)
        echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - eddy-corr. unwarped DWIs & corrected b-vectors..."
        fsl_sub -l $logdir -N fdt_dtifit_uw_bvecot_$(subjsess) dtifit -k $fldr/uw_ec_diff_merged -m $fldr/uw_nodif_brain_mask -r $fldr/bvecs_concat.rot -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_uw_bvecrot
        
        # estimate tensor model - unwarped and eddy-corrected DWIs (native bvecs)
        echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - eddy-corr. unwarped DWIs & native b-vectors..."
        fsl_sub -l $logdir -N fdt_dtifit_uw_norot_$(subjsess) dtifit -k $fldr/uw_ec_diff_merged -m $fldr/uw_nodif_brain_mask -r $fldr/bvecs_concat.txt -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_uw_norot
      fi
      
    done    
  done
fi

#####################
# ----- END FDT -----
#####################


waitIfBusy


############################
# ----- BEGIN BEDPOSTX -----
############################


if [ $BPX_STG1 -eq 1 ] ; then
  
  echo "----- BEGIN BPX_STG1 -----"  
  
  # define bedpostx subdirectories
  bpx_dir=""
  
  # define bedpostx options
  if [ x"$BPX_OPTIONS" != "x" ] ; then
    bpx_opts="$BPX_OPTIONS"
  else
    bpx_opts="-n 2 -w 1 -b 1000"
  fi
  
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      if [ $BPX_USE_NOEC -eq 1 ] ; then
          bpx_dir=$subjdir/$subj/$sess/bpx/${BPX_OUTDIR_PREFIX}_noec ; mkdir -p $bpx_dir
          if [ -d ${bpx_dir}.bedpostX ] ; then
            echo "BEDPOSTX : subj $subj , sess $sess : WARNING : removing previous run in '${bpx_dir}.bedpostX' in 5 seconds - press CTRL-C to abort." ; sleep 5
            rm -rf ${bpx_dir}.bedpostX
          fi
          echo "BEDPOSTX : subj $subj , sess $sess : copying bedpostX inputfiles to '$bpx_dir'..."
          cp -v $subjdir/$subj/$sess/fdt/nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
          cp -v $subjdir/$subj/$sess/fdt/bvecs_concat.txt $bpx_dir/bvecs
          cp -v $subjdir/$subj/$sess/fdt/bvals_concat.txt $bpx_dir/bvals
          cp -v $subjdir/$subj/$sess/fdt/diff_merged.nii.gz $bpx_dir/data.nii.gz
          
          echo "BEDPOSTX : subj $subj , sess $sess : executing bedpostX in '$bpx_dir'..."
          echo "bedpostx $bpx_dir $bpx_opts" | tee $bpx_dir/bedpostx.cmd ; . $bpx_dir/bedpostx.cmd
      fi
      if [ $BPX_USE_EC_NOROT -eq 1 ] ; then
          bpx_dir=$subjdir/$subj/$sess/bpx/${BPX_OUTDIR_PREFIX}_ec_norot ; mkdir -p $bpx_dir
          if [ -d ${bpx_dir}.bedpostX ] ; then
            echo "BEDPOSTX : subj $subj , sess $sess : WARNING : removing previous run in '${bpx_dir}.bedpostX' in 5 seconds - press CTRL-C to abort." ; sleep 5
            rm -rf ${bpx_dir}.bedpostX
          fi
          echo "BEDPOSTX : subj $subj , sess $sess : copying bedpostX inputfiles to '$bpx_dir'..."
          cp -v $subjdir/$subj/$sess/fdt/nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
          cp -v $subjdir/$subj/$sess/fdt/bvecs_concat.txt $bpx_dir/bvecs
          cp -v $subjdir/$subj/$sess/fdt/bvals_concat.txt $bpx_dir/bvals
          cp -v $subjdir/$subj/$sess/fdt/ec_diff_merged.nii.gz $bpx_dir/data.nii.gz
          
          echo "BEDPOSTX : subj $subj , sess $sess : executing bedpostX in '$bpx_dir'..."
          echo "bedpostx $bpx_dir $bpx_opts" | tee $bpx_dir/bedpostx.cmd ; . $bpx_dir/bedpostx.cmd
      fi	
      if [ $BPX_USE_EC_BVECROT -eq 1 ] ; then
          bpx_dir=$subjdir/$subj/$sess/bpx/${BPX_OUTDIR_PREFIX}_ec_bvecrot ; mkdir -p $bpx_dir
          if [ -d ${bpx_dir}.bedpostX ] ; then
            echo "BEDPOSTX : subj $subj , sess $sess : WARNING : removing previous run in '${bpx_dir}.bedpostX' in 5 seconds - press CTRL-C to abort." ; sleep 5
            rm -rf ${bpx_dir}.bedpostX
          fi
          echo "BEDPOSTX : subj $subj , sess $sess : copying bedpostX inputfiles to '$bpx_dir'..."
          cp -v $subjdir/$subj/$sess/fdt/nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
          cp -v $subjdir/$subj/$sess/fdt/bvecs_concat.rot $bpx_dir/bvecs
          cp -v $subjdir/$subj/$sess/fdt/bvals_concat.txt $bpx_dir/bvals
          cp -v $subjdir/$subj/$sess/fdt/ec_diff_merged.nii.gz $bpx_dir/data.nii.gz
          
          echo "BEDPOSTX : subj $subj , sess $sess : executing bedpostX in '$bpx_dir'..."
          echo "bedpostx $bpx_dir $bpx_opts" | tee $bpx_dir/bedpostx.cmd ; . $bpx_dir/bedpostx.cmd
      fi
      if [ $BPX_USE_UNWARPED_NOROT -eq 1 ] ; then
          bpx_dir=$subjdir/$subj/$sess/bpx/${BPX_OUTDIR_PREFIX}_uw_norot ; mkdir -p $bpx_dir
          if [ -d ${bpx_dir}.bedpostX ] ; then
            echo "BEDPOSTX : subj $subj , sess $sess : WARNING : removing previous run in '${bpx_dir}.bedpostX' in 5 seconds - press CTRL-C to abort." ; sleep 5
            rm -rf ${bpx_dir}.bedpostX
          fi
          echo "BEDPOSTX : subj $subj , sess $sess : copying bedpostX inputfiles to '$bpx_dir'..."
          cp -v $subjdir/$subj/$sess/fdt/uw_nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
          cp -v $subjdir/$subj/$sess/fdt/bvecs_concat.txt $bpx_dir/bvecs
          cp -v $subjdir/$subj/$sess/fdt/bvals_concat.txt $bpx_dir/bvals
          cp -v $subjdir/$subj/$sess/fdt/uw_ec_diff_merged.nii.gz $bpx_dir/data.nii.gz
          
          echo "BEDPOSTX : subj $subj , sess $sess : executing bedpostX in '$bpx_dir'..."
          echo "bedpostx $bpx_dir $bpx_opts" | tee $bpx_dir/bedpostx.cmd ; . $bpx_dir/bedpostx.cmd
      fi		
      if [ $BPX_USE_UNWARPED_BVECROT -eq 1 ] ; then
          bpx_dir=$subjdir/$subj/$sess/bpx/${BPX_OUTDIR_PREFIX}_uw_bvecrot ; mkdir -p $bpx_dir
          if [ -d ${bpx_dir}.bedpostX ] ; then
            echo "BEDPOSTX : subj $subj , sess $sess : WARNING : removing previous run in '${bpx_dir}.bedpostX' in 5 seconds - press CTRL-C to abort." ; sleep 5
            rm -rf ${bpx_dir}.bedpostX
          fi
          echo "BEDPOSTX : subj $subj , sess $sess : copying bedpostX inputfiles to '$bpx_dir'..."
          cp -v $subjdir/$subj/$sess/fdt/uw_nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
          cp -v $subjdir/$subj/$sess/fdt/bvecs_concat.rot $bpx_dir/bvecs
          cp -v $subjdir/$subj/$sess/fdt/bvals_concat.txt $bpx_dir/bvals
          cp -v $subjdir/$subj/$sess/fdt/uw_ec_diff_merged.nii.gz $bpx_dir/data.nii.gz
          
          echo "BEDPOSTX : subj $subj , sess $sess : executing bedpostX in '$bpx_dir'..."
          echo "bedpostx $bpx_dir $bpx_opts" | tee $bpx_dir/bedpostx.cmd ; . $bpx_dir/bedpostx.cmd
       fi
       if [ $BPX_USE_TOPUP_NOEC_BVECROT -eq 1 ] ; then
          bpx_dir=$subjdir/$subj/$sess/bpx/${BPX_OUTDIR_PREFIX}_topup_noec_bvecrot ; mkdir -p $bpx_dir
          if [ -d ${bpx_dir}.bedpostX ] ; then
            echo "BEDPOSTX : subj $subj , sess $sess : WARNING : removing previous run in '${bpx_dir}.bedpostX' in 5 seconds - press CTRL-C to abort." ; sleep 5
            rm -rf ${bpx_dir}.bedpostX
          fi
          echo "BEDPOSTX : subj $subj , sess $sess : copying bedpostX inputfiles to '$bpx_dir'..."
          cp -v $subjdir/$subj/$sess/topup/uw_nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
          cp -v $subjdir/$subj/$sess/topup/avg_bvecs_topup.rot $bpx_dir/bvecs
          cp -v $subjdir/$subj/$sess/topup/avg_bvals.txt $bpx_dir/bvals
          cp -v $subjdir/$subj/$sess/topup/$(subjsess)_topup_corr_merged.nii.gz $bpx_dir/data.nii.gz

          echo "BEDPOSTX : subj $subj , sess $sess : executing bedpostX in '$bpx_dir'..."
          echo "bedpostx $bpx_dir $bpx_opts" | tee $bpx_dir/bedpostx.cmd ; . $bpx_dir/bedpostx.cmd
       fi
       if [ $BPX_USE_TOPUP_EC_BVECROT -eq 1 ] ; then
          bpx_dir=$subjdir/$subj/$sess/bpx/${BPX_OUTDIR_PREFIX}_topup_ec_bvecrot ; mkdir -p $bpx_dir
          if [ -d ${bpx_dir}.bedpostX ] ; then
            echo "BEDPOSTX : subj $subj , sess $sess : WARNING : removing previous run in '${bpx_dir}.bedpostX' in 5 seconds - press CTRL-C to abort." ; sleep 5
            rm -rf ${bpx_dir}.bedpostX
          fi
          echo "BEDPOSTX : subj $subj , sess $sess : copying bedpostX inputfiles to '$bpx_dir'..."
          cp -v $subjdir/$subj/$sess/topup/uw_nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
          cp -v $subjdir/$subj/$sess/topup/avg_bvecs_topup_ec.rot $bpx_dir/bvecs
          cp -v $subjdir/$subj/$sess/topup/avg_bvals.txt $bpx_dir/bvals
          cp -v $subjdir/$subj/$sess/topup/$(subjsess)_topup_corr_ec_merged.nii.gz $bpx_dir/data.nii.gz
          
          echo "BEDPOSTX : subj $subj , sess $sess : executing bedpostX in '$bpx_dir'..."
          echo "bedpostx $bpx_dir $bpx_opts" | tee $bpx_dir/bedpostx.cmd ; . $bpx_dir/bedpostx.cmd
       fi	
       if [ $BPX_USE_TOPUP_EDDY_NOROT -eq 1 ] ; then
          bpx_dir=$subjdir/$subj/$sess/bpx/${BPX_OUTDIR_PREFIX}_topup_eddy_norot ; mkdir -p $bpx_dir
          if [ -d ${bpx_dir}.bedpostX ] ; then
            echo "BEDPOSTX : subj $subj , sess $sess : WARNING : removing previous run in '${bpx_dir}.bedpostX' in 5 seconds - press CTRL-C to abort." ; sleep 5
            rm -rf ${bpx_dir}.bedpostX
          fi
          echo "BEDPOSTX : subj $subj , sess $sess : copying bedpostX inputfiles to '$bpx_dir'..."
          cp -v $subjdir/$subj/$sess/topup/uw_nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
          cp -v $subjdir/$subj/$sess/topup/avg_bvecs.txt $bpx_dir/bvecs
          cp -v $subjdir/$subj/$sess/topup/avg_bvals.txt $bpx_dir/bvals
          cp -v $subjdir/$subj/$sess/topup/$(subjsess)_topup_corr_eddy_merged.nii.gz $bpx_dir/data.nii.gz
          
          echo "BEDPOSTX : subj $subj , sess $sess : executing bedpostX in '$bpx_dir'..."
          echo "bedpostx $bpx_dir $bpx_opts" | tee $bpx_dir/bedpostx.cmd ; . $bpx_dir/bedpostx.cmd
       fi	
		done
	done
fi

##########################
# ----- END BEDPOSTX -----
##########################


waitIfBusy


#########################
# ----- BEGIN RECON -----
#########################

# RECON-ALL prepare 
if [ $RECON_STG1 -eq 1 ] ; then
  echo "----- BEGIN RECON_STG1 -----"
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$FS_subjdir/$(subjsess)/mri/orig
      mkdir -p $fldr
      
      # reorient to please fslview
      file=`ls ${srcdir}/${subj}/${sess}/${pttrn_strucs} | tail -n 1` # take last, check pattern (!)
      echo "RECON : subj $subj , sess $sess : reorienting T1 ('$file') to please fslview..."
      $scriptdir/fslreorient2std.sh $file $fldr/tmp_t1
      
      # convert to .mgz
      echo "RECON : subj $subj , sess $sess : converting T1 to .mgz format..."
      mri_convert $fldr/tmp_t1.nii.gz $fldr/001.mgz &>$logdir/recon_mri_convert_$(subjsess) # fslreorient2std above is probably useless...
      rm -f $fldr/tmp_t1.nii.gz
    done
  done
fi

waitIfBusy

# RECON-ALL execute
if [ $RECON_STG2 -eq 1 ] ; then
  echo "----- BEGIN RECON_STG2 -----"
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$FS_subjdir/$(subjsess)
      
      echo "RECON : subj $subj , sess $sess : executing recon-all..."
      
      # use CUDA if available...
      if [ $RECON_USE_CUDA = 1 ] ; then exitflag=0 ; else exitflag=X ; fi
      
      # additional switches
      if [ $RECON_USE_MRITOTAL = 1 ] ; then opts="-use-mritotal" ; else opts="" ; fi # -use-mritotal may give better talairach transforms (!)
      
      echo '#!/bin/bash' > $fldr/recon-all_cuda.sh
      echo 'cudadetect &>/dev/null' >>  $fldr/recon-all_cuda.sh
      echo "if [ \$? = $exitflag ] ; then recon-all -all -use-gpu -no-isrunning -noappend -clean-tal -tal-check $opts -subjid $(subjsess)" >> $fldr/recon-all_cuda.sh # you may want to remove clean-tal flag (!)
      echo "else  recon-all -all -no-isrunning -noappend -clean-tal -tal-check $opts -subjid $(subjsess) ; fi" >> $fldr/recon-all_cuda.sh
      chmod +x $fldr/recon-all_cuda.sh
      
      # execute...
      $scriptdir/fsl_sub_NOPOSIXLY.sh -l $logdir -N recon-all_$(subjsess) $fldr/recon-all_cuda.sh
    done
  done
fi

waitIfBusy

if [ $RECON_STG3 -eq 1 ] ; then
  echo "----- BEGIN RECON_STG3 -----"
  for subj in `cat subjects`; do
    if [ "$(cat ${subj}/sessions_struc)" = "." ] ; then echo "RECON : subj $subj : ERROR : single-session design ! Skipping longitudinal freesurfer stream..." ; continue ; fi
    
    # create template dir.
    fldr=$FS_subjdir/$subj
    mkdir -p $fldr
    
    # init. command line
    cmd="recon-all -base $subj"
    
    # generate command line
    for sess in `cat ${subj}/sessions_struc` ; do
      cmd="$cmd -tp $(subjsess)" 
    done
    
    # additional switches
    if [ $RECON_USE_MRITOTAL = 1 ] ; then opts="-use-mritotal" ; else opts="" ; fi
    
    # executing...
    echo "RECON : subj $subj , sess $sess : executing recon-all - unbiased template generation..."
    cmd="$cmd -all -no-isrunning -noappend -clean-tal -tal-check $opts"
    echo $cmd | tee $fldr/recon-all_base.cmd
    $scriptdir/fsl_sub_NOPOSIXLY.sh -l $logdir -N recon-all_base_${subj} -t $fldr/recon-all_base.cmd
  done
fi 

waitIfBusy

if [ $RECON_STG4 -eq 1 ] ; then
  echo "----- BEGIN RECON_STG4 -----"
  for subj in `cat subjects`; do
    if [ "$(cat ${subj}/sessions_struc)" = "." ] ; then echo "RECON : subj $subj : ERROR : single-session design ! Skipping longitudinal freesurfer stream..." ; continue ; fi
    
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$FS_subjdir/$(subjsess)
      
      # generate command line
      cmd="recon-all -long $(subjsess) $subj -all -no-isrunning -noappend"
      
      # executing...
      echo "RECON : subj $subj , sess $sess : executing recon-all - longitudinal stream..."
      echo $cmd | tee $fldr/recon-all_long.cmd
      $scriptdir/fsl_sub_NOPOSIXLY.sh -l $logdir -N recon-all_long_$(subjsess) -t $fldr/recon-all_long.cmd
    done    
  done
fi 

waitIfBusy

if [ $RECON_STG5 -eq 1 ] ; then
  echo "----- BEGIN RECON_STG5 -----"

  # register Freesurfer's longit. template (if applicable) or brain.mgz to FSL'S MNI152
  for subj in `cat subjects` ; do
            
    # check
    if [ "$(cat ${subj}/sessions_struc)" = "." ] ; then 
      echo "RECON : subj $subj : single-session design !"
      template=$FS_subjdir/$subj/mri/brain.mgz
      if [ -f $template ] ; then
        echo "RECON : subj $subj : registering Freesurfer's brain.mgz to FSL's MNI152 template..."
      else
        echo "RECON : subj $subj : ERROR : '$template' not found ! Exiting..." ; exit 1
      fi
    else
      template=$FS_subjdir/$subj/mri/norm_template.mgz
      if [ -f $template ] ; then
        echo "RECON : subj $subj : registering Freesurfer's longitudinal template (norm_template.mgz) to FSL's MNI152 template..."
      else
        echo "RECON : subj $subj : ERROR : longitudinal template '$template' not found ! Exiting..." ; exit 1
      fi
    fi
    
    # prepare...
    echo "RECON : subj $subj : preparing..."
    FS_fldr=$FS_subjdir/$subj/fsl_reg ; mkdir -p $FS_fldr
    MNI_brain=$FS_fldr/longt_standard.nii.gz
    MNI_head=$FS_fldr/longt_standard_head.nii.gz
    MNI_mask=$FS_fldr/longt_standard_mask.nii.gz
    cp -v $FSL_DIR/data/standard/MNI152_T1_2mm.nii.gz $MNI_head
    cp -v $FSL_DIR/data/standard/MNI152_T1_2mm_brain.nii.gz $MNI_brain
    cp -v $FSL_DIR/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz $MNI_mask
    
    # convert to FSL-format
    $scriptdir/fs_convert.sh $FS_subjdir/$subj/mri/T1.mgz $FS_fldr/longt_head.nii.gz 0
    $scriptdir/fs_convert.sh $template $FS_fldr/longt_brain.nii.gz 0 
          
    # generate command line
    cmd="$scriptdir/feat_T1_2_MNI.sh $FS_fldr/longt_head $FS_fldr/longt_brain $FS_fldr/longt_head2longt_standard none corratio $scriptdir/LIA_to_LAS_conformed.mat $MNI_head $MNI_brain $MNI_mask $subj --"
    
    # executing...
    cmd_file=$FS_subjdir/$subj/recon_longt2mni152.cmd
    log_file=recon_longt2mni152_${subj}
    echo "RECON : subj $subj : executing '$cmd_file'"
    echo "$cmd" | tee $cmd_file
    fsl_sub -l $logdir -N $log_file -t $cmd_file
  done
fi

#########################
# ----- END RECON -----
#########################


waitIfBusy


###############################
# ----- BEGIN VBM PREPROC -----
###############################

# VBM PREPROC prepare T1
if [ $VBM_STG1 -eq 1 ] ; then
  echo "----- BEGIN VBM_STG1 -----"
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/vbm
      
      # create vbm directory     
      mkdir -p $fldr

      # list and copy anatomical t1 images
      echo "VBM PREPROC : subj $subj , sess $sess : copying T1 image to ${fldr}..."
      file=`ls ${srcdir}/${subj}/${sess}/${pttrn_strucs} | tail -n 1` # take last, check (!)
      fslmaths $file ${fldr}/$(subjsess)_t1_orig
      
      # reorient for fslview
      $scriptdir/fslreorient2std.sh $file ${fldr}/$(subjsess)_t1_reor
      ln -sf $(subjsess)_t1_reor.nii.gz $fldr/$(subjsess)_t1_struc.nii.gz
      
      # convert to .mnc & perform non-uniformity correction
      if [ $VBM_NU_CORRECT_T1 -eq 1 ] ; then
        echo "VBM PREPROC : subj $subj , sess $sess : performing non-uniformity correction..."
        echo "mri_convert ${fldr}/$(subjsess)_t1_reor.nii.gz $fldr/tmp.mnc ; \
        nu_correct -clobber $fldr/tmp.mnc $fldr/t1_nu_struc.mnc; \
        mri_convert $fldr/t1_nu_struc.mnc $fldr/$(subjsess)_t1_nu_struc.nii.gz -odt float; \
        rm -f $fldr/tmp.mnc ; rm -f $fldr/t1_nu_struc.mnc ; \
        ln -sf $(subjsess)_t1_nu_struc.nii.gz $fldr/$(subjsess)_t1_struc.nii.gz" > $fldr/vbm_nu_correct.cmd
        
        fsl_sub -l $logdir -N vbm_nu_correct_$(subjsess) -t $fldr/vbm_nu_correct.cmd
      fi      
    done
  done

  waitIfBusy

  # also obtain skull-stripped volumes from FREESURFER, if available
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      if [ -f $FS_subjdir/$(subjsess)/mri/brain.mgz ] ; then
        fldr=$subjdir/$subj/$sess/vbm
        echo "VBM PREPROC : subj $subj , sess $sess : applying FREESURFER brain-mask to '$(subjsess)_t1_struc.nii.gz' (-> '$(subjsess)_FS_brain.nii.gz' & '$(subjsess)_FS_struc.nii.gz')..."
        echo "mri_convert $FS_subjdir/$(subjsess)/mri/brain.mgz $fldr/$(subjsess)_FS_brain.nii.gz -odt float ;\
        fslmaths $fldr/$(subjsess)_FS_brain.nii.gz -bin $fldr/$(subjsess)_FS_brain_mask.nii.gz ;\
        mri_convert --conform $fldr/$(subjsess)_t1_struc.nii.gz $fldr/$(subjsess)_FS_struc.nii.gz -odt float ;\
        fslmaths $fldr/$(subjsess)_FS_struc.nii.gz -mas $fldr/$(subjsess)_FS_brain_mask.nii.gz $fldr/$(subjsess)_FS_brain.nii.gz ;\
        fslreorient2std $fldr/$(subjsess)_FS_brain.nii.gz $fldr/$(subjsess)_FS_brain.nii.gz ;\
        fslreorient2std $fldr/$(subjsess)_FS_struc.nii.gz $fldr/$(subjsess)_FS_struc.nii.gz ;\
        fslreorient2std $fldr/$(subjsess)_FS_brain_mask.nii.gz $fldr/$(subjsess)_FS_brain_mask.nii.gz" > $fldr/vbm_FSbrainmask.cmd
        fsl_sub -l $logdir -N vbm_FSbrainmask_$(subjsess) -t $fldr/vbm_FSbrainmask.cmd
      else
        echo "VBM PREPROC : subj $subj , sess $sess : no FREESURFER processed MRIs found."
      fi
    done
  done
  
  waitIfBusy
  
  # also execute fsl_anat script (fsl v.5) if applicable
  if [ $VBM_FSLV5 -eq 1 ] ; then
    if [ ! -f $FSL_DIR/bin/fsl_anat ] ; then echo "VBM PREPROC : ERROR : fsl_anat not found... is this really FSL v.5 ? Exiting." ; exit 1 ; fi
    for subj in `cat subjects`; do 
      for sess in `cat ${subj}/sessions_struc` ; do
        echo "VBM PREPROC : subj $subj , sess $sess : 'fsl_anat' is being executed..."
        fldr=$subjdir/$subj/$sess/vbm
        fsl_sub -l $logdir -N vbm_fsl_anat_$(subjsess) fsl_anat --clobber --noseg --nosubcortseg -i ${fldr}/$(subjsess)_t1_orig
      done
    done
  fi
  
fi

waitIfBusy

# VBM PREPROC initial skull strip
if [ $VBM_STG2 -eq 1 ] ; then
  echo "----- BEGIN VBM_STG2 -----"
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do  
      fldr=$subjdir/$subj/$sess/vbm

      # get infos for bet
      CoG=`getBetCoG ${subjdir}/config_bet_struc0 $subj $sess`    
      echo "VBM PREPROC : subj $subj , sess $sess : bet: Center of Gravity: $CoG"
      f=`getBetThres ${subjdir}/config_bet_struc0 $subj $sess`
      echo "VBM PREPROC : subj $subj , sess $sess : bet: FI Threshold: $f"
      
      ## use t2 image for betting if available
      betT2=""
      #if [ -d $subjdir/$subj/$sess/fdt -a x"$pttrn_diffs" != "x" -a x"$pttrn_bvals" != "x" ] ; then 
        #dwi=$(ls $srcdir/$subj/$sess/$pttrn_diffs | head -n1)
        #bval=$(ls $srcdir/$subj/$sess/$pttrn_bvals | head -n1)
        ## get B0 index
        #b0idx=`getB0Index $bval $fldr/b0.idx | cut -d " " -f 1` ; min=`getB0Index $bval $fldr/b0.idx | cut -d " " -f 2`
        #fslroi $dwi $fldr/b0 $b0idx 1
        #betT2="-A2 $fldr/b0.nii.gz"
        #rm $fldr/b0.idx
      #fi

      # betting (if no externally modified skull-stripped volume is supplied)
      if [ $f = "mod" ] ; then 
        imcp ${fldr}/$(subjsess)_t1_betted_initbrain_mod ${fldr}/$(subjsess)_t1_betted_initbrain
        ln -sf $(subjsess)_t1_betted_initbrain_mod $fldr/$(subjsess)_t1_initbrain.nii.gz       
      else
        fsl_sub -l $logdir -N vbm_bet_$(subjsess) bet ${fldr}/$(subjsess)_t1_struc  ${fldr}/$(subjsess)_t1_betted_initbrain `getBetCoGOpt "$CoG"` `getBetFIOpt $f` $betT2
        fsl_sub -l $logdir -N vbm_watershed_$(subjsess) mri_watershed ${fldr}/$(subjsess)_t1_struc.nii.gz  ${fldr}/$(subjsess)_t1_watershed_initbrain.nii.gz
        
        if [ $VBM_USE_WATERSHED_INIT -eq 1 ] ; then
          echo "VBM PREPROC : subj $subj , sess $sess : using waterhsed initbrain for subsequent processing..."
          ln -sf $(subjsess)_t1_watershed_initbrain.nii.gz $fldr/$(subjsess)_t1_initbrain.nii.gz
        fi
        
        if [ $VBM_USE_BETTED_INIT -eq 1 ] ; then 
          echo "VBM PREPROC : subj $subj , sess $sess : using betted initbrain for subsequent processing..."
          ln -sf $(subjsess)_t1_betted_initbrain.nii.gz $fldr/$(subjsess)_t1_initbrain.nii.gz
        fi
      fi      
    done
  done
fi

waitIfBusy

# VBM PREPROC SSM apply standard space mask (SSM)
if [ $VBM_STG3 -eq 1 ] ; then
  echo "----- BEGIN VBM_STG3 -----"
  # VBM PREPROC SSM flirting Brain to MNI
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr="$subjdir/${subj}/${sess}/vbm"
      t1Brain="${fldr}/$(subjsess)_t1_initbrain"      
      echo "VBM PREPROC : subj $subj , sess $sess : flirting $t1Brain to MNI..."
      fsl_sub -l $logdir -N vbm_flirt_$(subjsess) flirt -in ${t1Brain} -ref $FSLDIR/data/standard/MNI152_T1_1mm_brain -out ${fldr}/flirted_t1_brain -dof 12 -omat ${fldr}/t1_to_MNI        
    done
  done

  waitIfBusy

  # VBM PREPROC SSM flirting standard mask to T1 space
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr="$subjdir/${subj}/${sess}/vbm"; t1=${fldr}/$(subjsess)_t1_struc
      echo "VBM PREPROC : subj $subj , sess $sess : flirting standard mask to T1 space..."
      convert_xfm -omat ${fldr}/MNI_to_t1 -inverse ${fldr}/t1_to_MNI
      fsl_sub -l $logdir -N vbm_flirt_$(subjsess) flirt -in  $FSLDIR/data/standard/MNI152_T1_1mm_first_brain_mask -out ${fldr}/t1_mask -ref $t1 -applyxfm -init ${fldr}/MNI_to_t1         
    done
  done

  waitIfBusy

  # VBM PREPROC SSM creating mask
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/${subj}/${sess}/vbm
      echo "VBM PREPROC : subj $subj , sess $sess : creating mask..."
      fslmaths ${fldr}/t1_mask -thr 0 -bin  ${fldr}/t1_mask -odt char
      fslmaths ${fldr}/t1_mask -mul -1 -add 1 -bin ${fldr}/t1_mask_inv_ero0
    done
  done

  waitIfBusy

  # VBM PREPROC SSM eroding mask
  n_ero=0
  for n_ero in `seq 1 $VBM_SSM_ERODE_STEPS` ; do
    for subj in `cat subjects`; do 
      for sess in `cat ${subj}/sessions_struc` ; do
        fldr=$subjdir/${subj}/${sess}/vbm
        echo "VBM PREPROC : subj $subj , sess $sess : eroding mask - iteration ${n_ero} / ${VBM_SSM_ERODE_STEPS}..."
        fsl_sub -l $logdir -N vbm_fslmaths_$(subjsess) fslmaths ${fldr}/t1_mask_inv_ero$(echo $n_ero -1 | bc -l) -ero -bin ${fldr}/t1_mask_inv_ero${n_ero}
      done
    done
    
    waitIfBusy
    
  done


  # VBM PREPROC SSM masking native T1
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/${subj}/${sess}/vbm;  t1=${fldr}/$(subjsess)_t1_struc
      echo "VBM PREPROC : subj $subj , sess $sess : applying standard space mask..."
      fslmaths ${fldr}/t1_mask_inv_ero${n_ero} -mul -1 -add 1 -bin ${fldr}/t1_mask_ero
      fslmaths $t1 -mas ${fldr}/t1_mask_ero ${fldr}/$(subjsess)_t1_masked
    done
  done
fi

waitIfBusy

# VBM PREPROC final skull strip - bet
if [ $VBM_STG4 -eq 1 ] ; then
  echo "----- BEGIN VBM_STG4 -----"
  if [ $VBM_STG3 -eq 0 ] ; then masked="" ; input="_t1_initbrain.nii.gz" ; fi
  if [ $VBM_STG3 -eq 1 ] ; then masked="_masked" ; input="_t1_masked.nii.gz" ; fi
  
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/vbm
      
       # get info for bet
      CoG=`getBetCoG ${subjdir}/config_bet_struc1 $subj $sess`    
      echo "VBM PREPROC : subj $subj , sess $sess : bet: Center of Gravity: $CoG"
      f=`getBetThres ${subjdir}/config_bet_struc1 $subj $sess`
      echo "VBM PREPROC : subj $subj , sess $sess : bet: FI Threshold: $f"
      # betting...    
      fsl_sub -l $logdir -N vbm_bet_$(subjsess) bet $fldr/$(subjsess)${input} $fldr/$(subjsess)_t1_betted${masked}_brain `getBetCoGOpt "$CoG"` `getBetFIOpt $f`
    done
  done
  
  waitIfBusy  
  
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/vbm
      
      echo "VBM PREPROC : subj $subj , sess $sess : creating binary mask from betted brain..."
      fslmaths $fldr/$(subjsess)_t1_betted${masked}_brain -bin $fldr/$(subjsess)_t1_betted${masked}_brain_mask
    done
  done
fi

waitIfBusy

# VBM PREPROC final skull strip - watershed
if [ $VBM_STG5 -eq 1 ] ; then
  echo "----- BEGIN VBM_STG5 -----"
  if [ $VBM_STG3 -eq 0 ] ; then masked="" ; input="_t1_initbrain.nii.gz" ; fi
  if [ $VBM_STG3 -eq 1 ] ; then masked="_masked" ; input="_t1_masked.nii.gz" ; fi
  
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/vbm
      
      # watershed...
      echo "VBM PREPROC : subj $subj , sess $sess : watershedding..."
      fsl_sub -l $logdir -N vbm_watershed1_$(subjsess) mri_watershed $fldr/$(subjsess)${input} $fldr/$(subjsess)_t1_watershed${masked}_brain.nii.gz
      fsl_sub -l $logdir -N vbm_watershed2_$(subjsess) mri_watershed $fldr/$(subjsess)_t1_betted${masked}_brain.nii.gz $fldr/$(subjsess)_t1_watershed_betted${masked}_brain.nii.gz
    done
  done
  
  waitIfBusy
  
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/vbm
      
      echo "VBM PREPROC : subj $subj , sess $sess : creating binary mask from watershedded brain..."
      fslmaths $fldr/$(subjsess)_t1_watershed${masked}_brain -bin $fldr/$(subjsess)_t1_watershed${masked}_brain_mask
      fslmaths $fldr/$(subjsess)_t1_watershed_betted${masked}_brain -bin $fldr/$(subjsess)_t1_watershed_betted${masked}_brain_mask
    done
  done
fi

#############################
# ----- END VBM PREPROC -----
#############################


waitIfBusy


###########################
# ----- BEGIN TRACULA -----
###########################

# TRACULA prepare 
if [ $TRACULA_STG1 -eq 1 ] ; then
  echo "----- BEGIN TRACULA_STG1 -----"
  if [ ! -f $tmpltdir/template_tracula.rc ] ; then echo "TRACULA : ERROR : template file not found. Exiting..." ; exit 1 ; fi
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
    
      # create dest. folder
      fldr=$FS_subjdir/$(subjsess) ; mkdir -p $fldr
    
      # display info
      echo "TRACULA : subj $subj , sess $sess : preparing TRACULA in $fldr..."
                  
      # get BET info
      thr=`getBetThres $subjdir/config_bet_lowb $subj`
      echo "TRACULA : subj $subj , sess $sess : bet: FI Threshold: $thr"      
            
      # copy config-template to FS folder
      echo "TRACULA : subj $subj , sess $sess : creating config file ${fldr}/tracula.rc" 
      cp $tmpltdir/template_tracula.rc $fldr/tracula.rc
      
      # substitute TRACULA configuration
      sed -i "s|setenv SUBJECTS_DIR X|setenv SUBJECTS_DIR $FS_subjdir|g" $fldr/tracula.rc
      sed -i "s|set dtroot = X|set dtroot = $FS_subjdir|g" $fldr/tracula.rc
      sed -i "s|set subjlist = (X)|set subjlist = ($(subjsess))|g" $fldr/tracula.rc
      sed -i "s|set dcmroot = X|set dcmroot = $FS_subjdir|g" $fldr/tracula.rc
      sed -i "s|set dcmlist = (X)|set dcmlist = ($(subjsess)/diff_merged.nii.gz)|g" $fldr/tracula.rc
      sed -i "s|set bvalfile = X|set bvalfile = ($FS_subjdir/$(subjsess)/bvals_transp.txt)|g" $fldr/tracula.rc
      sed -i "s|set bvecfile = X|set bvecfile = ($FS_subjdir/$(subjsess)/bvecs_transp.txt)|g" $fldr/tracula.rc
      sed -i "s|set thrbet = X|set thrbet = $thr|g" $fldr/tracula.rc
      
      # link to appropiate files and adapt TRACULA settings...
      echo "TRACULA : subj $subj , sess $sess : linking to appropriate bvals/bvecs files and DWI files..."
      if [ $TRACULA_USE_NATIVE -eq 1 ] ; then
        echo "TRACULA : subj $subj , sess $sess : linking to native DWIs..."
        # are bvals and bvecs already concatenated ?
        if [ ! -f $subj/$sess/fdt/bvals_concat.txt -o ! -f $subj/$sess/fdt/bvecs_concat.txt ] ; then
          echo "TRACULA : subj $subj , sess $sess : creating concatenated bvals and bvecs file..."
          concat_bvals $srcdir/$subj/$sess/"$pttrn_bvals" $fldr/bvals_concat.txt
          concat_bvecs $srcdir/$subj/$sess/"$pttrn_bvecs" $fldr/bvecs_concat.txt
        else
          ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/fdt/)/bvals_concat.txt  $fldr/bvals_concat.txt
          ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/fdt/)/bvecs_concat.txt  $fldr/bvecs_concat.txt
        fi        
        
        # are DWIs already concatenated ?
        if [ -f $subj/$sess/fdt/diff_merged.nii.gz ] ; then
          ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/fdt/)/diff_merged.nii.gz  $fldr/diff_merged.nii.gz
        else
          echo "TRACULA : subj $subj , sess $sess : no pre-existing 4D file found - merging diffusion files..."
          diffs=`ls $srcdir/$subj/$sess/$pttrn_diffs`          
          fsl_sub -l $logdir -N trac_fslmerge_$(subjsess) fslmerge -t $fldr/diff_merged $diffs 
        fi
        
        # tracula shall perform eddy-correction
        sed -i "s|set doeddy = .*|set doeddy = 1|g" $fldr/tracula.rc
        sed -i "s|set dorotbvecs = .*|set dorotbvecs = 1|g" $fldr/tracula.rc 
      elif [ $TRACULA_USE_UNWARPED_BVECROT -eq 1 ] ; then          
        # is fdt directory present ?
        if [ ! -d $subjdir/$subj/$sess/fdt ] ; then echo "TRACULA : subj $subj , sess $sess : ERROR : you must run the FDT-stream first - breaking loop..." ; break ; fi
        
        echo "TRACULA : subj $subj , sess $sess : linking to unwarped DWIs (and corrected b-vectors)..."
        
        # path_abs2rel: mind trailing "/"
        ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/fdt/)/bvals_concat.txt  $fldr/bvals_concat.txt
        ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/fdt/)/bvecs_concat.rot  $fldr/bvecs_concat.txt
        ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/fdt/)/uw_ec_diff_merged.nii.gz  $fldr/diff_merged.nii.gz
        
        # tracula shall not eddy-correct
        sed -i "s|set doeddy = .*|set doeddy = 0|g" $fldr/tracula.rc
        sed -i "s|set dorotbvecs = .*|set dorotbvecs = 0|g" $fldr/tracula.rc
      elif [ $TRACULA_USE_TOPUP_NOEC_BVECROT -eq 1 ] ; then
        # is topup directory present ?
        if [ ! -d $subjdir/$subj/$sess/topup ] ; then echo "TRACULA : subj $subj , sess $sess : ERROR : you must run the TOPUP-stream first - breaking loop..." ; break ; fi
        
        echo "TRACULA : subj $subj , sess $sess : linking to TOPUP corrected DWIs (and corrected b-vectors)..."
        ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/topup/)/avg_bvals.txt $fldr/bvals_concat.txt
        ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/topup/)/avg_bvecs_topup.rot $fldr/bvecs_concat.txt
        ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/topup/)/$(subjsess)_topup_corr_merged.nii.gz $fldr/diff_merged.nii.gz
        
        # tracula shall not eddy-correct
        sed -i "s|set doeddy = .*|set doeddy = 0|g" $fldr/tracula.rc
        sed -i "s|set dorotbvecs = .*|set dorotbvecs = 0|g" $fldr/tracula.rc # b-vec. correction in TRACULA will be incorrect for TOPUP corrected files, bc. TOPUP does a rigid body alignment that must be accounted for before running TRACULA
      elif [ $TRACULA_USE_TOPUP_EC_BVECROT -eq 1 ] ; then
        # is topup directory present ?
        if [ ! -d $subjdir/$subj/$sess/topup ] ; then echo "TRACULA : subj $subj , sess $sess : ERROR : you must run the TOPUP-stream first - breaking loop..." ; break ; fi
        
        echo "TRACULA : subj $subj , sess $sess : linking to TOPUP corrected, eddy-corrected DWIs (and corrected b-vectors)..."
        ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/topup/)/avg_bvals.txt $fldr/bvals_concat.txt
        ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/topup/)/avg_bvecs_topup_ec.rot $fldr/bvecs_concat.txt
        ln -sfv $(path_abs2rel $fldr/ $subjdir/$subj/$sess/topup/)/$(subjsess)_topup_corr_ec_merged.nii.gz $fldr/diff_merged.nii.gz
       
        # tracula shall not eddy-correct
        sed -i "s|set doeddy = .*|set doeddy = 0|g" $fldr/tracula.rc
        sed -i "s|set dorotbvecs = .*|set dorotbvecs = 0|g" $fldr/tracula.rc
      fi
      
      # transpose bvals and bvecs files to please TRACULA
      echo "TRACULA : subj $subj , sess $sess : transpose fsl-style bvals / bvecs files to please TRACULA..."
      transpose $fldr/bvals_concat.txt > $fldr/_bvals_transp.txt; cat $fldr/_bvals_transp.txt | wc
      transpose $fldr/bvecs_concat.txt > $fldr/bvecs_transp.txt; cat $fldr/bvecs_transp.txt | wc
      
      # replace b0-value with 0 (to please TRACULA)
      min=$(cat $fldr/_bvals_transp.txt | getMin)
      echo "TRACULA : subj $subj , sess $sess : if b0 value in bvals > 0: replace with zero to please TRACULA (min. is ${min})..."
      cat $fldr/_bvals_transp.txt | sed -e "s|^${min}$|0|g ; s|^${min}.|0.|g" > $fldr/bvals_transp.txt
      rm $fldr/_bvals_transp.txt
      
      # count number of low B images
      nb0=0;
      lowB=`cat $fldr/bvals_transp.txt | getMin`
      for bval in `cat $fldr/bvals_transp.txt` ; do 
        bval=`printf '%.0f' $bval` # strip zeroes
        if [ "$bval" = "$lowB" ] ; then  nb0=$[$nb0+1] ; fi
      done
      echo "TRACULA : subj $subj , sess $sess : $nb0 low-B images counted (val:${lowB})"
      sed -i "s|set nb0 = X|set nb0 = 1|g" $fldr/tracula.rc # set to '1': tracula averages the first n images of the 4D diff. volume, no matter if these are really b0 images or not (!)
      
      ## diff-file present ?
      #if [ ! -f $fldr/diff_merged.nii.gz ] ; then echo "TRACULA : subj $subj , sess $sess : ERROR : $fldr/diff_merged.nii.gz not found - skipping consistency check..." ; continue ; fi
            
      # check consistency
      checkConsistency $fldr/diff_merged.nii.gz $fldr/bvals_transp.txt $fldr/bvecs_transp.txt
      
      echo ""
    done
  done
fi

waitIfBusy

# TRACULA execute -prep
if [ $TRACULA_STG2 -eq 1 ] ; then
  echo "----- BEGIN TRACULA_STG2 -----"  
  errflag=0
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$FS_subjdir/$(subjsess)
      if [ ! -f $fldr/mri/aparc+aseg.mgz ] ; then echo "TRACULA : subj $subj , sess $sess : ERROR : aparc+aseg.mgz file not found - did you run recon-all ?" ; errflag=1 ;  fi
    done
  done
  if [ $errflag = 1 ] ; then echo "TRACULA : subj $subj , sess $sess : ERROR : you must run recon-all for all subjects before executing TRACULA - exiting..." ; exit 1 ; fi
  
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$FS_subjdir/$(subjsess)
      echo "TRACULA : subj $subj , sess $sess : executing trac-all -prep command:"
      echo "fsl_sub -l $logdir -N trac-all-prep_$(subjsess) trac-all -no-isrunning -noappendlog -prep -c $fldr/tracula.rc" | tee $fldr/trac-all_prep.cmd
      #echo "$scriptdir/fsl_sub_NOPOSIXLY.sh -l $logdir -N trac-all-prep_$(subjsess) trac-all -no-isrunning -noappendlog -prep -c $fldr/tracula.rc" | tee $fldr/trac-all_prep.cmd # fsl_sub_NOPOSIXLY.sh gives getopt error ! (!)
      . $fldr/trac-all_prep.cmd
      # note: the eddy correct log file is obviously overwritten on re-run by trac-all -prep, that's what we want (eddy_correct per se would append on .log from broken runs, that's bad)
    done
  done
fi

waitIfBusy

# TRACULA execute -bedp
if [ $TRACULA_STG3 -eq 1 ] ; then
  echo "----- BEGIN TRACULA_STG3 -----"
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$FS_subjdir/$(subjsess)
      echo "TRACULA : subj $subj , sess $sess : executing trac-all -bedp command:"
      #echo "$scriptdir/fsl_sub_NOPOSIXLY.sh -l $logdir -N trac-all-bedp_$(subjsess) trac-all -no-isrunning -noappendlog -bedp -c $fldr/tracula.rc" | tee $fldr/trac-all_bedp.cmd
      echo "trac-all -no-isrunning -noappendlog -bedp -c $fldr/tracula.rc -log $logdir/trac-all-bedp_$(subjsess)_$$ " | tee $fldr/trac-all_bedp.cmd # bedpostx is self-submitting (!)
      . $fldr/trac-all_bedp.cmd
    done
  done
fi

waitIfBusy

# TRACULA execute -path
if [ $TRACULA_STG4 -eq 1 ] ; then
  echo "----- BEGIN TRACULA_STG4 -----"
  for subj in `cat subjects`; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$FS_subjdir/$(subjsess)
      echo "subj $subj , sess $sess : executing trac-all -path command:"
      echo "fsl_sub -l $logdir -N trac-all-paths_$(subjsess) trac-all -no-isrunning -noappendlog -path -c $fldr/tracula.rc" | tee $fldr/trac-all_path.cmd
      #echo "$scriptdir/fsl_sub_NOPOSIXLY.sh -l $logdir -N trac-all-paths_$(subjsess) trac-all -no-isrunning -noappendlog -path -c $fldr/tracula.rc" | tee $fldr/trac-all_path.cmd # fsl_sub_NOPOSIXLY.sh perhaps also unsafe here ? (?)
      . $fldr/trac-all_path.cmd
    done
  done
fi

#########################
# ----- END TRACULA -----
#########################


waitIfBusy


############################
# ----- BEGIN BOLD -----
############################

# BOLD unwarp and motion-align BOLDs - prepare FEAT config-file
if [ $BOLD_STG1 -eq 1 ] ; then
  echo "----- BEGIN BOLD_STG1 -----"
  n=0 ; _npts=0 ; npts=0 # variables for counting and comparing number of volumes in the 4Ds
  
  # set prefix for feat-dir name
  if [ "x${BOLD_FEATDIR_PREFIX}" = "x" ] ; then BOLD_FEATDIR_PREFIX="" ; fi
          
  # carry out substitutions
  if [ x"${BOLD_SMOOTHING_KRNLS}" = "x" ] ; then BOLD_SMOOTHING_KRNLS=0 ; fi
  if [ x"${BOLD_HPF_CUTOFFS}" = "x" ] ; then BOLD_HPF_CUTOFFS="Inf" ; fi
  
  for subj in `cat subjects` ; do
    if [ -z $pttrn_bolds ] ; then echo "BOLD : ERROR : no search pattern for BOLD filenames given - breaking loop..." ; break ; fi
    
    for sess in `cat ${subj}/sessions_func` ; do
      
      # check if we have acquisition parameters
      defineBOLDparams $subjdir/config_acqparams_bold $subj $sess
      
      # define folder
      fldr=$subjdir/$subj/$sess/bold
      
      # create directory
      mkdir -p $fldr
                  
      # link bold file
      bold_bn=`basename $(ls $srcdir/$subj/$sess/$pttrn_bolds | tail -n 1)`
      bold_ext=`echo ${bold_bn#*.}`
      bold_lnk=bold.${bold_ext}
      if [ -L $fldr/bold.nii -o -L $fldr/bold.nii.gz ] ; then rm -f $fldr/bold.nii $fldr/bold.nii.gz ; fi # delete link if already present
      echo "BOLD : subj $subj , sess $sess : creating link '$bold_lnk' to '$bold_bn'"
      ln -sf $(path_abs2rel $fldr/ $srcdir/$subj/$sess/)/$bold_bn $fldr/$bold_lnk # path_abs2rel: mind trailing "/"
      
      # number of volumes in 4D
      echo -n "BOLD : subj $subj , sess $sess : counting number of volumes in '$fldr/$bold_lnk'..."
      npts=`countVols $fldr/$bold_lnk`
      echo " ${npts}."
      if [ $n -gt 0 ] ; then
        if [ ! $npts -eq $_npts ] ; then
          "BOLD : subj $subj , sess $sess : WARNING : Number of volumes does not match with previous image file in the loop!" 
        fi
      fi
      _npts=$npts
      n=$[$n+1]     
      
      # define magnitude and fieldmap
      fmap=$subjdir/$subj/$sess/$(remove_ext $BOLD_FMAP).nii.gz
      fmap_magn=$subjdir/$subj/$sess/$(remove_ext $BOLD_MAGN).nii.gz
      if [ $BOLD_UNWARP -eq 1 ] ; then
        if [ $(_imtest $fmap) -eq 0 ] ; then echo "BOLD : subj $subj , sess $sess : ERROR : Fieldmap image '$fmap' not found ! Exiting..." ; exit 1 ; fi
        if [ $(_imtest $fmap_magn) -eq 0 ] ; then echo "BOLD : subj $subj , sess $sess : ERROR : Fieldmap magnitude image '$fmap_magn' not found ! Exiting..." ; exit 1 ; fi
      fi
      
      # create symlinks to t1-structurals (highres registration reference)
      if [ $BOLD_REGISTER_TO_MNI -eq 1 ] ; then
        echo "BOLD : subj $subj , sess $sess : creating symlinks to t1-structurals (highres registration reference) to please FEAT's naming convention..."
        line=`cat $subjdir/config_func2highres.reg | awk '{print $1}' | grep -nx $(subjsess) | cut -d : -f1`
        sess_t1=`cat $subjdir/config_func2highres.reg | awk '{print $2}' | sed -n ${line}p `
        if [ $sess_t1 = '.' ] ; then sess_t1="" ; fi # single-session design   
        if [ x"$sess_t1" = "x" ] ; then 
          relpath="../../$subj/vbm" # single sess.
        else
          relpath="../../$sess_t1/vbm" # multi sess.
        fi
        t1_brain=$fldr/${subj}${sess_t1}_t1_brain.nii.gz
        t1_struc=$fldr/${subj}${sess_t1}_t1.nii.gz
        feat_t1struc=`ls $subj/$sess_t1/vbm/$BOLD_PTTRN_HIGHRES_STRUC` ; feat_t1brain=`ls $subj/$sess_t1/vbm/$BOLD_PTTRN_HIGHRES_BRAIN`
        echo "BOLD : subj $subj , sess $sess : creating symlink '$(basename $t1_struc)' to '$relpath/$(basename $feat_t1struc)'"
        ln -sf $relpath/$(basename $feat_t1struc) $t1_struc
        echo "BOLD : subj $subj , sess $sess : creating symlink '$(basename $t1_brain)' to '$relpath/$(basename $feat_t1brain)'"
        ln -sf $relpath/$(basename $feat_t1brain) $t1_brain 
      fi
      
      # preparing alternative example func
      if [ $BOLD_BET_EXFUNC -eq 1 ] ; then
        mid_pos=$(echo "scale=0 ; $npts / 2" | bc) # equals: floor($npts / 2)
        echo "BOLD : subj $subj , sess $sess : betting bold at pos. $mid_pos / $npts and using as example_func..."
        altExFunc=$fldr/example_func_bet
        fslroi $fldr/$bold_lnk $altExFunc $mid_pos 1
        fslmaths $altExFunc $altExFunc -odt float
        bet $altExFunc $altExFunc -f 0.3
      fi

      for hpf_cut in $BOLD_HPF_CUTOFFS ; do
        for sm_krnl in $BOLD_SMOOTHING_KRNLS ; do
          for uw_dir in -y +y 00 ; do # 00 -> no unwarping applied
            for stc_val in $BOLD_SLICETIMING_VALUES ; do
            
              # set feat-file's name
              _hpf_cut=$(echo $hpf_cut | sed "s|\.||g") ; _sm_krnl=$(echo $sm_krnl | sed "s|\.||g") # remove '.'
              conffile=$fldr/${BOLD_FEATDIR_PREFIX}_uw${uw_dir}_st${stc_val}_s${_sm_krnl}_hpf${_hpf_cut}.fsf        
                       
              echo "BOLD : subj $subj , sess $sess : FEAT pre-processing - creating config file $conffile"
              cp $tmpltdir/template_preprocBOLD.fsf $conffile
             
              sed -i "s|set fmri(outputdir) \"X\"|set fmri(outputdir) \"${conffile%.fsf}\"|g" $conffile # set output dir
              sed -i "s|set fmri(tr) X|set fmri(tr) $TR_bold|g" $conffile # set TR
              sed -i "s|set fmri(npts) X|set fmri(npts) $npts|g" $conffile # set number of volumes
              sed -i "s|set fmri(dwell) X|set fmri(dwell) $EES_bold|g" $conffile # set Eff. Echo Spacing
              sed -i "s|set fmri(te) X|set fmri(te) $TE_bold|g" $conffile # set TE
              sed -i "s|set fmri(signallossthresh) X|set fmri(signallossthresh) $BOLD_SIGNLOSS_THRES|g" $conffile # set signal loss threshold in percent
              sed -i "s|set feat_files(1) \"X\"|set feat_files(1) \"$fldr/$bold_lnk\"|g" $conffile # set input files
              sed -i "s|set unwarp_files(1) \"X\"|set unwarp_files(1) \"$(remove_ext $fmap)\"|g" $conffile # set fieldmap file (removing extension might be important for finding related files by feat) (?)
              sed -i "s|set unwarp_files_mag(1) \"X\"|set unwarp_files_mag(1) \"$(remove_ext $fmap_magn)\"|g" $conffile # set fieldmap magnitude file (removing extension might be important for finding related files by feat) (?)
              sed -i "s|set fmri(alternative_example_func) \"X\"|set fmri(alternative_example_func) \"\"|g" $conffile # unset alternative example func
              sed -i "s|set fmri(regstandard) .*|set fmri(regstandard) \"$FSL_DIR/data/standard/MNI152_T1_2mm_brain\"|g" $conffile # set MNI template
              sed -i "s|set fmri(analysis) .*|set fmri(analysis) 1|g" $conffile # do only pre-stats        
              sed -i "s|set fmri(mc) .*|set fmri(mc) 1|g" $conffile # enable motion correction
              sed -i "s|set fmri(reginitial_highres_yn) .*|set fmri(reginitial_highres_yn) 0|g" $conffile # unset registration to initial highres
              sed -i "s|fmri(overwrite_yn) .*|fmri(overwrite_yn) 1|g" $conffile # overwrite on re-run
              
              # set slice timing correction method
              sed -i "s|set fmri(st) .*|set fmri(st) $stc_val|g" $conffile              
              if [ $stc_val -eq 3 ] ; then
                $scriptdir/getsliceorderSIEMENS_interleaved.sh $fldr/$bold_lnk $fldr/sliceorder.txt
                sed -i "s|set fmri(st_file) .*|set fmri(st_file) $fldr/sliceorder.txt|g" $conffile
              fi
              
              # set alternative example func
              if [ $BOLD_BET_EXFUNC -eq 1 ] ; then 
                sed -i "s|set fmri(alternative_example_func) .*|set fmri(alternative_example_func) \"$altExFunc\"|g" $conffile 
              fi
              
              # brain extraction
              if [ $BOLD_BET -eq 1 ] ; then
                sed -i "s|set fmri(bet_yn) .*|set fmri(bet_yn) 1|g" $conffile
              else
                sed -i "s|set fmri(bet_yn) .*|set fmri(bet_yn) 0|g" $conffile
              fi              
              
              # smoothing kernel            
              sed -i "s|set fmri(smooth) X|set fmri(smooth) $sm_krnl|g" $conffile
              
              # unwarp
              if [ $uw_dir = 00 ] ; then 
                sed -i "s|set fmri(regunwarp_yn) .*|set fmri(regunwarp_yn) 0|g" $conffile # disable unwarp
              else
                sed -i "s|set fmri(regunwarp_yn) .*|set fmri(regunwarp_yn) 1|g" $conffile # enable unwarp            
              fi
              dir=""
              if [ $uw_dir = -y ] ; then dir="y-" ; fi
              if [ $uw_dir = +y ] ; then dir="y" ; fi
              sed -i "s|set fmri(unwarp_dir) .*|set fmri(unwarp_dir) $dir|g" $conffile
              
              # highpass filter
              if [ $hpf_cut = "Inf" ] ; then
                # unset highpass filter
                sed -i "s|set fmri(temphp_yn) .*|set fmri(temphp_yn) 0|g" $conffile
              else
                # set highpass filter
                sed -i "s|set fmri(temphp_yn) .*|set fmri(temphp_yn) 1|g" $conffile
                sed -i "s|set fmri(paradigm_hp) .*|set fmri(paradigm_hp) $hpf_cut|g" $conffile
              fi
              
              # MNI registration
              if [ $BOLD_REGISTER_TO_MNI -eq 1 ] ; then
                # enable MNI registration
                sed -i "s|set fmri(reghighres_yn) .*|set fmri(reghighres_yn) 1|g" $conffile # set registration to highres
                sed -i "s|set fmri(reghighres_dof) .*|set fmri(reghighres_dof) $BOLD_REGISTER_TO_STRUC_DOF|g" $conffile # set dof for the registration to highres
                sed -i "s|set fmri(regstandard_yn) .*|set fmri(regstandard_yn) 1|g" $conffile # set registration to standard space
                sed -i "s|set fmri(regstandard_nonlinear_yn) .*|set fmri(regstandard_nonlinear_yn) 1|g" $conffile # enable nonlinear registration
                sed -i "s|set fmri(regstandard_nonlinear_warpres) .*|set fmri(regstandard_nonlinear_warpres) 10|g" $conffile # set warp resolution
                #sed -i "s|set highres_files(1) .*|set highres_files(1) \"$t1_brain\"|g" $conffile # set brain-extracted T1
                
                # set t1 highres structural & create sym-links
                echo "# Subject's structural image for analysis 1" >> $conffile
                echo "set highres_files(1) \"$(remove_ext $t1_brain)\"" >> $conffile # removing the file extension is very important, o.w. the non-brain extracted T1 is not found and non-linear registration will become highly inaccurate (feat does not throw an error here!) (!)
              else
                # disable MNI registration
                sed -i "s|set fmri(reghighres_yn) .*|set fmri(reghighres_yn) 0|g" $conffile # unset registration to highres
                sed -i "s|set fmri(regstandard_yn) .*|set fmri(regstandard_yn) 0|g" $conffile # unset registration to standard space
              fi
              
              # progress watcher
              if [ $BOLD_FEAT_NO_BROWSER -eq 1 ] ; then
                sed -i "s|set fmri(featwatcher_yn) .*|set fmri(featwatcher_yn) 0|g" $conffile
              else 
                sed -i "s|set fmri(featwatcher_yn) .*|set fmri(featwatcher_yn) 1|g" $conffile
              fi
              
              echo "---------------------------"
              
            done # end stc_val
          done # end uw_dir          
        done # end sm_krnl
      done # end hpf_cut
      echo ""
    done
  done
fi
  
waitIfBusy

# BOLD execute FEAT
if [ $BOLD_STG2 -eq 1 ] ; then
  echo "----- BEGIN BOLD_STG2 -----"
  
  # set prefix for feat-dir name
  if [ "x${BOLD_FEATDIR_PREFIX}" = "x" ] ; then BOLD_FEATDIR_PREFIX="" ; fi
  
  # carry out substitutions
  if [ x"${BOLD_SMOOTHING_KRNLS}" = "x" ] ; then BOLD_SMOOTHING_KRNLS=0 ; fi
  if [ x"${BOLD_HPF_CUTOFFS}" = "x" ] ; then BOLD_HPF_CUTOFFS="Inf" ; fi
  
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_func` ; do
    
      if [ -z $pttrn_bolds ] ; then echo "BOLD : ERROR : no search pattern for BOLD filenames given - continuing..." ; continue ; fi
      
      fldr=$subjdir/$subj/$sess/bold
      
      # shall we unwarp ?
      if [ $BOLD_UNWARP -eq 1 ] ; then
        uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess`
      else 
        uw_dir=00
      fi
      
      # cleanup previous run, execute FEAT and link to processed file
      # NOTE: feat self-submits to the cluster and should in fact not be used in conjunction with fsl_sub (but it seems to work anyway) (!)
      for hpf_cut in $BOLD_HPF_CUTOFFS ; do
        for sm_krnl in $BOLD_SMOOTHING_KRNLS ; do
          for stc_val in $BOLD_SLICETIMING_VALUES ; do
            # define feat-dir
            _hpf_cut=$(echo $hpf_cut | sed "s|\.||g") ; _sm_krnl=$(echo $sm_krnl | sed "s|\.||g") # remove '.'
            featdir=$fldr/${BOLD_FEATDIR_PREFIX}_uw${uw_dir}_st${stc_val}_s${_sm_krnl}_hpf${_hpf_cut}.feat 
             
            # delete prev. run
            if [ -d $featdir ] ; then
              echo "BOLD : subj $subj , sess $sess : WARNING : removing previous .feat directory ('$featdir') in 5 seconds - press CTRL-C to abort." ; sleep 5
              rm -rf $featdir
            fi
            
            # execute...
            conffile=${featdir%.feat}.fsf
            echo "BOLD : subj $subj , sess $sess : running \"feat $conffile\"..."
            #fsl_sub -l $logdir -N bold_feat_$(subjsess) feat $conffile
            feat $conffile
            
            sleepfor $DELAYINSECS
            
            # link...
            echo "BOLD : subj $subj , sess $sess : creating symlink to unwarped 4D BOLD."
            #lname=$(echo "$featdir" | sed "s|"uw[-+0][y0]"|"uw"|g") # remove unwarp direction from link's name
            lname=$(echo "$featdir" | sed "s|"uw[-+]y"|"uw"|g") # remove unwarp direction from link's name
            ln -sfv ./$(basename $featdir)/filtered_func_data.nii.gz ${lname%.feat}_filtered_func_data.nii.gz
            # create a link to report_log.html in logdir.
            ln -sfv $featdir/report_log.html $logdir/bold_reportlog_$(basename $featdir)_$(subjsess).html
   
          done # end stc_val
        done # end sm_krnl        
      done # end hpf_cut
      
    done # end sess
  done # end subj
  
fi

waitIfBusy

# BOLD denoise
if [ $BOLD_STG3 -eq 1 ] ; then
  echo "----- BEGIN BOLD_STG3 -----"  
    
  # substitutions
  if [ x"$BOLD_DENOISE_SMOOTHING_KRNLS" = "x" ] ; then BOLD_DENOISE_SMOOTHING_KRNLS=0; fi
  if [ x"$BOLD_DENOISE_USE_MOVPARS_NAT" = "x" ] ; then BOLD_DENOISE_USE_MOVPARS_NAT=0 ; fi
 
  # mind the \' \' -> necessary, o.w. string gets split up when a) being inside double-quotes 
  # (e.g., echo redirection to a cmd-file for fsl_sub) and b) being passed as an argument to a function (!)
  BOLD_DENOISE_MASKS_NAT=\'$BOLD_DENOISE_MASKS_NAT\'
  BOLD_DENOISE_SMOOTHING_KRNLS=\'$BOLD_DENOISE_SMOOTHING_KRNLS\'
  BOLD_DENOISE_USE_MOVPARS_NAT=\'$BOLD_DENOISE_USE_MOVPARS_NAT\'   
  
  for subj in `cat subjects` ; do
    
    if [ x"$BOLD_DENOISE_MASKS_NAT" = "x" ] ; then echo "BOLD : subj $subj : ERROR : no masks for signal extraction specified -> no denoising possible -> breaking loop..." ; break ; fi

    for sess in `cat ${subj}/sessions_func` ; do
        
      # check if we have acquisition parameters
      defineBOLDparams $subjdir/config_acqparams_bold $subj $sess
      
      fldr=$subjdir/$subj/$sess/bold
      sess_t1=`getT1Sess4FuncReg $subjdir/config_func2highres.reg $subj $sess`
      
      if [ ! -f $FS_subjdir/${subj}${sess_t1}/mri/aparc+aseg.mgz ] ; then echo "BOLD : subj $subj , sess $sess : ERROR : aparc+aseg.mgz not found in '${FS_subjdir}/${subj}${sess_t1}/mri' ! You must run recon-all first. Continuing ..." ; continue ; fi

      if [ $BOLD_UNWARP -eq 1 ] ; then uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess` ; else uw_dir=00 ; fi
      
      for hpf_cut in $BOLD_HPF_CUTOFFS ; do # it may be better to do temporal filtering first, then denoise (not the other way around) (?)
        for sm_krnl in 0 ; do # denoising only with non-smoothed data -> smoothing carried out at the end.
          for stc_val in $BOLD_SLICETIMING_VALUES ; do
            
            # define feat-dir
            _hpf_cut=$(echo $hpf_cut | sed "s|\.||g") ; _sm_krnl=$(echo $sm_krnl | sed "s|\.||g") # remove '.'
            featdir=$fldr/${BOLD_FEATDIR_PREFIX}_uw${uw_dir}_st${stc_val}_s${_sm_krnl}_hpf${_hpf_cut}.feat
            
            if [ ! -d $featdir ] ; then echo "BOLD : subj $subj , sess $sess : feat-directory '$featdir' not found ! -> breaking loop..." ; break ; else echo "BOLD : subj $subj , sess $sess : feat-directory: '$(basename $featdir)'." ; fi
            
            # cleanup prev. bbreg. runs
            rm -rf $featdir/noise/tmp.bbregister.*
            
            # display info
            echo "BOLD : subj $subj , sess $sess : creating masks in functional native space using FS's bbreg..."
            echo "BOLD : subj $subj , sess $sess : denoising (tag: ${dntag_boldnat})..."
            echo "BOLD : subj $subj , sess $sess : smoothing (FWHM: ${BOLD_DENOISE_SMOOTHING_KRNLS})..."
            
            # creating command for fsl_sub
            mkdir -p $featdir/noise
            ln -sf ../filtered_func_data.nii.gz $featdir/noise/filtered_func_data.nii.gz
            echo "$scriptdir/fs_create_masks.sh $SUBJECTS_DIR ${subj}${sess_t1} $featdir/example_func $featdir/noise $subj $sess ; \
            $scriptdir/denoise4D.sh $featdir/noise/filtered_func_data "$BOLD_DENOISE_MASKS_NAT" $featdir/mc/prefiltered_func_data_mcf.par "$BOLD_DENOISE_USE_MOVPARS_NAT" $hpf_cut $TR_bold $featdir/noise/filtered_func_data_dn${dntag_boldnat} $subj $sess ; \
            $scriptdir/feat_smooth.sh $featdir/noise/filtered_func_data_dn${dntag_boldnat} $featdir/filtered_func_data_dn${dntag_boldnat} "$BOLD_DENOISE_SMOOTHING_KRNLS" none $TR_bold $subj $sess" > $featdir/bold_denoise.cmd
            
            # executing...
            $scriptdir/fsl_sub_NOPOSIXLY.sh -l $logdir -N bold_denoise_$(subjsess) -t $featdir/bold_denoise.cmd
            
            sleepfor $DELAYINSECS
            
          done # end stc_val
        done # end sm_krnl
      done # end hpf_cut
        
    done
  done  
fi

waitIfBusy

# BOLD write out mni registered files
if [ $BOLD_STG4 -eq 1 ] ; then
  echo "----- BEGIN BOLD_STG4 -----"

  # set prefix for feat-dir name
  if [ "x${BOLD_FEATDIR_PREFIX}" = "x" ] ; then BOLD_FEATDIR_PREFIX="" ; fi
  
  # set interpolation method
  if [ "x${BOLD_MNI_RESAMPLE_INTERP}" != "x" ] ; then interp="${BOLD_MNI_RESAMPLE_INTERP}" ; else interp="trilinear" ; fi
  
  # carry out substitutions
  if [ x"${BOLD_SMOOTHING_KRNLS}" = "x" ] ; then BOLD_SMOOTHING_KRNLS=0 ; fi
  if [ x"${BOLD_HPF_CUTOFFS}" = "x" ] ; then BOLD_HPF_CUTOFFS="Inf" ; fi
  
  if [ $BOLD_USE_FS_LONGT_TEMPLATE -ge 1 ] ; then
    for subj in `cat subjects` ; do

      if [ ! -f $FS_subjdir/${subj}/mri/aparc+aseg.mgz ] ; then echo "BOLD : subj $subj : ERROR : aparc+aseg.mgz not found ! You must run recon-all (longitudinal) first. Continuing ..." ; continue ; fi

      for sess in `cat ${subj}/sessions_func` ; do
      
        echo "BOLD : subj $subj , sess $sess : performing boundary-based registration of func -> FS's longitudinal anatomical template..."
        
        # single session design ?
        if [ $sess = "." -a $BOLD_USE_FS_LONGT_TEMPLATE -eq 1 ] ; then echo "BOLD : subj $subj , sess $sess : single-session design -> skipping..." ; continue ; fi
        
        # retrieving corresponding session with structural scan
        sess_t1=`getT1Sess4FuncReg $subjdir/config_func2highres.reg $subj $sess`              
        if [ ! -f $FS_subjdir/${subj}${sess_t1}/mri/aparc+aseg.mgz ] ; then echo "BOLD : subj $subj , sess $sess : ERROR : aparc+aseg.mgz not found ! You must run recon-all first. Continuing ..." ; continue ; fi
         
        # did we unwarp ?
        if [ $BOLD_UNWARP -eq 1 ] ; then uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess` ; else uw_dir=00 ; fi
              
        # FS's bbreg based registration, if applicable
        for hpf_cut in $BOLD_HPF_CUTOFFS ; do
          for sm_krnl in $BOLD_SMOOTHING_KRNLS ; do
            for stc_val in $BOLD_SLICETIMING_VALUES ; do
              
              # define feat-dir.
              _hpf_cut=$(echo $hpf_cut | sed "s|\.||g") ; _sm_krnl=$(echo $sm_krnl | sed "s|\.||g") # remove '.'
              featdir=$subjdir/$subj/$sess/bold/${BOLD_FEATDIR_PREFIX}_uw${uw_dir}_st${stc_val}_s${_sm_krnl}_hpf${_hpf_cut}.feat
              
              # check feat-dir.
              if [ ! -d $featdir ] ;  then echo "BOLD : subj $subj , sess $sess : WARNING : feat-directory '$featdir' does not exist - continuing loop..." ; continue ; fi              
            
              echo "BOLD : subj $subj , sess $sess : copying registrations from '$FS_subjdir/$subj/fsl_reg/' to '$featdir/reg_longt/'..."
              mkdir -p $featdir/reg_longt
              cp $FS_subjdir/$subj/fsl_reg/* $featdir/reg_longt/

              # cleanup prev. bbreg. runs
              rm -rf $featdir/reg_longt/tmp.bbregister.*
              
              # needful vars
              affine=$featdir/reg_longt/example_func2longt_brain.mat
              cmd_file=$featdir/bold_func2longt.cmd
              log_file=bold_func2longt_$(subjsess)
              sess_t1=`getT1Sess4FuncReg $subjdir/config_func2highres.reg $subj $sess`              
              
              if [ $BOLD_USE_FS_LONGT_TEMPLATE -eq 1 ] ; then
                echo "BOLD : subj $subj , sess $sess : converting '${subj}${sess_t1}_to_${subj}.lta' -> '${subj}${sess_t1}_to_${subj}.mat' (FSL-style)..."
                echo "BOLD : subj $subj , sess $sess : using FS's bbreg to register 'example_func.nii.gz' -> FS's structural (ID '${subj}${sess_t1}')..."
                echo "BOLD : subj $subj , sess $sess : writing example_func -> FS's structural..."
                echo "BOLD : subj $subj , sess $sess : concatenating matrices..."
                
                echo "tkregister2 --noedit --mov $FS_subjdir/${subj}${sess_t1}/mri/norm.mgz --targ $FS_subjdir/$subj/mri/norm_template.mgz --lta $FS_subjdir/$subj/mri/transforms/${subj}${sess_t1}_to_${subj}.lta --fslregout $featdir/reg_longt/${subj}${sess_t1}_to_${subj}.mat --reg $tmpdir/deleteme.reg.dat ;\
                bbregister --s ${subj}${sess_t1} --mov $featdir/example_func.nii.gz --init-fsl --reg $featdir/reg_longt/example_func2highres_bbr.dat --t2 --fslmat $featdir/reg_longt/example_func2highres_bbr.mat ;\
                mri_convert $FS_subjdir/${subj}${sess_t1}/mri/brain.mgz $featdir/reg_longt/brain.nii.gz ;\
                flirt -in $featdir/example_func.nii.gz -ref $featdir/reg_longt/brain.nii.gz -init $featdir/reg_longt/example_func2highres_bbr.mat -applyxfm -out $featdir/reg_longt/example_func2highres_bbr ;\
                fslreorient2std $featdir/reg_longt/brain $featdir/reg_longt/highres ;\
                fslreorient2std $featdir/reg_longt/example_func2highres_bbr $featdir/reg_longt/example_func2highres_bbr ;\
                imrm $featdir/reg_longt/brain ;\
                convert_xfm -omat $affine -concat $featdir/reg_longt/${subj}${sess_t1}_to_${subj}.mat $featdir/reg_longt/example_func2highres_bbr.mat" > $cmd_file                
                
              elif [ $BOLD_USE_FS_LONGT_TEMPLATE -eq 2 ] ; then
                echo "BOLD : subj $subj , sess $sess : using FS's bbreg to register 'example_func.nii.gz' -> FS's structural (ID '${subj}')..."
                echo "BOLD : subj $subj , sess $sess : writing example_func -> FS's structural..."
                              
                echo "bbregister --s ${subj} --mov $featdir/example_func.nii.gz --init-fsl --reg $featdir/reg_longt/example_func2highres_bbr.dat --t2 --fslmat $featdir/reg_longt/example_func2highres_bbr.mat ;\
                mri_convert $FS_subjdir/${subj}/mri/brain.mgz $featdir/reg_longt/brain.nii.gz ;\
                flirt -in $featdir/example_func.nii.gz -ref $featdir/reg_longt/brain.nii.gz -init $featdir/reg_longt/example_func2highres_bbr.mat -applyxfm -out $featdir/reg_longt/example_func2highres_bbr ;\
                fslreorient2std $featdir/reg_longt/brain $featdir/reg_longt/highres ;\
                fslreorient2std $featdir/reg_longt/example_func2highres_bbr $featdir/reg_longt/example_func2highres_bbr ;\
                imrm $featdir/reg_longt/brain ;\
                cp $featdir/reg_longt/example_func2highres_bbr.mat $affine" > $cmd_file              
              fi
              
              $scriptdir/fsl_sub_NOPOSIXLY.sh -l $logdir -N $log_file -t $cmd_file
              
            done # end stc_val
          done # end sm_krnl
        done # end hpf_cut

      done # end sess
    done # end subj
  fi # end BOLD_USE_FS_LONGT_TEMPLATE
  
  waitIfBusy
  
  for subj in `cat subjects` ; do
    
    if [ -z "$BOLD_MNI_RESAMPLE_RESOLUTIONS" -o "$BOLD_MNI_RESAMPLE_RESOLUTIONS" = "0" ] ; then echo "BOLD : ERROR : no resampling-resolutions for the MNI-registered BOLDs defined - breaking loop..." ; break ; fi

    for sess in `cat ${subj}/sessions_func` ; do
    
      # did we unwarp ?
      if [ $BOLD_UNWARP -eq 1 ] ; then uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess` ; else uw_dir=00 ; fi
      
      # write out MNI-registered volumes
      for hpf_cut in $BOLD_HPF_CUTOFFS ; do
        for sm_krnl in $BOLD_SMOOTHING_KRNLS ; do
          for stc_val in $BOLD_SLICETIMING_VALUES ; do
            
            # define feat-dir.
            _hpf_cut=$(echo $hpf_cut | sed "s|\.||g") ; _sm_krnl=$(echo $sm_krnl | sed "s|\.||g") # remove '.'
            featdir=$subjdir/$subj/$sess/bold/${BOLD_FEATDIR_PREFIX}_uw${uw_dir}_st${stc_val}_s${_sm_krnl}_hpf${_hpf_cut}.feat
            
            # check feat-dir.
            if [ ! -d $featdir ] ;  then echo "BOLD : subj $subj , sess $sess : WARNING : feat-directory '$featdir' does not exist - continuing loop..." ; continue ; fi
            
            # create $featdir/reg_standard
            echo "BOLD : subj $subj , sess $sess : featregapply -> '$featdir/reg_standard'..."
            featregapply $featdir
            
            if [ $BOLD_USE_FS_LONGT_TEMPLATE -ge 1 ] ; then            
              T1_file=$featdir/reg_longt/longt_brain # see RECON_STG5
              MNI_file=$featdir/reg_longt/longt_standard
              affine=$featdir/reg_longt/example_func2longt_brain.mat
              warp=$featdir/reg_longt/longt_head2longt_standard_warp
              ltag="_longt"   
            else            
              T1_file=$featdir/reg/highres
              MNI_file=$featdir/reg/standard
              affine=$featdir/reg/example_func2highres.mat
              warp=$featdir/reg/highres2standard_warp
              ltag=""            
            fi

            # execute...
            for data_file in $BOLD_MNI_RESAMPLE_FUNCDATAS ; do
              
              if [ $(_imtest $featdir/$data_file) != 1 ] ; then
                  echo "BOLD : subj $subj , sess $sess : WARNING : volume '$featdir/$data_file' not found -> this file cannot be written out in MNI-space. Continuing loop..."
                  continue
              fi
              in_file=$featdir/$(remove_ext $data_file)
              
              for mni_res in $BOLD_MNI_RESAMPLE_RESOLUTIONS ; do

                _mni_res=$(echo $mni_res | sed "s|\.||g") # remove '.'
                                  
                out_file=$featdir/reg_standard/$(basename $in_file)${ltag}_mni${_mni_res}
                resampled_MNI_file=$featdir/reg_standard/$(basename $MNI_file)_${_mni_res}.nii.gz
                MNI_T1_file=$featdir/reg_standard/$(basename $T1_file)_${_mni_res}.nii.gz
                cmd_file=$featdir/bold_writeMNI_$(basename $in_file)${ltag}_res${_mni_res}.cmd
                log_file=bold_writeMNI_$(basename $in_file)${ltag}_res${_mni_res}_$(subjsess)
                
                # resampling standard
                if [ ! -f $resampled_MNI_file ] ; then
                  echo "BOLD : subj $subj , sess $sess : resampling standard '$(basename $MNI_file)' to resolution $mni_res..."
                  flirt -ref $MNI_file -in $MNI_file -out $resampled_MNI_file -applyisoxfm $mni_res
                fi
                
                # writing registration T1->standard
                if [ ! -f $MNI_T1_file ] ; then
                  echo "BOLD : subj $subj , sess $sess : writing registration highres '$(basename $T1_file)' -> '$(basename $MNI_file)'..."
                  applywarp --ref=$resampled_MNI_file --in=${T1_file} --out=$MNI_T1_file --warp=${warp}  --interp=sinc
                fi
                
                echo "BOLD : subj $subj , sess $sess : writing MNI-registered 4D BOLD '$(basename $out_file)' to '$(dirname $out_file)/'."
                                
                # create command for fsl_sub
                ## mask result to remove spline / sinc related oscillations outside the brain...
                if [ $interp = "spline" -o $interp = "sinc" ] ; then  
                  cmd_mask="$scriptdir/feat_mask.sh ${out_file} ${out_file}_mask $subj $sess; \
                  fslmaths $out_file -mas ${out_file}_mask $out_file;\
                  median_intensity=\`cat ${out_file}_mask_vals |  awk '{print \$4}'\` ;\
                  $scriptdir/feat_scale.sh ${out_file} ${out_file} global 10000 \$median_intensity $subj $sess"
                else
                  cmd_mask=""
                fi
                
                echo "$scriptdir/feat_writeMNI.sh $in_file $MNI_file $out_file $mni_res $affine $warp $interp $subj $sess ;\
                $cmd_mask" > $cmd_file
                
                fsl_sub -l $logdir -N $log_file -t $cmd_file 
                
                # link...
                echo "BOLD : subj $subj , sess $sess : creating symlink to MNI-registered 4D BOLD."
                #lname=$(echo "$featdir" | sed "s|"uw[-+0][y0]"|"uw"|g") # remove unwarp direction from link's name
                lname=$(echo "$featdir" | sed "s|"uw[-+]y"|"uw"|g") # remove unwarp direction from link's name
                ln -sfv ./$(basename $featdir)/reg_standard/$(basename $out_file).nii.gz ${lname%.feat}_$(basename $out_file).nii.gz

              done # end mni_res            
            done # end data_file
          done # end stc_val
        done # end sm_krnl
      done # end hpf_cut
    
    done # end sess
  done # end subj
fi


waitIfBusy


if [ $BOLD_STG5 -eq 1 ]; then
  echo "----- BEGIN BOLD_STG5 -----"
   
  # carry out substitutions
  if [ x"$BOLD_DENOISE_USE_MOVPARS_MNI" = "x" ] ; then BOLD_DENOISE_USE_MOVPARS_NAT=0 ; fi
  if [ x"${BOLD_SMOOTHING_KRNLS}" = "x" ] ; then BOLD_SMOOTHING_KRNLS=0 ; fi
  if [ x"${BOLD_HPF_CUTOFFS}" = "x" ] ; then BOLD_HPF_CUTOFFS="Inf" ; fi
  # mind the \' \' -> necessary, o.w. string gets split up when a) being inside double-quotes 
  # (e.g., echo redirection to a cmd-file for fsl_sub) and b) being passed as an argument to a function (!)
  BOLD_DENOISE_MASKS_MNI=\'$BOLD_DENOISE_MASKS_MNI\'
  BOLD_DENOISE_USE_MOVPARS_MNI=\'$BOLD_DENOISE_USE_MOVPARS_MNI\'
  
  
  for subj in `cat subjects` ; do
  
    if [ x"$BOLD_DENOISE_MASKS_MNI" = "x" ] ; then echo "BOLD : subj $subj : ERROR : no masks for nuisance extraction in MNI space specified -> no denoising possible -> breaking loop..." ; break ; fi

    for sess in `cat ${subj}/sessions_func` ; do
      
      # check if we have acquisition parameters
      defineBOLDparams $subjdir/config_acqparams_bold $subj $sess 
    
      for hpf_cut in $BOLD_HPF_CUTOFFS ; do
        for sm_krnl in $BOLD_SMOOTHING_KRNLS ; do
          for stc_val in $BOLD_SLICETIMING_VALUES ; do

            if [ $BOLD_UNWARP -eq 1 ] ; then uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess` ; else uw_dir=00 ; fi
            
            if [ $BOLD_USE_FS_LONGT_TEMPLATE -ge 1 ] ; then
              ltag="_longt"   
            else
              ltag=""            
            fi
     
            # define feat-dir.
            _hpf_cut=$(echo $hpf_cut | sed "s|\.||g") ; _sm_krnl=$(echo $sm_krnl | sed "s|\.||g") # remove '.'
            featdir=$subjdir/$subj/$sess/bold/${BOLD_FEATDIR_PREFIX}_uw${uw_dir}_st${stc_val}_s${_sm_krnl}_hpf${_hpf_cut}.feat
            
            # check feat-dir.
            if [ ! -d $featdir ] ;  then echo "BOLD : subj $subj , sess $sess : WARNING : feat-directory '$featdir' does not exist - continuing loop..." ; continue ; fi
            
            # create $featdir/noise
            noisedir=$featdir/reg_standard/noise
            mkdir -p $noisedir
            
            # estimate nuisance regressors on resolution 2
            mni_res=2       
            data_file=filtered_func_data${ltag}_mni${mni_res}.nii.gz
            cmd_file=${featdir}/bold_denoise-prep_$(remove_ext $data_file).cmd
            if [ $(_imtest $featdir/reg_standard/$data_file) != 1 ] ; then
                echo "BOLD : subj $subj , sess $sess : WARNING : estimating nuisance regressors : volume '$featdir/reg_standard/$data_file' not found. Continuing loop..."
                continue
            fi
            echo "BOLD : subj $subj , sess $sess : estimating nuisance regressors from '$data_file'..."
            # copy masks (1000 connectomes)
            echo "BOLD : subj $subj , sess $sess : creating masks..."
            echo "BOLD : subj $subj , sess $sess : masking 1000 connectome WM/CSF masks with whole-brain mask..."
            echo "BOLD : subj $subj , sess $sess : estimating nuisance regressors..."
            ln -sf ../$data_file $noisedir/$data_file
            echo "fslmaths $noisedir/$data_file -Tmin $noisedir/min ; \
            bet $noisedir/min $noisedir/min -f 0.3 ; \
            fslmaths $noisedir/min -thr 0 -bin -ero $noisedir/MNI_WB.nii.gz ; \
            fslmaths $FSL_DIR/data/standard/avg152T1_csf_bin.nii.gz   -mas $noisedir/MNI_WB.nii.gz $noisedir/MNI_CSF.nii.gz ; \
            fslmaths $FSL_DIR/data/standard/avg152T1_white_bin.nii.gz -mas $noisedir/MNI_WB.nii.gz $noisedir/MNI_WM.nii.gz ; \
            imrm $noisedir/min ; \
            $scriptdir/denoise4D.sh -m $noisedir/${data_file} "$BOLD_DENOISE_MASKS_MNI" $featdir/mc/prefiltered_func_data_mcf.par "$BOLD_DENOISE_USE_MOVPARS_MNI" $hpf_cut $TR_bold $noisedir/$(remove_ext $data_file)_dn${dntag_boldmni} $subj $sess" > $cmd_file
            # execute
            jid=`fsl_sub -l $logdir -N bold_denoise-prep_mni${mni_res}_$(subjsess) -t $cmd_file`

            for mni_res in $BOLD_MNI_RESAMPLE_RESOLUTIONS ; do
              
              data_file=filtered_func_data${ltag}_mni${mni_res}.nii.gz
              data_ref=filtered_func_data${ltag}_mni2.nii.gz # the file we derived the nuisance regressors from
              cmd_file=${featdir}/bold_denoise_$(remove_ext $data_file).cmd
              
              echo "BOLD : subj $subj , sess $sess : denoising '$data_file' in MNI space using 1000 connectome masks and nusiance matrix '$(remove_ext $data_ref)_dn${dntag_boldmni}_nuisance_proc.mat' ..."
                          
              # creating command for fsl_sub
              ln -sf ../$data_file $noisedir/$data_file
              echo "$scriptdir/rem_noise.sh $noisedir/${data_file} $noisedir/$(remove_ext $data_ref)_dn${dntag_boldmni}_nuisance_proc.mat $noisedir/$(remove_ext $data_file)_dn${dntag_boldmni} $subj $sess ; \
              immv $noisedir/$(remove_ext $data_file)_dn${dntag_boldmni} $featdir/reg_standard/" > $cmd_file
           
              # executing...
              ln -sf ../$data_file $noisedir/$data_file
              fsl_sub -j $jid -l $logdir -N bold_denoise_mni${mni_res}_$(subjsess) -t $cmd_file
              
              # creating link...
              echo "BOLD : subj $subj , sess $sess : creating symlink to MNI-denoised 4D BOLD."
              #lname=$(echo "$featdir" | sed "s|"uw[-+0][y0]"|"uw"|g") # remove unwarp direction from link's name
              lname=$(echo "$featdir" | sed "s|"uw[-+]y"|"uw"|g") # remove unwarp direction from link's name
              ln -sfv ./$(basename $featdir)/reg_standard/$(remove_ext $data_file)_dn${dntag_boldmni}.nii.gz ${lname%.feat}_$(remove_ext $data_file)_dn${dntag_boldmni}.nii.gz
                
            done # end mni_res
    
          done # end stc_val
        done # end sm_krnl
      done # end hpf_cut

    done # end sess
  done # end subj    
fi

######################
# ----- END BOLD -----
######################


waitIfBusy


########################
# ----- BEGIN ALFF -----
########################

if [ $ALFF_STG1 -eq 1 ] ; then
  echo "----- BEGIN ALFF_STG1 -----"

  sm=$ALFF_SMOOTHING_KERNEL
  if [ x"${ALFF_HPF_CUTOFF}" = "x" -o x"${ALFF_HPF_CUTOFF}" = "xnone" ] ; then ALFF_HPF_CUTOFF="Inf" ; fi
  ALFF_DENOISE_MASKS_NAT=\'$ALFF_DENOISE_MASKS_NAT\'
  ALFF_DENOISE_USE_MOVPARS_NAT=\'$ALFF_DENOISE_USE_MOVPARS_NAT\'
  jid="1"

  # prepare
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_func` ; do
      
      # check if we have acquisition parameters
      defineBOLDparams $subjdir/config_acqparams_bold $subj $sess
      
      # declare vars
      out=$fldr/$(subjsess)
      uwdir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess`
      featdir=$subjdir/$subj/$sess/$(echo "$ALFF_FEATDIR" | sed "s|??|$uwdir|g")
      if [ $ALFF_FSLV5 -eq 1 ] ; then
        if [ -f $featdir/reg/unwarp/EF_UD_shift.nii.gz ] ; then
          alff_uw_shiftmap=$featdir/reg/unwarp/EF_UD_shift.nii.gz # patched version of fsl5
        else
          alff_uw_shiftmap=$featdir/reg/unwarp/FM_UD_fmap2epi_shift.nii.gz # this misnaming of the shiftmap is a known bug of unpatched fsl5
        fi        
      else
        alff_uw_shiftmap=$featdir/unwarp/EF_UD_shift.nii.gz
      fi
      
      # apply shiftmap ?
      if [ $ALFF_APPLY_UNWARP -eq 0 ] ; then uwdir=00 ; alff_uw_shiftmap="none" ; fi
      
      # check
      if [ ! -d $featdir ] ; then echo "ALFF : subj $subj , sess $sess : ERROR: directory '$featdir' not found - exiting..." ; exit 1 ; fi
      if [ ! -d $featdir/mc ] ; then echo "ALFF : subj $subj , sess $sess : ERROR: '$featdir/mc' not found - exiting..." ; exit 1 ; fi
      if [ ! -f $alff_uw_shiftmap -a "$uwdir" != "00" ] ; then echo "ALFF : subj $subj , sess $sess : ERROR: '$alff_uw_shiftmap' not found - exiting..." ; exit 1 ; fi
      
      # mkdir
      fldr=$subjdir/$subj/$sess/alff
      mkdir -p $fldr
      
      # define cmd
      cmd=$fldr/alff_prepare.cmd ; rm -f $cmd
            
      # link bold file
      bold_bn=`basename $(ls $srcdir/$subj/$sess/$pttrn_bolds | tail -n 1)`
      bold_ext=`echo ${bold_bn#*.}`
      bold_lnk=bold.${bold_ext}
      if [ -L $fldr/bold.nii -o -L $fldr/bold.nii.gz ] ; then rm -f $fldr/bold.nii $fldr/bold.nii.gz ; fi # delete link if already present
      echo "ALFF : subj $subj , sess $sess : creating link '$bold_lnk' to '$bold_bn'"
      ln -sf $(path_abs2rel $fldr/ $srcdir/$subj/$sess/)/$bold_bn $fldr/$bold_lnk # path_abs2rel: mind trailing "/"
      #cp -Pv $(dirname $featdir)/bold.nii $fldr/
      
      # apply motion correction and unwarping
      if [ $uwdir = -y ] ; then  _uwdir=y- ; fi
      if [ $uwdir = +y ] ; then  _uwdir=y ; fi
      if [ $uwdir = 00 ] ; then  _uwdir=00 ; fi
      
      if [ "$ALFF_DENOISE_MASKS_NAT" != "'none'" ] ; then
        echo "ALFF : subj $subj , sess $sess : copying denoise_masks from './bold/$(basename $featdir)/noise'..."
        mkdir -p $fldr/noise/
        cp -v $featdir/noise/EF_*.nii.gz $fldr/noise/
        #echo "ALFF : subj $subj , sess $sess : creating denoise_masks..."
        #sess_t1=`getT1Sess4FuncReg $subjdir/config_func2highres.reg $subj $sess`
        #echo "    $scriptdir/fs_create_masks.sh $SUBJECTS_DIR ${subj}${sess_t1} $fldr/example_func $fldr/noise $subj $sess" >> $cmd
        #tail $cmd
      fi
      
      #create cmd      
      echo "ALFF : subj $subj , sess $sess : applying motion-correction and unwarp shiftmap in ./bold/$(basename $featdir)'..."
      echo "ALFF : subj $subj , sess $sess : despiking (using AFNI's 3dDespike)..."
      
      imrm $fldr/_tmp $fldr/__tmp $fldr/_m $fldr/_dm 
      
      if [ "$ALFF_HPF_CUTOFF" = "Inf" ] ; then

        echo "ALFF : subj $subj , sess $sess : detrending (using AFNI tools)..."

        echo "$scriptdir/apply_mc+unwarp.sh $fldr/bold.nii $fldr/filtered_func_data.nii.gz $featdir/mc/prefiltered_func_data_mcf.mat $alff_uw_shiftmap $_uwdir trilinear ;\
        3dDespike -prefix $fldr/_tmp.nii.gz $fldr/filtered_func_data.nii.gz ; \
        3dTcat -rlt+ -prefix $fldr/__tmp.nii.gz $fldr/_tmp.nii.gz ; \
        rm -f $fldr/filtered_func_data.nii.gz $fldr/_tmp.nii.gz ; \
        mv $fldr/__tmp.nii.gz $fldr/filtered_func_data.nii.gz" > $cmd
      
      else
      
        echo "ALFF : subj $subj , sess $sess : detrending (using FSL's fslmaths -bptf, cutoff: $ALFF_HPF_CUTOFF Hz)..."
      
        echo "$scriptdir/apply_mc+unwarp.sh $fldr/bold.nii $fldr/filtered_func_data.nii.gz $featdir/mc/prefiltered_func_data_mcf.mat $alff_uw_shiftmap $_uwdir trilinear ;\
        3dDespike -prefix $fldr/_tmp.nii.gz $fldr/filtered_func_data.nii.gz ; \
        $scriptdir/feat_hpf.sh $fldr/_tmp.nii.gz $fldr/__tmp.nii.gz $ALFF_HPF_CUTOFF $TR_bold $subj $sess ; \
        rm -f $fldr/filtered_func_data.nii.gz $fldr/_tmp.nii.gz ; \
        mv $fldr/__tmp.nii.gz $fldr/filtered_func_data.nii.gz" > $cmd
      
      fi
      
      ## with afni despike/detrend        
      #3dTstat -mean -prefix $fldr/_m.nii.gz $fldr/_tmp.nii.gz ; 3dDetrend -polort 2 -prefix $fldr/_dm.nii.gz $fldr/_tmp.nii.gz ; 3dcalc -a $fldr/_m.nii.gz  -b $fldr/_dm.nii.gz  -expr 'a+b' -prefix $fldr/__tmp.nii.gz ; rm -f $fldr/_m.nii.gz $fldr/_dm.nii.gz ;
          
      ## with slicetiming correction      
      #echo "$scriptdir/apply_mc+unwarp.sh $fldr/bold.nii $fldr/filtered_func_data.nii.gz $featdir/mc/prefiltered_func_data_mcf.mat $alff_uw_shiftmap $_uwdir trilinear ;\
      #$scriptdir/getsliceorderSIEMENS_interleaved.sh $fldr/filtered_func_data.nii.gz $fldr/sliceorder.txt ; slicetimer -i $fldr/filtered_func_data.nii.gz --out=$fldr/_tmp.nii.gz -r $TR_bold --ocustom=$fldr/sliceorder.txt ;\
      #$scriptdir/feat_hpf.sh $fldr/_tmp.nii.gz $fldr/__tmp.nii.gz $ALFF_HPF_CUTOFF $TR_bold $subj $sess ;\
      #rm -f $fldr/filtered_func_data.nii.gz $fldr/_tmp.nii.gz ;\
      #mv $fldr/__tmp.nii.gz $fldr/filtered_func_data.nii.gz" > $cmd
      
      echo "ALFF : execute cmd:"
      cat -nb $cmd        
      jid=`fsl_sub -l $logdir -N $(basename $cmd)_$(subjsess) -t $cmd`
    done
  done

  waitIfBusy

  # denoise
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_func` ; do
          
      # check if we have acquisition parameters
      defineBOLDparams $subjdir/config_acqparams_bold $subj $sess
      
      # declare vars
      uwdir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess` ; featdir=$subjdir/$subj/$sess/$(echo "$ALFF_FEATDIR" | sed "s|??|$uwdir|g")
      fldr=$subjdir/$subj/$sess/alff
      
      cmd=$fldr/alff_denoise.cmd ; rm -f $cmd

      # create cmd
      echo "ALFF : subj $subj , sess $sess : denoising (tag: ${dntag_alff})..."
      mkdir -p $fldr/noise ; ln -sf ../filtered_func_data.nii.gz $fldr/noise/filtered_func_data.nii.gz
      echo "    $scriptdir/denoise4D.sh $fldr/noise/filtered_func_data "$ALFF_DENOISE_MASKS_NAT" $featdir/mc/prefiltered_func_data_mcf.par "$ALFF_DENOISE_USE_MOVPARS_NAT" $ALFF_HPF_CUTOFF $TR_bold $fldr/noise/filtered_func_data_dn${dntag_alff} $subj $sess" > $cmd
      
      echo "ALFF : execute cmd:"
      cat -nb $cmd        
      jid=`fsl_sub -l $logdir -N $(basename $cmd)_$(subjsess) -t $cmd`      
    done
  done

  waitIfBusy
  
  # mask & smooth
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_func` ; do
      
      # check if we have acquisition parameters
      defineBOLDparams $subjdir/config_acqparams_bold $subj $sess
      
      # declare vars
      fldr=$subjdir/$subj/$sess/alff
      sm=$ALFF_SMOOTHING_KERNEL
      
      cmd=$fldr/alff_smooth.cmd ; rm -f $cmd
      
      # create cmd
      echo "ALFF : subj $subj , sess $sess : smoothing (FWHM: ${sm})..."
      echo "    $scriptdir/feat_smooth.sh $fldr/noise/filtered_func_data_dn${dntag_alff} $fldr/filtered_func_data_dn${dntag_alff} $sm none $subj $sess" > $cmd
      #tail $cmd
      
      echo "ALFF : execute cmd:"
      cat -nb $cmd        
      jid=`fsl_sub -l $logdir -N $(basename $cmd)_$(subjsess) -t $cmd`
      
      sleepfor $DELAYINSECS
    done
  done
fi


waitIfBusy


if [ $ALFF_STG2 -eq 1 ] ; then
  echo "----- BEGIN ALFF_STG2 -----"
  
  # create (f)ALFF
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_func` ; do
      # declare vars
      fldr=$subjdir/$subj/$sess/alff
      out=$fldr/$(subjsess)
      sm=$ALFF_SMOOTHING_KERNEL
      
      cmd=$fldr/alff_createALFF.cmd ; rm -f $cmd
      
      # create cmd
      echo "ALFF : subj $subj , sess $sess : eroding susan's brain-mask a bit..." # this is perhaps not so good (!)
      fslmaths $fldr/filtered_func_data_dn${dntag_alff}_susan_mask -ero $fldr/susan_mask_ero # erode the dilated susan mask
      echo "ALFF : subj $subj , sess $sess : creating ALFF maps..."
      echo "    $scriptdir/createALFF.sh ${out} $fldr/filtered_func_data_dn${dntag_alff}_s${sm} $fldr/susan_mask_ero $TR_bold $ALFF_BANDPASS" > $cmd
      
      echo "ALFF : execute cmd:"
      cat -nb $cmd
      jid=`fsl_sub -l $logdir -N $(basename $cmd)_$(subjsess) -t $cmd`
    done
  done
fi


waitIfBusy


if [ $ALFF_STG3 -eq 1 ] ; then
  echo "----- BEGIN ALFF_STG3 -----"
  
  # register to MNI space
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_func` ; do
      # declare vars
      fldr=$subjdir/$subj/$sess/alff
      out=$fldr/$(subjsess)
      uwdir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess` ; featdir=$subjdir/$subj/$sess/$(echo "$ALFF_FEATDIR" | sed "s|??|$uwdir|g")
      affine=$featdir/$ALFF_MNI_AFFINE
      warp=$featdir/$ALFF_MNI_WARP
      interp=trilinear            
      MNI_file=$FSL_DIR/data/standard/MNI152_T1_2mm_brain.nii.gz
      
      # check
      if [ ! -f $affine ] ; then echo "ALFF : subj $subj , sess $sess : ERROR: '$affine' not found. Exiting..." ; exit 1 ; fi
      if [ $(_imtest $warp) -eq 0 ] ; then echo "ALFF : subj $subj , sess $sess : ERROR: '$warp' not found. Exiting..." ; exit 1 ; fi
          
      # copy template
      cp $MNI_file $fldr/standard.nii.gz
      
      # create cmd
      for mni_res in $ALFF_RESAMPLING_RESOLUTIONS ; do
        echo "ALFF : subj $subj , sess $sess : registering ALFF maps to MNI space at resolution '$mni_res'..."
        cmd="    flirt -ref $fldr/standard -in $fldr/standard -out $fldr/standard_${mni_res} -applyisoxfm $mni_res"
        echo $cmd ; $cmd
        
        cmd="    applywarp --ref=$fldr/standard_${mni_res} --in=${out}_ALFF.nii.gz --out=${out}_ALFF_mni${mni_res} --warp=${warp} --premat=${affine} --interp=${interp}"
        echo $cmd ; $cmd
        cmd="    applywarp --ref=$fldr/standard_${mni_res} --in=${out}_fALFF.nii.gz --out=${out}_fALFF_mni${mni_res} --warp=${warp} --premat=${affine} --interp=${interp}"
        echo $cmd ; $cmd
        cmd="    applywarp --ref=$fldr/standard_${mni_res} --in=${out}_ALFF_Z.nii.gz --out=${out}_ALFF_Z_mni${mni_res} --warp=${warp} --premat=${affine} --interp=${interp}"
        echo $cmd ; $cmd
        cmd="    applywarp --ref=$fldr/standard_${mni_res} --in=${out}_fALFF_Z.nii.gz --out=${out}_fALFF_Z_mni${mni_res} --warp=${warp} --premat=${affine} --interp=${interp}"
        echo $cmd ; $cmd
        
        cmd="    applywarp --ref=$fldr/standard_${mni_res} --in=$fldr/filtered_func_data_dn${dntag_alff}_susan_mask.nii.gz --out=$fldr/susan_mask_mni${mni_res}.nii.gz --warp=${warp} --premat=${affine} --interp=${interp}"
        echo $cmd ; $cmd
        cmd="    fslmaths $fldr/susan_mask_mni${mni_res} -bin $fldr/susan_mask_mni${mni_res}"
        echo $cmd ; $cmd
      done    
    done
  done  
fi

######################
# ----- END ALFF -----
######################


waitIfBusy


#####################################
#####################################
# ----- BEGIN 2nLevel Analyses -----#
#####################################
#####################################

# change to 2nd level directory
cd $grpdir

########################
# ----- BEGIN ALFF -----
########################

# ALFF prepare ALFF data
if [ $ALFF_2NDLEV_STG1 -eq 1 ] ; then
  echo "----- BEGIN ALFF_2NDLEV_STG1 -----"
  echo "ALFF_2NDLEV: prepare..."
  for res in $ALFF_RESOLUTIONS ; do
    ztransform2ndlev=1
    prepareALFF $subjdir alff $alffdir/$ALFF_OUTDIRNAME/stats_mni${res} "*_ALFF_mni${res}.nii.gz" "*_fALFF_mni${res}.nii.gz" "susan_mask_mni${res}.nii.gz" $ztransform2ndlev $ALFF_DELETE_PREV_RUNS
    ##################
    ztransform2ndlev=0
    prepareALFF $subjdir alff $alffdir/$ALFF_OUTDIRNAME/stats_nativeZ_mni${res} "*_ALFF_Z_mni${res}.nii.gz" "*_fALFF_Z_mni${res}.nii.gz" "susan_mask_mni${res}.nii.gz" $ztransform2ndlev $ALFF_DELETE_PREV_RUNS
  done 
fi

waitIfBusy

if [ $ALFF_2NDLEV_STG2 -eq 1 ] ; then
  echo "----- BEGIN ALFF_2NDLEV_STG2 -----"
  echo "ALFF_2NDLEV : copying GLM designs..."  
 
  for res in $ALFF_RESOLUTIONS ; do
    statdirs=${alffdir}/${ALFF_OUTDIRNAME}/stats_mni${res}" "${alffdir}/${ALFF_OUTDIRNAME}/stats_nativeZ_mni${res} 
    
    for statdir in $statdirs ; do
      echo "ALFF_2NDLEV : copying GLM designs to $statdir"
      cat $glmdir_alff/designs | xargs -I{} cp -r $glmdir_alff/{} $statdir; cp $glmdir_alff/designs $statdir
      
      echo "ALFF_2NDLEV : starting permutations for fALFF-maps..."
      _randomise $statdir falff "fALFF_Z_merged" "-m ../brain_mask -d design.mat -t design.con -e design.grp $ALFF_RANDOMISE_OPTS" 0 brain_mask.nii.gz $RANDOMISE_PARALLEL
      waitIfBusy
    done    
  done
  
  waitIfBusy
  
  for res in $ALFF_RESOLUTIONS ; do
    statdirs=${alffdir}/${ALFF_OUTDIRNAME}/stats_mni${res}" "${alffdir}/${ALFF_OUTDIRNAME}/stats_nativeZ_mni${res}
    
    for statdir in $statdirs ; do
      echo "ALFF_2NDLEV : starting permutations for ALFF-maps..."
      _randomise $statdir alff "ALFF_Z_merged" "-m ../brain_mask -d design.mat -t design.con -e design.grp $ALFF_RANDOMISE_OPTS" 0 brain_mask.nii.gz $RANDOMISE_PARALLEL
      waitIfBusy
    done
  done
  
fi

########################
# ----- END ALFF -----
########################

waitIfBusy

########################
# ----- BEGIN TBSS -----
########################

# TBSS prepare TBSS data
if [ $TBSS_STG1 -eq 1 ] ; then
  echo "----- BEGIN TBSS_STG1 -----"
  echo "TBSS: prepare..."
  if [ $TBSS_USE_NOEC -eq 1 ] ; then prepareTBSS $subjdir fdt $tbssdir/${TBSS_OUTDIR_PREFIX}_noec "*_dti_noec_FA.nii.gz" -T $TBSS_DELETE_PREV_RUNS ; fi # check pattern (!)
  if [ $TBSS_USE_EC_NOROT -eq 1 ] ; then prepareTBSS $subjdir fdt $tbssdir/${TBSS_OUTDIR_PREFIX}_ec_norot "*_dti_ec_norot_FA.nii.gz" -T $TBSS_DELETE_PREV_RUNS ; fi # check pattern (!)
  if [ $TBSS_USE_EC_BVECROT -eq 1 ] ; then prepareTBSS $subjdir fdt $tbssdir/${TBSS_OUTDIR_PREFIX}_ec_bvecrot "*_dti_ec_bvecrot_FA.nii.gz" -T $TBSS_DELETE_PREV_RUNS ; fi # check pattern (!)
  if [ $TBSS_USE_UNWARPED_NOROT -eq 1 ] ; then prepareTBSS $subjdir fdt $tbssdir/${TBSS_OUTDIR_PREFIX}_uw_norot "*_dti_uw_norot_FA.nii.gz" -T $TBSS_DELETE_PREV_RUNS ; fi # check pattern (!)
  if [ $TBSS_USE_UNWARPED_BVECROT -eq 1 ] ; then prepareTBSS $subjdir fdt $tbssdir/${TBSS_OUTDIR_PREFIX}_uw_bvecrot "*_dti_uw_bvecrot_FA.nii.gz" -T $TBSS_DELETE_PREV_RUNS ; fi # check pattern (!)
  if [ $TBSS_USE_TOPUP_NOEC_BVECROT -eq 1 ] ; then prepareTBSS $subjdir topup $tbssdir/${TBSS_OUTDIR_PREFIX}_topup_noec_bvecrot "*_dti_topup_noec_bvecrot_FA.nii.gz" -T $TBSS_DELETE_PREV_RUNS ; fi # check pattern (!)
  if [ $TBSS_USE_TOPUP_EC_BVECROT -eq 1 ] ; then prepareTBSS $subjdir topup $tbssdir/${TBSS_OUTDIR_PREFIX}_topup_ec_bvecrot "*_dti_topup_ec_bvecrot_FA.nii.gz" -T $TBSS_DELETE_PREV_RUNS ; fi # check pattern (!)
fi

waitIfBusy

# TBSS threshold skeleton mask...
if [ $TBSS_STG2 -eq 1 ] ; then
  echo "----- BEGIN TBSS_STG2 -----"
  for thres in $TBSS_THRES ; do
    echo "TBSS: threshold skeletons at $thres..."
    if [ $TBSS_USE_NOEC -eq 1 ] ; then thres_skeleton $tbssdir/${TBSS_OUTDIR_PREFIX}_noec $thres $TBSS_DELETE_PREV_RUNS ; fi
    if [ $TBSS_USE_EC_NOROT -eq 1 ] ; then thres_skeleton $tbssdir/${TBSS_OUTDIR_PREFIX}_ec_norot $thres $TBSS_DELETE_PREV_RUNS ; fi
    if [ $TBSS_USE_EC_BVECROT -eq 1 ] ; then thres_skeleton $tbssdir/${TBSS_OUTDIR_PREFIX}_ec_bvecrot $thres $TBSS_DELETE_PREV_RUNS ; fi
    if [ $TBSS_USE_UNWARPED_NOROT -eq 1 ] ; then thres_skeleton $tbssdir/${TBSS_OUTDIR_PREFIX}_uw_norot $thres $TBSS_DELETE_PREV_RUNS ; fi
    if [ $TBSS_USE_UNWARPED_BVECROT -eq 1 ] ; then thres_skeleton $tbssdir/${TBSS_OUTDIR_PREFIX}_uw_bvecrot $thres $TBSS_DELETE_PREV_RUNS ; fi
    if [ $TBSS_USE_TOPUP_NOEC_BVECROT -eq 1 ] ; then thres_skeleton $tbssdir/${TBSS_OUTDIR_PREFIX}_topup_noec_bvecrot $thres $TBSS_DELETE_PREV_RUNS ; fi
    if [ $TBSS_USE_TOPUP_EC_BVECROT -eq 1 ] ; then thres_skeleton $tbssdir/${TBSS_OUTDIR_PREFIX}_topup_ec_bvecrot $thres $TBSS_DELETE_PREV_RUNS ; fi
  done
fi

waitIfBusy

# TBSS randomise..
if [ $TBSS_STG3 -eq 1 ] ; then
  echo "----- BEGIN TBSS_STG3 -----"
  # define tbss subdirectories
  tbss_dirs=""
  if [ $TBSS_USE_NOEC -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_noec ; fi
  if [ $TBSS_USE_EC_NOROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_ec_norot ; fi
  if [ $TBSS_USE_EC_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_ec_bvecrot ; fi
  if [ $TBSS_USE_UNWARPED_NOROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_uw_norot ; fi
  if [ $TBSS_USE_UNWARPED_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_uw_bvecrot ; fi
  if [ $TBSS_USE_TOPUP_NOEC_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_topup_noec_bvecrot ; fi
  if [ $TBSS_USE_TOPUP_EC_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_topup_ec_bvecrot ; fi
   
  echo "TBSS: copying GLM designs..."
  for tbss_dir in $tbss_dirs ; do
    for thres in $TBSS_THRES ; do
      statdir=$tbss_dir/stats_${thres}
      if [ ! -d $statdir ] ; then echo "TBSS: WARNING: <$statdir> not found - continuing loop..." ; continue ; fi
    
      echo "TBSS: copying GLM designs to $statdir"
      cat $glmdir_tbss/designs | xargs -I{} cp -r $glmdir_tbss/{} $statdir; cp $glmdir_tbss/designs $statdir
      echo "TBSS: starting permutations..."
      _randomise $statdir tbss "all_FA_skeletonised" "-m ../mean_FA_skeleton_mask -d design.mat -t design.con -e design.grp $TBSS_RANDOMISE_OPTS" $TBSS_Z_TRANSFORM mean_FA_skeleton_mask.nii.gz $RANDOMISE_PARALLEL

    done
  done
fi

waitIfBusy

# TBSS prepare TBSSX
if [ $TBSS_STG4 -eq 1 ] ; then
  echo "----- BEGIN TBSS_STG4 -----"
  ## bedpostX files present ?
  #if [ ! -d $FS_subjdir/$(subjsess)/dmri.bedpostX ] ; then echo "TBSSX: dmri.bedpostX directory not found for TBSSX - you must run TRACULA first. Exiting ..." ; exit 1 ; fi
  
  # define tbss subdirectories
  tbss_dirs=""
  if [ $TBSS_USE_NOEC -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_noec ; fi
  if [ $TBSS_USE_EC_NOROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_ec_norot ; fi
  if [ $TBSS_USE_EC_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_ec_bvecrot ; fi
  if [ $TBSS_USE_UNWARPED_NOROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_uw_norot ; fi
  if [ $TBSS_USE_UNWARPED_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_uw_bvecrot ; fi
  if [ $TBSS_USE_TOPUP_NOEC_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_topup_noec_bvecrot ; fi
  if [ $TBSS_USE_TOPUP_EC_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_topup_ec_bvecrot ; fi

  for tbss_dir  in $tbss_dirs ; do
    if [ ! $tbss_dir ] ; then echo "TBSS: ERROR: $tbss_dir not found - exiting..." ; exit 1 ; fi
    
    # define dti type
    FA_type=$(basename $tbss_dir | sed "s|^${TBSS_OUTDIR_PREFIX}_||g")
    
    # change directory
    echo "TBSSX: changing to <$tbss_dir>"
    cd  $tbss_dir
      if [ ! -d stats -a ! -d _stats ] ; then echo "TBSSX: ERROR: $tbss_dir/[_]stats not found - you must run the TBSS stream first; exiting..." ; exit 1 ; fi
       
      # cleanup prev. runs
      rm -f F1/* F2/* D1/* D2/*       
      
      # create TBSSX directories
      mkdir -p F1 F2 D1 D2
       
      if [ $TBSS_USE_BPX_FROM_TRACULA -eq 1 ] ; then
        # copy bedpostX files from TRACULA
        for subj in $TBSS_INCLUDED_SUBJECTS ; do
          for sess in $TBSS_INCLUDED_SESSIONS ; do
            fname=$(subjsess)_dti_${FA_type}_FA.nii.gz
            if [ ! -d $FS_subjdir/$(subjsess)/dmri.bedpostX ] ; then echo "TBSSX: ERROR: directory '$FS_subjdir/$(subjsess)/dmri.bedpostX' not found  - you must run the TRACULA stream first..." ; exit 1 ; fi
            echo "TBSSX: copying..."
            cp -v $FS_subjdir/$(subjsess)/dmri.bedpostX/dyads1.nii.gz D1/$fname
            cp -v $FS_subjdir/$(subjsess)/dmri.bedpostX/dyads2.nii.gz D2/$fname
            cp -v $FS_subjdir/$(subjsess)/dmri.bedpostX/mean_f1samples.nii.gz F1/$fname
            cp -v $FS_subjdir/$(subjsess)/dmri.bedpostX/mean_f2samples.nii.gz F2/$fname
          done 
        done
      else            
        # copy bedpostX files
        errflag=0
        for subj in $TBSS_INCLUDED_SUBJECTS ; do
          for sess in $TBSS_INCLUDED_SESSIONS ; do
            bpx_dir=$subjdir/$subj/$sess/bpx/${TBSS_BPX_INDIR_PREFIX}_${FA_type}.bedpostX
            if [ ! -d $bpx_dir ] ; then echo "TBSSX: ERROR: directory '$bpx_dir' not found - you must run BedpostX first..." ; errflag=1 ; fi
          done 
        done
        if [ $errflag -eq 1 ] ; then echo "... exiting." ; exit 1 ; fi
        
        echo "TBSSX: copying..."
        for subj in $TBSS_INCLUDED_SUBJECTS ; do
          for sess in $TBSS_INCLUDED_SESSIONS ; do
            fname=$(subjsess)_dti_${FA_type}_FA.nii.gz
            bpx_dir=$subjdir/$subj/$sess/bpx/${TBSS_BPX_INDIR_PREFIX}_${FA_type}.bedpostX
            cp -v $bpx_dir/dyads1.nii.gz D1/$fname
            cp -v $bpx_dir/dyads2.nii.gz D2/$fname
            cp -v $bpx_dir/mean_f1samples.nii.gz F1/$fname
            cp -v $bpx_dir/mean_f2samples.nii.gz F2/$fname
          done
        done
      fi
       
      # create link to thresholded tbss-stats directory and execute tbss_x script
      if [ -L stats ] ; then rm stats ; fi
      if [ -d stats ] ; then mv stats _stats ; fi
      for thres in $TBSS_THRES ; do
        # is stats directory present ?
        statdir=$tbss_dir/stats_${thres}
        if [ "x$statdir" = "x" ] ; then echo "TBSSX: directory <stats_${thres}> not found in <$tbss_dir> - continuing loop..." ; continue ; fi
        # create link
        echo "TBSSX: creating link 'stats' -> <$statdir>..."
        ln -sfnv `basename $statdir` stats # mind the -n option, o.w. the dir-link is not overwritten on each iteration (!)
        # execute tbss_x script
        tbss_x F1 F2 D1 D2
        cd $tbss_dir           
      done
      
      # cleanup
      if [ -L stats ] ; then rm stats ; fi
      mv _stats stats
      
    echo "TBSSX: changing to <$grpdir>"
    cd $grpdir
  done
fi

waitIfBusy

# TBSS randomise TBSSX...
if [ $TBSS_STG5 -eq 1 ] ; then
  echo "----- BEGIN TBSS_STG5 -----"
  tbss_dirs=""
  if [ $TBSS_USE_NOEC -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_noec ; fi
  if [ $TBSS_USE_EC_NOROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_ec_norot ; fi
  if [ $TBSS_USE_EC_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_ec_bvecrot ; fi
  if [ $TBSS_USE_UNWARPED_NOROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_uw_norot ; fi
  if [ $TBSS_USE_UNWARPED_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_uw_bvecrot ; fi
  if [ $TBSS_USE_TOPUP_NOEC_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_topup_noec_bvecrot ; fi
  if [ $TBSS_USE_TOPUP_EC_BVECROT -eq 1 ] ; then tbss_dirs=$tbss_dirs" "$tbssdir/${TBSS_OUTDIR_PREFIX}_topup_ec_bvecrot ; fi

  echo "TBSSX: copying GLM designs..."
  for tbss_dir in $tbss_dirs ; do
    for thres in $TBSS_THRES ; do
      statdir=$tbss_dir/stats_${thres}
      if [ ! -d $statdir ] ; then echo "TBSSX: WARNING: <$statdir> not found - continuing loop..." ; continue ; fi
    
      echo "TBSSX: copying GLM designs to $statdir"
      cat $glmdir_tbss/designs | xargs -I{} cp -r $glmdir_tbss/{} $statdir; cp $glmdir_tbss/designs $statdir
      echo "TBSSX: starting permutations..."
      _randomise $statdir tbssxF1 "all_F1_x_skeletonised" "-m ../mean_FA_skeleton_mask -d design.mat -t design.con -e design.grp $TBSS_RANDOMISE_OPTS" $TBSS_Z_TRANSFORM mean_FA_skeleton_mask.nii.gz $RANDOMISE_PARALLEL
      _randomise $statdir tbssxF2 "all_F2_x_skeletonised" "-m ../mean_FA_skeleton_mask -d design.mat -t design.con -e design.grp $TBSS_RANDOMISE_OPTS" $TBSS_Z_TRANSFORM mean_FA_skeleton_mask.nii.gz $RANDOMISE_PARALLEL
    done
  done
fi

######################
# ----- END TBSS -----
######################


waitIfBusy


############################
# ----- BEGIN FS_STATS -----
############################

FS_STATS_SMOOTHING_KRNLS=\'$FS_STATS_SMOOTHING_KRNLS\'
FS_STATS_MEASURES=\'$FS_STATS_MEASURES\'

# resampling to fsaverage space
if [ $FS_STATS_STG1 -eq 1 ] ; then
  mkdir -p $FSstatsdir
  echo "$scriptdir/fs_stats.sh $SUBJECTS_DIR $glmdir_fs $FSstatsdir" $FS_STATS_MEASURES $FS_STATS_SMOOTHING_KRNLS "1 0 0 0 $FS_STATS_NPERM $logdir" > $FSstatsdir/fs_stats_01.cmd  
  . $FSstatsdir/fs_stats_01.cmd
  echo ""
  echo ""
fi

waitIfBusy

# smoothing
if [ $FS_STATS_STG2 -eq 1 ] ; then
  echo "$scriptdir/fs_stats.sh $SUBJECTS_DIR $glmdir_fs $FSstatsdir" $FS_STATS_MEASURES $FS_STATS_SMOOTHING_KRNLS "0 1 0 0 $FS_STATS_NPERM $logdir" > $FSstatsdir/fs_stats_02.cmd  
  . $FSstatsdir/fs_stats_02.cmd
  echo ""
  echo ""
fi

waitIfBusy

# GLM
if [ $FS_STATS_STG3 -eq 1 ] ; then
  echo "$scriptdir/fs_stats.sh $SUBJECTS_DIR $glmdir_fs $FSstatsdir" $FS_STATS_MEASURES $FS_STATS_SMOOTHING_KRNLS "0 0 1 0 $FS_STATS_NPERM $logdir" > $FSstatsdir/fs_stats_03.cmd  
  . $FSstatsdir/fs_stats_03.cmd
  echo ""
  echo ""
fi

waitIfBusy

# GLM permutation testing
if [ $FS_STATS_STG4 -eq 1 ] ; then
  echo "$scriptdir/fs_stats.sh $SUBJECTS_DIR $glmdir_fs $FSstatsdir" $FS_STATS_MEASURES $FS_STATS_SMOOTHING_KRNLS "0 0 0 1 $FS_STATS_NPERM $logdir" > $FSstatsdir/fs_stats_04.cmd  
  . $FSstatsdir/fs_stats_04.cmd
  echo ""
  echo ""
fi


##########################
# ----- END FS_STATS -----
##########################


waitIfBusy


#######################
# ----- BEGIN VBM -----
#######################


if [ $VBM_2NDLEV_STG1 -eq 1 ] ; then
  echo "----- BEGIN VBM_2NDLEV_STG1 -----"
  echo "VBM_2NDLEV : prepare..."
  prepareVBM $subjdir $vbmdir/${VBM_OUTDIRNAME} "$VBM_PTTRN_STRUC" "$VBM_PTTRN_BRAIN" $VBM_DELETE_PREV_RUNS
fi

waitIfBusy

if [ $VBM_2NDLEV_STG2 -eq 1 ] ; then
  echo "----- BEGIN VBM_2NDLEV_STG2 -----"
  for kernel in $VBM_SMOOTHING_KRNL ; do
    echo "VBM_2NDLEV : smooth with $kernel..."
    vbm_smooth $vbmdir/${VBM_OUTDIRNAME} $kernel $VBM_DELETE_PREV_RUNS
  done
fi

waitIfBusy

if [ $VBM_2NDLEV_STG3 -eq 1 ] ; then
  echo "----- BEGIN VBM_2NDLEV_STG3 -----"
  echo "VBM_2NDLEV : copying GLM designs..."
  for krnl in $VBM_SMOOTHING_KRNL ; do
    statdirs=`find $vbmdir/${VBM_OUTDIRNAME} -maxdepth 1 -mindepth 1 -type d  | sort | grep stats_s${krnl} || true` # added '|| true' to avoid abortion by 'set -e' statement
    if [ "x$statdirs" = "x" ] ; then echo "VBM_2NDLEV : no stats directories found - continuing loop..." ; continue ; fi
    
    for i in $statdirs ; do
      echo "VBM_2NDLEV : copying GLM designs to $i"
      cat $glmdir_vbm/designs | xargs -I{} cp -r $glmdir_vbm/{} $i; cp $glmdir_vbm/designs $i
      echo "VBM_2NDLEV : starting permutations..."
      _randomise $i vbm "GM_mod_merg_smoothed" "-m ../GM_mask -d design.mat -t design.con -e design.grp $VBM_RANDOMISE_OPTS" $VBM_Z_TRANSFORM GM_mask.nii.gz $RANDOMISE_PARALLEL
    done
  done
fi

#####################
# ----- END VBM -----
#####################


waitIfBusy


#################################
# ----- BEGIN MELODIC_2NDLEV -----
#################################

# MELODIC_2NDLEV create *.fsf configuration file
if [ $MELODIC_2NDLEV_STG1 -eq 1 ]; then
  echo "----- BEGIN MELODIC_2NDLEV_STG1 -----"
  fldr=$gicadir ; mkdir -p $fldr
  conffile=$fldr/${MELODIC_OUTDIRNAME}_$(remove_ext $MELODIC_INPUT_FILE).fsf
  templateICA=$tmpltdir/template_gICA.fsf
  
  echo "MELODIC_GROUP: creating MELODIC configuration file '$conffile'..."
 
  if [ ! -f $templateICA ] ; then echo "MELODIC_GROUP: ERROR: MELODIC template file not found - exiting..." ; exit 1 ; fi
  if [ ! -f $subjdir/config_func2highres.reg ] ; then echo "MELODIC_GROUP: ERROR: registration mapping between functionals and t1 reference not found - exiting..." ; exit 1 ; fi

  cat $templateICA > $conffile
 
  # count volumes
  npts=0 ; _npts=0 ; n=0
  for subj in $MELODIC_INCLUDED_SUBJECTS ; do
    for sess in $MELODIC_INCLUDED_SESSIONS ; do
      bold=$subjdir/$subj/$sess/bold/$MELODIC_INPUT_FILE

      echo -n "MELODIC_GROUP: counting volumes in '$bold'..."
      npts=`countVols ${bold}` # number of volumes in 4D bold
      echo " ${npts} volumes."
      if [ $n -gt 0 ] ; then
        if [ ! $npts -eq $_npts ] ; then
          "MELODIC_GROUP: WARNING: Unequal number of volumes in input files detected." 
        fi
      fi
      _npts=$npts
      n=$[$n+1]
    done
  done
  
  # add unwarped bold files and highres T1s to *.fsf configuration file
  n=0
  for subj in $MELODIC_INCLUDED_SUBJECTS ; do
    for sess in $MELODIC_INCLUDED_SESSIONS ; do  
      n=$[$n+1]

      bold=$subjdir/$subj/$sess/bold/$MELODIC_INPUT_FILE
      
      echo "# 4D AVW data or FEAT directory ($n)" >> $conffile
      echo "set feat_files($n) \"$(remove_ext $bold)\"" >> $conffile # remove extension, o.w. *.ica directories are not properly named (!)
      
      #sess_t1=`cat $subjdir/config_func2highres.reg | grep ^$(subjsess) | cut -f2`
      line=`cat $subjdir/config_func2highres.reg | awk '{print $1}' | grep -nx $(subjsess) | cut -d : -f1`
      sess_t1=`cat $subjdir/config_func2highres.reg | awk '{print $2}' | sed -n ${line}p `
      if [ $sess_t1 = '.' ] ; then sess_t1="" ; fi # single-session design
      t1_brain=$gicadir/${subj}${sess_t1}_t1_brain
      
      echo "MELODIC_GROUP: using t1_brain from session '$sess_t1' as reference for '$bold'"
      echo "# Subject's structural image for analysis $n" >> $conffile
      echo "set highres_files($n) \"$t1_brain\"" >> $conffile # no file extension here, o.w. the non-brain extracted T1 is not found and non-linear registration will become highly inaccurate (feat does not throw an error here!) (!)  
    done
  done
  
  # check if we have acquisition parameters
  defineBOLDparams $subjdir/config_acqparams_bold # assuming that TR is the same for all datasets
  
  # do some substitutions on the MELODIC template file
  outdir=$fldr/${MELODIC_OUTDIRNAME} # define output directory
  echo "MELODIC_GROUP: counting volumes in '$bold' (assuming that all other inputs have the same number)..."
  npts=`countVols ${bold}` # number of volumes in 4D bold
  echo "MELODIC_GROUP: ...${npts} volumes."
  sed -i "s|set fmri(multiple) .*|set fmri(multiple) $n|g" $conffile # set nuber of first-level analyses
  sed -i "s|set fmri(outputdir) .*|set fmri(outputdir) \"$outdir\"|g" $conffile # set output-dir
  sed -i "s|set fmri(npts) .*|set fmri(npts) $npts|g" $conffile # set number of volumes in 4D
  sed -i "s|set fmri(tr) .*|set fmri(tr) $TR_bold|g" $conffile # set TR
  sed -i "s|set fmri(regstandard) .*|set fmri(regstandard) \"$FSL_DIR/data/standard/MNI152_T1_2mm_brain\"|g" $conffile # set MNI template
  sed -i "s|set fmri(regstandard_res) X|set fmri(regstandard_res) $MELODIC_REGSTD_RESOLUTION|g" $conffile # set resampling resolution of normalised volumes (mm)
  sed -i "s|set fmri(smooth) X|set fmri(smooth) $MELODIC_SMOOTH|g" $conffile # set smoothing kernel width (mm)
  sed -i "s|set fmri(paradigm_hp) X|set fmri(paradigm_hp) $MELODIC_HIGHPASS_CUTOFF|g" $conffile # set high-pass filter cuoff value
  sed -i "s|fmri(overwrite_yn) .*|fmri(overwrite_yn) 0|g" $conffile # overwrite on re-run (does not work in case of Melodic!) (!)
  # brain extraction
  if [ $MELODIC_BET -eq 1 ] ; then
    sed -i "s|set fmri(bet_yn) .*|set fmri(bet_yn) 1|g" $conffile
  else
    sed -i "s|set fmri(bet_yn) .*|set fmri(bet_yn) 0|g" $conffile
  fi              
fi

waitIfBusy

# create appropriately named links to t1-brain and t1-structural images (needed for MELODIC/FEAT registration procedure)
if [ $MELODIC_2NDLEV_STG2 -eq 1 ]; then
  echo "----- BEGIN MELODIC_2NDLEV_STG2 -----"
  for subj in $MELODIC_INCLUDED_SUBJECTS ; do
    for sess in $MELODIC_INCLUDED_SESSIONS ; do    
      line=`cat $subjdir/config_func2highres.reg | awk '{print $1}' | grep -nx $(subjsess) | cut -d : -f1`
      sess_t1=`cat $subjdir/config_func2highres.reg | awk '{print $2}' | sed -n ${line}p `
      if [ $sess_t1 = '.' ] ; then sess_t1="" ; fi # single-session design
      fldr=$subjdir/$subj/$sess_t1/vbm
      
      echo "MELODIC_GROUP: creating appropriately named links to brain-extracted and original high-res images to please MELODIC (functional in session '$sess' -> structural in session '$sess_t1')" 
      
      melodic_t1brain=`ls $fldr/$MELODIC_PTTRN_HIGHRES_BRAIN`
      melodic_t1struc=`ls $fldr/$MELODIC_PTTRN_HIGHRES_STRUC`
           
      if [ "x$melodic_t1brain" = "x" ] ; then echo "MELODIC_GROUP: WARNING: brain-extracted high-res not found - continuing loop... " ; continue ; fi
      if [ "x$melodic_t1struc" = "x" ] ; then echo "MELODIC_GROUP: WARNING: high-res not found - continuing loop... " ; continue ; fi
      
      #cp -v $melodic_t1struc $gicadir/$(subjsess)_t1.nii.gz
      #cp -v $melodic_t1brain $gicadir/$(subjsess)_t1_brain.nii.gz
      cmd="ln -sfv ../../$(basename $subjdir)/$subj/$sess_t1/vbm/$(basename $melodic_t1struc) $gicadir/$(subjsess)_t1.nii.gz" ; $cmd
      cmd="ln -sfv ../../$(basename $subjdir)/$subj/$sess_t1/vbm/$(basename $melodic_t1brain) $gicadir/$(subjsess)_t1_brain.nii.gz " ; $cmd
    done
  done
fi

###############################
# ----- END MELODIC_2NDLEV -----
###############################


waitIfBusy


###############################
# ----- BEGIN MELODIC_CMD -----
###############################

# MELODIC_CMD use melodic command line tool
if [ $MELODIC_CMD_STG1 -eq 1 ]; then
  echo "----- BEGIN MELODIC_CMD_STG1 -----"
  
  for melodic_input in $MELODIC_CMD_INPUT_FILES ; do
    
    fldr=$gicadir/${MELODIC_CMD_OUTDIR_PREFIX}_$(remove_ext $melodic_input).gica
    
    # erase prev. run
    if [ -d $fldr ] ; then
      if [ $MELODIC_CMD_DELETE_PREV_RUNS -eq 1 ] ; then
        echo "MELODIC_CMD : WARNING : folder '$fldr' already exists - deleting it in 5 seconds as requested (abort with CTRL-C)..." ; sleep 5 ; 
        rm -r $fldr
      else
        read -p "MELODIC_CMD : WARNING : folder '$fldr' already exists - press key to continue..."
      fi
    fi
    
    # create dir.
    mkdir -p $fldr
    
    # add bold files...
    rm -f $fldr/input.files
    err=0
    for subj in $MELODIC_CMD_INCLUDED_SUBJECTS ; do
      for sess in $MELODIC_CMD_INCLUDED_SESSIONS ; do  

        bold=$subjdir/$subj/$sess/bold/$melodic_input
        
        if [ $(_imtest $bold) -eq 0 ] ; then echo "MELODIC_CMD : subj $subj , sess $sess : ERROR : input volume '$bold' not found - continuing loop..." ; err=1 ; continue ; fi
        
        echo "MELODIC_CMD  subj $subj , sess $sess : adding input-file '$bold'"
        echo $bold | tee -a $fldr/input.files
      
      done
    done    
    if [ $err -eq 1 ] ; then echo "MELODIC_CMD : an ERROR has occurred - exiting..." ; exit 1 ; fi
    
    # shall we bet ?
    opts=""
    if [ $MELODIC_CMD_BET -eq 0 ] ; then opts="--nobet --bgthreshold=10" ; fi
    
    # check if we have acquisition parameters
    defineBOLDparams $subjdir/config_acqparams_bold # assuming that TR is the same for all datasets
    
    # execute
    echo "MELODIC_CMD : executing melodic command line tool:"
    echo "melodic -i $fldr/input.files -o $fldr/groupmelodic.ica $opts -v --tr=$TR_bold --report --guireport=$fldr/report.html -d 0 --mmthresh=0.5 -a concat --Oall" | tee $fldr/melodic.cmd
    . $fldr/melodic.cmd
  done
fi


#############################
# ----- END MELODIC_CMD -----
#############################


waitIfBusy


###########################
# ----- BEGIN DUALREG -----
###########################

# DUALREG prepare
if [ $DUALREG_STG1 -eq 1 ] ; then
  echo "----- BEGIN DUALREG_STG1 -----"
  
  # do substitutions
  if [ x"$DUALREG_USE_MOVPARS_HPF" = "x" -o x"$DUALREG_USE_MOVPARS_HPF" = "xnone" ] ; then 
    DUALREG_USE_MOVPARS_HPF=dummy
  fi
  
  # where to look for input files...
  for DUALREG_INPUT_ICA_DIRNAME in $DUALREG_INPUT_ICA_DIRNAMES ; do
  
    # this applies when inputfile variable is set
    if [ x"$DUALREG_INPUT_BOLD_FILES" != "x" ] ; then
      _inputfiles="$DUALREG_INPUT_BOLD_FILES"
    # this applies when MELODIC-GUI was used
    elif [ -f $gicadir/${DUALREG_INPUT_ICA_DIRNAME}.fsf ] ; then
      echo "DUALREG : taking basic input filename from '$gicadir/${DUALREG_INPUT_ICA_DIRNAME}.fsf' (first entry therein)"
      _inputfiles=$(basename $(cat $gicadir/${DUALREG_INPUT_ICA_DIRNAME}.fsf | grep "set feat_files(1)" | cut -d "\"" -f 2)) # get inputfile basename from melodic *.fsf file... (assuming same basename for all included subjects/sessions) (!)
      _inputfiles=$(remove_ext $_inputfiles)_${DUALREG_INPUT_ICA_DIRNAME}.ica/reg_standard/filtered_func_data.nii.gz
    # this applies when MELODIC command line tool was used
    elif [ -f $gicadir/${DUALREG_INPUT_ICA_DIRNAME}.gica/input.files ] ; then
      echo "DUALREG : taking basic input filename from '${DUALREG_INPUT_ICA_DIRNAME}.gica/input.files' (first entry therein)"
      _inputfiles=$(basename $(head -n 1 $gicadir/${DUALREG_INPUT_ICA_DIRNAME}.gica/input.files)) # get inputfile basename from melodic input-file list...(assuming same basename for all included subjects/sessions) (!)
    else
      echo "DUALREG : ERROR : no input files defined - exiting..." ; exit 1
    fi
    
    # check inputfiles
    for _inputfile in $_inputfiles ; do
      inputfiles="" ; inputfile="" ; err=0
      for subj in $DUALREG_INCLUDED_SUBJECTS ; do
        for sess in $DUALREG_INCLUDED_SESSIONS ; do        

          inputfile=$subjdir/$subj/$sess/bold/${_inputfile}
                  
          if [ $(_imtest $inputfile) -eq 0 ] ; then echo "DUALREG : subj $subj , sess $sess : ERROR : standard-space registered input file '$inputfile' not found - continuing..." ; err=1 ; continue ; fi
          
          #if [ `echo "$inputfile"|wc -w` -gt 1 ] ; then 
            #echo "DUALREG : subj $subj , sess $sess : WARNING : more than one standard-space registered input file detected:"
            #echo "DUALREG : subj $subj , sess $sess :           '$inputfile'"
            #inputfile=`echo $inputfile | row2col | tail -n 1`
            #echo "DUALREG : subj $subj , sess $sess :           taking the latest one:"
            #echo "DUALREG : subj $subj , sess $sess :           '$inputfile'"
          #fi 
      
          inputfiles=$inputfiles" "$inputfile
        done # end sess
      done # end subj
      if [ $err -eq 1 ] ; then echo "DUALREG : An ERROR has occured. Exiting..." ; exit 1 ; fi
    done # end _inputfile
    # end check

    # gather input-files    
    for _inputfile in $_inputfiles ; do
      inputfiles="" ; inputfile="" 
      for subj in $DUALREG_INCLUDED_SUBJECTS ; do
        for sess in $DUALREG_INCLUDED_SESSIONS ; do
          inputfile=$subjdir/$subj/$sess/bold/${_inputfile}
          echo "DUALREG : subj $subj , sess $sess : adding standard-space registered input file '$inputfile'"
          inputfiles=$inputfiles" "$inputfile        
        done
      done
    
      # check if number of rows in design file and number of input-files match
      if [ ! -f $glmdir_dr/designs ] ; then echo "DUALREG : ERROR : file '$glmdir_dr/designs' not found - exiting..." ; exit 1 ; fi
      if [ -z "$(cat $glmdir_dr/designs)" ] ; then echo "DUALREG : ERROR : no designs specified in file '$glmdir_dr/designs' - exiting..." ; exit 1 ; fi
      dr_glm_names=$(cat $glmdir_dr/designs)
      for dr_glm_name in $dr_glm_names ; do
        n_files=$(echo $inputfiles | wc -w)
        n_rows=$(cat $glmdir_dr/$dr_glm_name/design.mat | grep NumPoints | cut -f 2)
        if [ $n_files -eq $n_rows ] ; then
          echo "DUALREG : number of input-files matches number of rows in design matrix '$glmdir_dr/$dr_glm_name/design.mat' ($n_rows entries)."
        else
          echo "DUALREG : ERROR : number of input-files ($n_files) does NOT match number of rows in design matrix $glmdir_dr/$dr_glm_name/design.mat ($n_rows entries) !"
          echo "Exiting."
          exit
        fi
      done
      
      # execute...
      for IC_fname in $DUALREG_IC_FILENAMES ; do
        ICfile=$gicadir/${DUALREG_INPUT_ICA_DIRNAME}.gica/groupmelodic.ica/${IC_fname}
        dr_outdir=$dregdir/${DUALREG_OUTDIR_PREFIX}__${DUALREG_INPUT_ICA_DIRNAME}__$(remove_ext $IC_fname)__$(basename $(remove_ext $inputfile))
        
        # check if IC file exitst
        if [ $(_imtest $ICfile) -eq 0 ] ; then echo "DUALREG : WARNING : group-level IC volume '$ICfile' not found - continuing loop..." ; continue ; fi
        #if [ $(_imtest $ICfile) -eq 0 ] ; then echo "DUALREG : ERROR : group-level IC volume '$ICfile' not found - exiting..." ; exit 1 ; fi
        
        # check if size / resolution matches
        set +e
        fslmeants -i $ICfile -m $(echo $inputfiles | row2col | head -n 1) &>/dev/null
        if [ $? -gt 0 ] ; then 
          echo "DUALREG : WARNING : size / resolution does not match btw. '$ICfile' and '$(echo $inputfiles | row2col | head -n 1)' (ignore error above) - continuing loop..."
          set -e
          continue
        fi
        set -e
        
        # cleanup previous run
        if [ -d $dr_outdir ] ; then
          if [ $DUALREG_DELETE_PREV_RUNS -eq 1 ] ; then
            echo "DUALREG : WARNING : deleting previous run in '$dr_outdir' in 5 seconds as requested - you may want to abort with CTRL-C..." ; sleep 5        
            rm -rf $dr_outdir/scripts+logs
            rm -rf $dr_outdir/stats
            rm -f $dr_outdir/*
          else
            read -p "DUALREG : '$dr_outdir' already exists. Press any key to continue or CTRL-C to abort..."
          fi
        fi
        
        # create output dir  
        mkdir -p $dr_outdir
        
        # save info-files
        echo $DUALREG_INCLUDED_SUBJECTS | row2col > $dr_outdir/subjects
        echo $DUALREG_INCLUDED_SESSIONS | row2col > $dr_outdir/sessions
        echo $inputfiles | row2col > $dr_outdir/inputfiles
        
        ## creating link to logdir
        #ln -sfn ../$(basename $grpdir)/$(basename $dregdir)/$DUALREG_INPUT_ICA_DIRNAME/scripts+logs $logdir/dualreg_${DUALREG_INPUT_ICA_DIRNAME}_scripts+logs # create link to dualreg-logfiles in log-directory
        
        # check if we have acquisition parameters
        defineBOLDparams $subjdir/config_acqparams_bold # assuming that TR is the same for all datasets
        
        # executing dualreg...
        echo "DUALREG : executing dualreg script on group-level ICs in '$ICfile' - writing to folder '$dr_outdir'..."
        
        if [ "$DUALREG_USE_MOVPARS_HPF" = "dummy" ] ; then 
          usemov=0
        else 
          usemov=1
          echo "DUALREG : Motion parameters will be used in dual-regressions (hpf-cutoff (s): ${DUALREG_USE_MOVPARS_HPF})."        
        fi
        echo ""
        cmd="$scriptdir/dualreg.sh $ICfile 1 dummy.mat dummy.con dummy.grp dummy.randcmd $DUALREG_NPERM $dr_outdir 0 dummy dummy 1 0 0 $(cat $dr_outdir/inputfiles)" ; echo "$cmd" > $dr_outdir/dualreg_prep.cmd
        $cmd ; waitIfBusy
        
        echo ""
        cmd="$scriptdir/dualreg.sh $ICfile 1 dummy.mat dummy.con dummy.grp dummy.randcmd $DUALREG_NPERM $dr_outdir $usemov $TR_bold $DUALREG_USE_MOVPARS_HPF 0 1 0 $(cat $dr_outdir/inputfiles)" ; echo "$cmd" >> $dr_outdir/dualreg_prep.cmd
        $cmd ; waitIfBusy
        echo ""
      done  # end IC_fname
      echo ""
    done # end _inputfile
    echo ""
  done # end DUALREG_INPUT_ICA_DIRNAME
fi

waitIfBusy

# DUALREG execute randomise call
if [ $DUALREG_STG2 -eq 1 ] ; then
  echo "----- BEGIN DUALREG_STG2 -----"
  for DUALREG_INPUT_ICA_DIRNAME in $DUALREG_INPUT_ICA_DIRNAMES ; do
  
    # this applies when inputfile variable is set
    if [ x"$DUALREG_INPUT_BOLD_FILES" != "x" ] ; then
      _inputfiles="$DUALREG_INPUT_BOLD_FILES"
    # this applies when MELODIC-GUI was used
    elif [ -f $gicadir/${DUALREG_INPUT_ICA_DIRNAME}.fsf ] ; then
      echo "DUALREG : taking basic input filename from '$gicadir/${DUALREG_INPUT_ICA_DIRNAME}.fsf' (first entry therein)"
      _inputfiles=$(basename $(cat $gicadir/${DUALREG_INPUT_ICA_DIRNAME}.fsf | grep "set feat_files(1)" | cut -d "\"" -f 2)) # get inputfile basename from melodic *.fsf file... (assuming same basename for all included subjects/sessions) (!)
      _inputfiles=$(remove_ext $_inputfiles)_${DUALREG_INPUT_ICA_DIRNAME}.ica/reg_standard/filtered_func_data.nii.gz
    # this applies when MELODIC command line tool was used
    elif [ -f $gicadir/${DUALREG_INPUT_ICA_DIRNAME}.gica/input.files ] ; then
      echo "DUALREG : taking basic input filename from '${DUALREG_INPUT_ICA_DIRNAME}.gica/input.files' (first entry therein)"
      _inputfiles=$(basename $(head -n 1 $gicadir/${DUALREG_INPUT_ICA_DIRNAME}.gica/input.files)) # get inputfile basename from melodic input-file list...(assuming same basename for all included subjects/sessions) (!)
    else
      echo "DUALREG : ERROR : no input files defined - exiting..." ; exit 1
    fi
  
    for _inputfile in $_inputfiles ; do
      for IC_fname in $DUALREG_IC_FILENAMES ; do
  #      dr_outdir=$dregdir/${DUALREG_OUTDIR_PREFIX}_${DUALREG_INPUT_ICA_DIRNAME}_$(remove_ext $IC_fname)
        dr_outdir=$dregdir/${DUALREG_OUTDIR_PREFIX}__${DUALREG_INPUT_ICA_DIRNAME}__$(remove_ext $IC_fname)__$(basename $(remove_ext $_inputfile))
        ICfile=$gicadir/${DUALREG_INPUT_ICA_DIRNAME}.gica/groupmelodic.ica/${IC_fname}
        
        #if [ ! -d $dr_outdir ] ; then echo "DUALREG : ERROR : output directory '$dr_outdir' not found - exiting..." ; exit 1 ; fi
        if [ ! -d $dr_outdir ] ; then echo "DUALREG : WARNING : output directory '$dr_outdir' not found - continuing loop..." ; continue ; fi
        if [ ! -f $dr_outdir/inputfiles ] ; then echo "DUALREG : ERROR : inputfiles textfile not found, you must run stage1 first - exiting..." ; exit 1 ; fi
        if [ $(_imtest $ICfile) -eq 0 ] ; then echo "DUALREG : ERROR : group-level IC volume '$ICfile' not found - exiting..." ; exit 1 ; fi

        echo "DUALREG : using output-directory '$dr_outdir'..."
        
        # check if number of rows in design file and number of input-files 
        if [ ! -f $glmdir_dr/designs ] ; then echo "DUALREG : ERROR : file '$glmdir_dr/designs' not found - exiting..." ; exit 1 ; fi
        if [ -z "$(cat $glmdir_dr/designs)" ] ; then echo "DUALREG : ERROR : no designs specified in file '$glmdir_dr/designs' - exiting..." ; exit 1 ; fi
        dr_glm_names=$(cat $glmdir_dr/designs)
        for dr_glm_name in $dr_glm_names ; do
          n_files=$(echo $(cat $dr_outdir/inputfiles) | wc -w)
          n_rows=$(cat $glmdir_dr/$dr_glm_name/design.mat | grep NumPoints | cut -f 2)
          if [ $n_files -eq $n_rows ] ; then
            echo "DUALREG : number of input-files matches number of rows in design matrix '$glmdir_dr/$dr_glm_name/design.mat' ($n_rows entries)."
          else
            echo "DUALREG : ERROR : number of input-files ($n_files) does NOT match number of rows in design matrix $glmdir_dr/$dr_glm_name/design.mat ($n_rows entries) !"
            echo "Exiting."
            exit
          fi
        done
        
        # delete previous randomise[_parallel] runs
        for dr_glm_name in $dr_glm_names ; do
          if [ -d $dr_outdir/stats/$dr_glm_name ] ; then
            if [ $DUALREG_DELETE_PREV_RUNS -eq 1 ] ; then            
                if [ ! -z $dr_glm_name ] ; then
                  echo "DUALREG : WARNING : deleting stats-folder '$dr_outdir/stats/$dr_glm_name' in 5 seconds as requested - you may want to abort with CTRL-C..." ; sleep 5
                  rm -r $dr_outdir/stats/$dr_glm_name
                fi
            else
              read -p "DUALREG : stats-folder '$dr_outdir/stats/$dr_glm_name'  already exists. Press any key to continue or CTRL-C to abort..."
            fi
          fi
        done
        
        # executing dualreg...
        if [ $RANDOMISE_PARALLEL -eq 1 ] ; then
          RANDCMD="randomise_parallel"
          echo "DUALREG : using the '$RANDCMD' command."
          echo "          - note that '$RANDCMD' will fail if i) /bin/sh does not point to /bin/bash and ii) you specify more permutations than uniquely possible."
        else
          RANDCMD="randomise"
          echo "DUALREG : using the '$RANDCMD' command."
        fi
        for dr_glm_name in $dr_glm_names ; do
          echo "DUALREG : copying GLM design '$dr_glm_name' to '$dr_outdir/stats'"
          mkdir -p $dr_outdir/stats ; cp -r $glmdir_dr/$dr_glm_name $dr_outdir/stats/ ; imcp $ICfile $dr_outdir/stats/
          echo "DUALREG : calling '$RANDCMD' for folder '$dr_outdir/stats/$dr_glm_name' ($DUALREG_NPERM permutations)."
          cmd="${scriptdir}/dualreg.sh $ICfile 1 $glmdir_dr/$dr_glm_name/design.mat $glmdir_dr/$dr_glm_name/design.con $glmdir_dr/$dr_glm_name/design.grp $RANDCMD $DUALREG_NPERM $dr_outdir 0 dummy dummy 0 0 1 $(cat $dr_outdir/inputfiles)" ; echo "$cmd" > $dr_outdir/dualreg_rand_${dr_glm_name}.cmd
          #$cmd ; waitIfBusy0 # CAVE: waiting here is necessary, otherwise the drD script is deleted before its execution is finished... (!)
          $cmd ; waitIfBusy # CAVE: waiting here is necessary, otherwise the drD script is deleted before its execution is finished... (!)
        done
        echo ""
      done # end IC_fname
    done # end _inputfile
  done # DUALREG_INPUT_ICA_DIRNAME
fi

#########################
# ----- END DUALREG -----
#########################

waitIfBusy

###########################
# ----- BEGIN FSLNETS -----
###########################

# resampling to fsaverage space
if [ $FSLNETS_STG1 -eq 1 ] ; then

  FSLNETS_GOODCOMPONENTS=\'$FSLNETS_GOODCOMPONENTS\'

  for dr in $FSLNETS_DREGDIRS ; do
    
    fldr=$fslnetsdir/${FSLNETS_OUTIDR_PREFIX}_${dr}
    groupIC=$(ls $dregdir/$dr/stats/*.nii.gz) # define group IC map
    
    mkdir -p $fldr

    echo "FSLNETS: copying GLM designs to '$fldr'"
    cat $glmdir_fslnets/designs | xargs -I{} cp -r $glmdir_fslnets/{} $fldr ; cp $glmdir_fslnets/designs $fldr
    
    for design in $(cat $glmdir_fslnets/designs) ; do
      echo "FSLNETS: executing FSLNETS..."
      echo "$scriptdir/start_FSLNets.sh $tmpltdir/template_nets_examples.m $dregdir/$dr $groupIC $FSLNETS_GOODCOMPONENTS $glmdir_fslnets/$design $FSLNETS_NPERM $fldr/$design" > $fldr/$design/fslnets.cmd  
      cat $fldr/$design/fslnets.cmd ; source $fldr/$design/fslnets.cmd 
      echo ""
      echo ""
    done
    
  done  
fi

#########################
# ----- END FSLNETS -----
#########################


waitIfBusy

finishdate=$(date)
finishdate_sec=$(date +"%s")
echo ""
echo "started      : $startdate"
echo "finished     : $finishdate"

cd $wd
exit
