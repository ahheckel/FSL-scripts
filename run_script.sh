#!/bin/bash

trap 'echo "$0 : An ERROR has occured."' ERR # don't exit on trap (!)

# exit on error
set -e

# echo date
date

# source environment variables and functions
source ./globalfuncs
source ./globalvars

# define current working directory
wd=`pwd`

# ----- create 1st level subject- and session files -----

if [ "x$FIRSTLEV_SUBJECTS" != "x" -a "x$FIRSTLEV_SESSIONS_FUNC" != "x" -a "x$FIRSTLEV_SESSIONS_STRUC" != "x" ] ; then
  echo "creating subjects file..."
  
  errflag=0
  for i in $FIRSTLEV_SUBJECTS ; do if [ ! -d ${subjdir}/$i ] ; then errflag=1 ; echo "ERROR: '${subjdir}/$i' does not exist!" ; fi ; done
  if [ $errflag -eq 1 ] ; then echo "...exiting." ; exit ; fi
  
  echo $FIRSTLEV_SUBJECTS | row2col > ${subjdir}/subjects
  cat -n ${subjdir}/subjects
  for subj in `cat ${subjdir}/subjects` ; do
    echo "creating functional session file for subject '$subj': [$FIRSTLEV_SESSIONS_FUNC]"
    echo $FIRSTLEV_SESSIONS_FUNC | row2col > ${subjdir}/$subj/sessions_func
    echo "creating structural session file for subject '$subj': [$FIRSTLEV_SESSIONS_STRUC]"
    echo $FIRSTLEV_SESSIONS_STRUC | row2col > ${subjdir}/$subj/sessions_struc
  done
fi

# ----- CHECKS -----

# are all progs installed ?
progs="$FSL_DIR/bin/tbss_x $FSL_DIR/bin/swap_voxelwise $FSL_DIR/bin/swap_subjectwise $FREESURFER_HOME/bin/trac-all $FSL_DIR/etc/flirtsch/b02b0.cnf $FSL_DIR/bin/topup $FSL_DIR/bin/applytopup"
for prog in $progs ; do
  if [ ! -f $prog ] ; then echo "ERROR : '$prog' is not installed. Exiting." ; exit ; fi
done
if [ x$(which octave) = "x" ] ; then echo "ERROR : OCTAVE does not seem to be installed on your system ! Exiting..." ; exit ; fi

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
      files=`find ./?* -maxdepth 1 -type d | sort | cut -d / -f 2`
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
      read -p "Session File for structural processing not present in ${subjdir}/${subj}. You will need to create that file. Exiting..." ; exit ; 
    fi
    if [ ! -f ${subjdir}/${subj}/sessions_func ] ; then
      read -p "Session File for functional processing not present in ${subjdir}/${subj}. You will need to create that file. Exiting..." ; exit ; 
    fi
  done

  # are bet info-files present ?
  if [ ! -f ${subjdir}/config_bet_lowb ] ; then
    read -p "Bet info file for the diffusion images not present in ${subjdir}. Press Key to create the default template."
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_struc` ; do echo "$(subjsess) $BETLOWB_INFO" | tee -a $subjdir/config_bet_lowb ; done ; done
  fi
  if [ ! -f ${subjdir}/config_bet_magn ] ; then
    read -p "Bet info file for the magnitude images not present in ${subjdir}. Press Key to create the default template."
    for subj in `cat $subjdir/subjects`; do for sess in `cat $subjdir/$subj/sessions_func` ; do echo "$(subjsess) $BETMAGN_INFO" | tee -a $subjdir/config_bet_magn ; done ; done
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
  
  # is registration mapping file present ? 
  if [ ! -f ${subjdir}/config_func2highres.reg ] ; then
    echo "Registration mapping between functionals and t1 structural not found. You may need to create that file..."
    subj=`head -n 1 $subjdir/subjects`
    if [ $(find $subjdir/$subj/ -maxdepth 1 -type d | wc -l) -eq 1 ] ; then
      read -p "No subdirectories in $subjdir/$subj detected - assuming single session design. Press Key to create default func->highres mapping for single session designs..."
      for i in $(cat $subjdir/subjects) ; do
        echo "$i ." >> $subjdir/config_func2highres.reg
      done
      echo "done."
    fi
    subj=""
  fi
  
  # are template files present?
  if [ ! -f ${subjdir}/template_tracula.rc ] ; then
    read -p "TRACULA template file not found. You may need to create that file..."  
  fi
  if [ ! -f ${subjdir}/template_preprocBOLD.fsf ] ; then
    read -p "FEAT template file for BOLD preprocessing not found. You may need to create that file..."  
  fi
  if [ ! -f ${subjdir}/template_unwarpDWI.fsf ] ; then
    read -p "FEAT template file for DWI unwarping not found. You may need to create that file..."  
  fi
  if [ ! -f ${subjdir}/template_makeXfmMatrix.m ] ; then 
    read -p "WARNING: OCTAVE file 'template_makeXfmMatrix.m' not found. You will need that file for TOPUP-related b-vector correction. Press key to continue..."
  fi
  if [ ! -f ${grpdir}/template_ICA.fsf ] ; then
    read -p "WARNING: MELODIC template file not found. You may need to create that file..." 
  fi
fi

# all subjects registered in infofiles ?
errflag=0
for infofile in config_bet_magn config_bet_lowb config_bet_struc0 config_bet_struc1 config_unwarp_dwi config_unwarp_bold config_func2highres.reg ; do
  for subj in `cat $subjdir/subjects` ; do
      line=$(cat $subjdir/$infofile | grep $subj || true)
      if [ "x$line" = "x" ] ; then errflag=1 ; echo "WARNING : '$infofile' : enty for subject '$subj' not found ! This may or may not be a problem depending on your setup." ; fi
  done
done
if [ $errflag -eq 1 ] ; then echo "***CHECK*** (sleeping 2 seconds)..." ; sleep 2 ; fi

# list files for each subject and session
checklist=""
if [ ! "x$pttrn_diffs" = "x" ] ; then checklist=$checklist" "$pttrn_diffs; fi
if [ ! "x$pttrn_bvals" = "x" ] ; then checklist=$checklist" "$pttrn_bvals; fi
if [ ! "x$pttrn_bvecs" = "x" ] ; then checklist=$checklist" "$pttrn_bvecs; fi
if [ ! "x$pttrn_strucs" = "x" ] ; then checklist=$checklist" "$pttrn_strucs; fi
if [ ! "x$pttrn_fmaps" = "x" ] ; then checklist=$checklist" "$pttrn_fmaps; fi
if [ ! "x$pttrn_bolds" = "x" ] ; then checklist=$checklist" "$pttrn_bolds; fi
# header line
printf "                      DWI  BVAL BVEC STRC FMAP BOLD \n"
# cycle through...
n=1
for subj in `cat $subjdir/subjects` ; do
  for sess in `cat $subjdir/$subj/sessions_* | sort | uniq` ; do
    out=""
    for i in $checklist ; do 
      out=$out"    "$(ls $subjdir/$subj/$sess/$i 2>/dev/null | wc -l)
    done
    printf "%3i subj %s , sess %s :%s \n" $n $subj $sess "$out"
    n=$[$n+1]
  done
done
echo "***CHECK*** (sleeping 2 seconds)..."
sleep 2

# dos2unix bval/bvec textfiles (just in case...)
echo "Ensuring UNIX line endings in bval-/bvec textfiles..."
for subj in `cat $subjdir/subjects` ; do
  for sess in `cat $subjdir/$subj/sessions_struc` ; do
    dwi_txtfiles=""
    if [ x${pttrn_bvalsplus} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$subjdir/$subj/$sess/$pttrn_bvalsplus ; fi
    if [ x${pttrn_bvalsminus} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$subjdir/$subj/$sess/$pttrn_bvalsminus ; fi
    if [ x${pttrn_bvecsplus} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$subjdir/$subj/$sess/$pttrn_bvecsplus ; fi
    if [ x${pttrn_bvecsminus} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$subjdir/$subj/$sess/$pttrn_bvecsminus ; fi
    if [ x${pttrn_bvals} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$subjdir/$subj/$sess/$pttrn_bvals ; fi
    if [ x${pttrn_bvecs} != "x" ] ; then dwi_txtfiles=$dwi_txtfiles" "$subjdir/$subj/$sess/$pttrn_bvecs ; fi
    dwi_txtfiles=$(echo $dwi_txtfiles| row2col | sort | uniq)
    for i in $dwi_txtfiles ; do 
      #echo "    $i"
      dos2unix -q $i
    done
  done
done

# check bvals, bvecs and diff. files for consistent number of entries
if [ $CHECK_CONSISTENCY_DIFFS = 1 ] ; then
  for subj in `cat $subjdir/subjects` ; do
    for sess in `cat $subjdir/$subj/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/
      echo "subj $subj , sess $sess : "
      checkConsistency "$fldr/$pttrn_diffs" "$fldr/$pttrn_bvals" "$fldr/$pttrn_bvecs"
    done
  done
fi

# make log directory for fsl_sub
mkdir -p $logdir

# make temp directory
mkdir -p $tmpdir

# make directory for 2nd level GLMs
mkdir -p $glmdir_tbss
mkdir -p $glmdir_vbm

# create freesurfer subjects dir
for subj in `cat $subjdir/subjects`; do 
  for sess in `cat $subjdir/$subj/sessions_struc` ; do
    mkdir -p $FS_sessdir/$(subjsess)
  done   
done

# create freesurfer session dir
for subj in `cat $subjdir/subjects`; do 
  for sess in `cat $subjdir/$subj/sessions_func` ; do
    mkdir -p $FS_subjdir/$(subjsess)
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
BOLD_ESTIMATE_NUISANCE=bold.nii
confounds="GB CSF WM MC"

for subj in `cat subjects` ; do
  for sess in `cat ${subj}/sessions_func` ; do
      
    #featdir=$subjdir/$subj/$sess/bold/$(dirname `readlink $subjdir/$subj/$sess/bold/$BOLD_ESTIMATE_NUISANCE`)
    fldr=$subjdir/$subj/$sess/bold/filt/$(remove_ext $BOLD_ESTIMATE_NUISANCE)

    if [ ! -f $subjdir/$subj/$sess/bold/$BOLD_ESTIMATE_NUISANCE ] ; then 
      echo "'$subjdir/$subj/$sess/bold/$BOLD_ESTIMATE_NUISANCE' not found - exiting..." ; exit
    fi
    #if [ ! -f $featdir/mc/prefiltered_func_data_mcf.par ] ; then
     # echo "motion parameter file '$featdir/mc/prefiltered_func_data_mcf.par' not found - exiting..." ; exit
    #fi

    echo "BOLD : subj $subj , sess $sess : creating directory '$fldr'"
    mkdir -p $fldr
    
    #echo "BOLD : subj $subj , sess $sess : copying motion parameter file..."
    #cp -v $featdir/mc/prefiltered_func_data_mcf.par $fldr/mc.par
    
    echo "BOLD : subj $subj , sess $sess : linking bold 4D..."
    ln -sfv ../../$BOLD_ESTIMATE_NUISANCE $fldr/bold.nii.gz
        
    echo "BOLD : subj $subj , sess $sess : linking T1..."
    sess_t1=`getT1Sess4FuncReg $subjdir/config_func2highres.reg $subj $sess`
    t1=$(remove_ext `basename $(ls $subjdir/$subj/$sess_t1/vbm/$BOLD_PTTRN_HIGHRES_BRAIN)`)
    if [ ! -f  $subjdir/$subj/$sess_t1/vbm/${t1}.nii.gz ] ; then echo "BOLD : $subj , $sess : '$subj/$sess/vbm/${t1}.nii.gz' does not exist - exiting..." ; exit ; fi
    ln -sfv ../../../../$sess_t1/vbm/${t1}.nii.gz $fldr
    
    npts=`countVols $fldr/bold.nii.gz` ; mid_pos=$(echo "scale=0 ; $npts / 2" | bc) # equals: floor($npts / 2)
    echo "BOLD : subj $subj , sess $sess : executing extraction of confounds from '$fldr/bold' (using pos. $mid_pos / $npts as reference for anatomical alignment)..."
    echo "$scriptdir/extractConfoundsFromNativeFuncs.sh $fldr/bold $fldr/albold $mid_pos $fldr/$t1" | tee $fldr/filt.cmd
    fsl_sub -t $fldr/filt.cmd
    
  done
done

#for subj in `cat subjects` ; do
  #for sess in `cat ${subj}/sessions_func` ; do
    #echo "BOLD : subj $subj , sess $sess : creating confounds matrix [${confounds}]."
    #fldr=$subjdir/$subj/$sess/bold/filt/$(remove_ext $BOLD_ESTIMATE_NUISANCE)
    #cd $fldr
    #paste -d "  " ${confounds} > confounds
    #cd $subjdir
  #done
#done

for subj in `cat subjects` ; do
  for sess in `cat ${subj}/sessions_func` ; do
    
    fldr=$subjdir/$subj/$sess/bold/filt/$(remove_ext $BOLD_ESTIMATE_NUISANCE)
   
    # gather confounds
    conf_list=""
    for confound in $confounds ; do
      if [ $confound = "CSF" ] ; then 
        conf_list=$conf_list" "$fldr/tc_CSF_mask
      fi
      if [ $confound = "WB" ] ; then 
        conf_list=$conf_list" "$fldr/tc_WB_mask 	
      fi
      if [ $confound = "WM" ] ; then 
        conf_list=$conf_list" "$fldr/tc_WM_mask 
      fi
      if [ $confound = "MotionPar" ] ; then 
        conf_list=$conf_list" "$fldr/mc.par 
      fi
    done

    echo "BOLD : subj $subj , sess $sess : creating confounds matrix including: $conf_list"

    # do confounds exist ?
    for file in $conf_list ; do
      if [ ! -f $file ] ; then
      echo "ERROR: $file not found." ; errflag=1
      fi
    done
    if [ $errflag -eq 1 ] ; then exit ; fi

    # forge confounds matrix
    suffix=$(echo $confounds | sed "s|" "|_|g")
    paste -d "  " $conf_list > $fldr/confound_$suffix
    
  done
done

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
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_func` ; do   
      fldr=${subj}/${sess}/fm
      
      # create fieldmap directory
      mkdir -p $fldr
   
      # find magnitude
      fm_m=`ls ${subj}/${sess}/${pttrn_fmaps} | sed -n 1p` # first in listing is magnitude (second is phase-difference volume) (!)
      imcp $fm_m $fldr
      
      # split magnitude
      echo "FIELDMAP : subj $subj , sess $sess : extracting magnitude image ${fm_m}..."
      fslroi $fm_m ${fldr}/magn 0 1 # extract first of the two magnitude images, do not fsl_sub (!)

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
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_func` ; do
      fldr=${subj}/${sess}/fm

      # get bet threshold
      f=`getBetThres ${subjdir}/config_bet_magn $subj $sess`

      # bet, if necessary
      if [ $f = "mod" ] ; then
        if [ ! -f ${fldr}/magn_brain_${f}.nii.gz -o ! -f ${fldr}/magn_brain_${f}_mask.nii.gz ] ; then
          echo "FIELDMAP : subj $subj , sess $sess : externally modified volume (magn_brain_${f}.nii.gz) & mask (magn_brain_${f}_mask.nii.gz) not found - exiting..." ; exit          
        fi
      else
        echo "FIELDMAP : subj $subj , sess $sess : betted magnitude image with fi=${f}..."
        bet ${fldr}/magn ${fldr}/magn_brain_${f} -m -f $f
      fi
          
      # find phase image
      fm_p=`ls ${subj}/${sess}/${pttrn_fmaps}  | tail -n 1` # last in list is phase image, check pattern (!)
      
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
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
    
      if [ "x$pttrn_diffsplus" = "x" -o "x$pttrn_diffsminus" = "x" -o "x$pttrn_bvalsplus" = "x" -o "x$pttrn_bvalsminus" = "x" -o "x$pttrn_bvecsplus" = "x" -o "x$pttrn_bvecsminus" = "x" ] ; then
        echo "TOPUP : subj $subj , sess $sess : ERROR : file search pattern for blipUp/blipDown DWIs not set..."
        continue
      fi
      
      fldr=${subjdir}/${subj}/${sess}/topup
      mkdir -p $fldr
      
      # display info
      echo "TOPUP : subj $subj , sess $sess : preparing TOPUP... "
      
      # are the +- diffusion files in equal number ?
      n_plus=`ls $subj/$sess/$pttrn_diffsplus | wc -l`
      n_minus=`ls $subj/$sess/$pttrn_diffsminus | wc -l`
      if [ ! $n_plus -eq $n_minus ] ; then 
        echo "TOPUP : subj $subj , sess $sess : ERROR : number of +blips diff. files ($n_plus) != number of -blips diff. files ($n_minus) - continuing loop..."
        continue
      elif [ $n_plus -eq 0 -a $n_minus -eq 0 ] ; then
        echo "TOPUP : subj $subj , sess $sess : ERROR : no blip-up/down diffusion files found for TOPUP (+/- must be part of the filename) - continuing loop..."
        continue
      fi
                        
      # count +/- bvec/bval-files
      ls $subjdir/$subj/$sess/$pttrn_bvecsplus > $fldr/bvec+.files
      ls $subjdir/$subj/$sess/$pttrn_bvecsminus > $fldr/bvec-.files
      cat $fldr/bvec-.files $fldr/bvec+.files > $fldr/bvec.files
      ls $subjdir/$subj/$sess/$pttrn_bvalsplus > $fldr/bval+.files
      ls $subjdir/$subj/$sess/$pttrn_bvalsminus > $fldr/bval-.files
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
      concat_bvals $subj/$sess/"$pttrn_bvalsminus" $fldr/bvalsminus_concat.txt
      concat_bvals $subj/$sess/"$pttrn_bvalsplus" $fldr/bvalsplus_concat.txt 
      concat_bvecs $subj/$sess/"$pttrn_bvecsminus" $fldr/bvecsminus_concat.txt
      concat_bvecs $subj/$sess/"$pttrn_bvecsplus" $fldr/bvecsplus_concat.txt 

      nbvalsplus=$(wc -w $fldr/bvalsplus_concat.txt | cut -d " " -f 1)
      nbvalsminus=$(wc -w $fldr/bvalsminus_concat.txt | cut -d " " -f 1)
      nbvecsplus=$(wc -w $fldr/bvecsplus_concat.txt | cut -d " " -f 1)
      nbvecsminus=$(wc -w $fldr/bvecsplus_concat.txt | cut -d " " -f 1)      
     
      # check number of entries in concatenated bvals/bvecs files
      n_entries=`countVols $subj/$sess/"$pttrn_diffsplus"` 
      if [ $nbvalsplus = $nbvalsminus -a $nbvalsplus = $n_entries -a $nbvecsplus = `echo "3*$n_entries" | bc` -a $nbvecsplus = $nbvecsminus ] ; then
        echo "TOPUP : subj $subj , sess $sess : number of entries in bvals- and bvecs files consistent ($n_entries entries)."
      else
        echo "TOPUP : subj $subj , sess $sess : ERROR : number of entries in bvals- and bvecs files NOT consistent - continuing loop..."
        echo "(diffs+: $n_entries ; bvals+: $nbvalsplus ; bvals-: $nbvalsminus ; bvecs+: $nbvecsplus /3 ; bvecs-: $nbvecsminus /3)"
        continue
      fi
      
      # check if +/- bval entries are the same
      i=1
      for bval in `cat $fldr/bvalsplus_concat.txt` ; do
        if [ $bval != $(cat $fldr/bvalsminus_concat.txt | cut -d " " -f $i)  ] ; then 
          echo "TOPUP : subj $subj , sess $sess : ERROR : +bval entries do not match -bval entries (they should have the same values !) - exiting..."
          exit
        fi        
        i=$[$i+1]
      done

      # creating index file for TOPUP
      echo "TOPUP : subj $subj , sess $sess : creating index file for TOPUP..."      
      rm -f $fldr/$(subjsess)_acqparam.txt ; rm -f $fldr/$(subjsess)_acqparam_inv.txt ; rm -f $fldr/diff.files # clean-up previous runs...
      
      diffsminus=`ls ${subjdir}/${subj}/${sess}/${pttrn_diffsminus}`
      for file in $diffsminus ; do
        nvol=`fslinfo $file | grep ^dim4 | awk '{print $2}'`
        echo "$file n:${nvol}" | tee -a $fldr/diff.files
        for i in `seq 1 $nvol`; do
          echo "0 -1 0 $readout_diff" >> $fldr/$(subjsess)_acqparam.txt
          echo "0 1 0 $readout_diff" >> $fldr/$(subjsess)_acqparam_inv.txt
        done
      done
      
      diffsplus=`ls ${subjdir}/${subj}/${sess}/${pttrn_diffsplus}`
      for file in $diffsplus ; do
        nvol=`fslinfo $file | grep ^dim4 | awk '{print $2}'`
        echo "$file n:${nvol}" | tee -a $fldr/diff.files
        for i in `seq 1 $nvol`; do
          echo "0 1 0 $readout_diff" >> $fldr/$(subjsess)_acqparam.txt
          echo "0 -1 0 $readout_diff" >> $fldr/$(subjsess)_acqparam_inv.txt
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
                $scriptdir/eddy_correct.sh $dwifile $fldr/ec_diffs_merged_${i} $b0img mutualinfo trilinear" > $fldr/topup_ec_${i}.cmd
          
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
      echo "TOPUP : subj $subj , sess $sess : concatenate bvals... "
      echo "`cat $fldr/bvalsminus_concat.txt`" "`cat $fldr/bvalsplus_concat.txt`" > $fldr/bvals_concat.txt
       
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
        echo "TOPUP : subj $subj , sess $sess : found B0 images in merged diff. at pos. $b0idx (val:${min}) - extracting..."
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
      echo "TOPUP : subj $subj , sess $sess : merging low-B images..."
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
      echo "TOPUP : subj $subj , sess $sess : executing TOPUP on merged low-b volumes..."
      echo "fsl_sub -l $logdir -N topup_topup_$(subjsess) topup -v --imain=$fldr/$(subjsess)_lowb_merged --datain=$fldr/$(subjsess)_acqparam_lowb.txt --config=b02b0.cnf --out=$fldr/$(subjsess)_field_lowb" > $fldr/topup.cmd
      . $fldr/topup.cmd
     
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
      
      # generate commando without eddy-correction
      nplus=`ls $subj/$sess/$pttrn_diffsplus | wc -l`      
      rm -f $fldr/applytopup.cmd
      for i in `seq 1 $nplus` ; do
        j=`echo "$i + $nplus" | bc -l`

        blipdown=`ls $subjdir/$subj/$sess/$pttrn_diffsminus | sed -n ${i}p`
        blipup=`ls $subjdir/$subj/$sess/$pttrn_diffsplus | sed -n ${i}p`
        
        n=`printf %03i $i`
        echo "fsl_sub -l $logdir -N topup_applytopup_$(subjsess) applytopup --imain=$blipdown,$blipup --datain=$fldr/$(subjsess)_acqparam_lowb.txt --inindex=$i,$j --topup=$fldr/$(subjsess)_field_lowb --method=lsr --out=$fldr/${n}_topup_corr" >> $fldr/applytopup.cmd
      done
      
      # generate commando with eddy-correction
      nplus=`ls $subj/$sess/$pttrn_diffsplus | wc -l`      
      rm -f $fldr/applytopup_ec.cmd
      for i in `seq 1 $nplus` ; do
        j=`echo "$i + $nplus" | bc -l`
        
        blipdown=$fldr/ec_diffs_merged_$(printf %03i $i)
        blipup=$fldr/ec_diffs_merged_$(printf %03i $j)
        
        n=`printf %03i $i`
        echo "fsl_sub -l $logdir -N topup_applytopup_ec_$(subjsess) applytopup --imain=$blipdown,$blipup --datain=$fldr/$(subjsess)_acqparam_lowb.txt --inindex=$i,$j --topup=$fldr/$(subjsess)_field_lowb --method=lsr --out=$fldr/${n}_topup_corr_ec" >> $fldr/applytopup_ec.cmd
      done
      
      # execute...
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : applying warps to native DWIs..."
        . $fldr/applytopup.cmd
      fi
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : applying warps to eddy-corrected DWIs..."
        . $fldr/applytopup_ec.cmd
      fi
       
      waitIfBusy
      
      # merge corrected files
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : merging topup-corrected DWIs..."
        fslmerge -t $fldr/$(subjsess)_topup_corr_merged $(imglob $fldr/*_topup_corr)
      fi
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : merging topup-corrected & eddy-corrected DWIs..."
        fslmerge -t $fldr/$(subjsess)_topup_corr_ec_merged $(imglob $fldr/*_topup_corr_ec)
      fi
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
      
      # get info for current subject
      f=`getBetThres ${subjdir}/config_bet_lowb $subj $sess`

      # bet, if necessary
      if [ $f = "mod" ] ; then
        if [ ! -f $fldr/nodif_brain_${f}.nii.gz  -o ! -f $fldr/nodif_brain_${f}_mask.nii.gz ] ; then   
          echo "TOPUP: subj $subj , sess $sess : externally modified volume (nodif_brain_${f}) & mask (nodif_brain_${f}_mask) not found - exiting..." ; exit
        fi
      else      
        echo "TOPUP : subj $subj , sess $sess : betting B0 image with fi=${f} - extracting B0..."
        if [ ! -f $fldr/lowb.idx ] ; then echo "TOPUP : subj $subj , sess $sess : ERROR : low-b index file '$fldr/lowb.idx' not found - continuing loop..." ; continue ; fi
        fslroi $fldr/diffs_merged $fldr/nodif $(sed -n 1p $fldr/lowb.idx) 1
        echo "TOPUP : subj $subj , sess $sess : ...and betting B0..."
        bet $fldr/nodif $fldr/nodif_brain_${f} -m -f $f         
      fi 
      ln -sf nodif_brain_${f}.nii.gz $fldr/nodif_brain.nii.gz
      ln -sf nodif_brain_${f}_mask.nii.gz $fldr/nodif_brain_mask.nii.gz      
    
      # averaging +/- bvecs & bvals...
      #average $fldr/bvecsminus_concat.txt $fldr/bvecsplus_concat.txt > $fldr/avg_bvecs.txt
      average $fldr/bvalsminus_concat.txt $fldr/bvalsplus_concat.txt > $fldr/avg_bvals.txt
      
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
        cp $subjdir/template_makeXfmMatrix.m $fldr/makeXfmMatrix_${i}.m
        
        # define vars
        rots=`sed -n ${i}p $fldr/$(subjsess)_field_lowb_movpar.txt | cut -d " " -f 7-11` # last three entries are rotations in radians
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
      echo "TOPUP : subj $subj , sess $sess : dtifit is estimating tensor model using nodif_brain_${f}_mask..."
      
      # estimate tensor model (rotated bvecs)
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then           
        echo "TOPUP : subj $subj , sess $sess : dtifit is estimating tensor model with rotated b-vectors (no eddy-correction)..."
        fsl_sub -l $logdir -N topup_dtifit_noec_bvecrot_$(subjsess) dtifit -k $fldr/$(subjsess)_topup_corr_merged -m $fldr/nodif_brain_mask -r $fldr/avg_bvecs_topup.rot -b $fldr/avg_bvals.txt  -o $fldr/$(subjsess)_dti_topup_noec_bvecrot
      fi
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : subj $subj , sess $sess : dtifit is estimating tensor model with rotated b-vectors (incl. eddy-correction)..."
        fsl_sub -l $logdir -N topup_dtifit_ec_bvecrot_$(subjsess) dtifit -k $fldr/$(subjsess)_topup_corr_ec_merged -m $fldr/nodif_brain_mask -r $fldr/avg_bvecs_topup_ec.rot  -b $fldr/avg_bvals.txt  -o $fldr/$(subjsess)_dti_topup_ec_bvecrot
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
      fldr=$subj/$sess/fdt ; mkdir -p $fldr
      
      if [ -z $pttrn_diffs ] ; then echo "FDT : search pattern for DWI files not defined - exiting..." ; exit ; fi
      
      # merge diffs...
      echo "FDT : subj $subj , sess $sess : merging diffs..."
      ls $subj/$sess/$pttrn_diffs | tee $fldr/diff.files
      fsl_sub -l $logdir -N fdt_fslmerge_${subj} fslmerge -t $fldr/diff_merged $(cat $fldr/diff.files)      
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
      b0img=`getB0Index $subj/$sess/"$pttrn_bvals" $fldr/ec_ref.idx | cut -d " " -f 1` ; min=`getB0Index $subj/$sess/"$pttrn_bvals" $fldr/ec_ref.idx | cut -d " " -f 2`

      # eddy-correct
      echo "FDT : subj $subj , sess $sess : eddy_correct is using volume no. $b0img as B0 (val:${min})..."
      
      # creating task file for fsl_sub, the deletions are needed to avoid accumulations when sge is doing a re-run on error
      echo "rm -f $fldr/ec_diff_merged_*.nii.gz ; \
            rm -f $fldr/ec_diff_merged.ecclog ; \
            $scriptdir/eddy_correct.sh $fldr/diff_merged $fldr/ec_diff_merged $b0img mutualinfo trilinear" > $fldr/fdt_ec.cmd
      fsl_sub -l $logdir -N fdt_eddy_correct_$(subjsess) -t $fldr/fdt_ec.cmd
      
    done
  done
  
  waitIfBusy
  
  # extract b0 reference image from eddy-corrected 4D (note: you can use these for both eddy-corrected and non eddy-corrected streams, bc. these b0 images were used as reference for eddy_correct)
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/fdt
      echo "FDT : subj $subj , sess $sess : extract b0 reference image from eddy-corrected 4D..."
      fsl_sub -l $logdir -N fdt_fslroi_$(subjsess) fslroi $fldr/ec_diff_merged $fldr/nodif $(cat $fldr/ec_ref.idx) 1  
    done
  done
fi

waitIfBusy

# FDT unwarp eddy-corrected DWIs - prepare FEAT config-file
if [ $FDT_STG3 -eq 1 ] ; then
  echo "----- BEGIN FDT_STG3 -----"
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
          "FDT : WARNING : Number of volumes does not match with previous image file in the loop!" 
        fi
      fi
      _npts=$npts
      n=$[$n+1] 
      
      # define alternative example func
      if [ $FDT_UNWARP_BET_ALTEXFUNC -eq 1 ] ; then
        f=`getBetThres ${subjdir}/config_bet_lowb $subj $sess`
        bet $fldr/nodif $fldr/altExFunc_nodif_brain_${f} -f $f
        altExFunc=$fldr/altExFunc_nodif_brain_${f}
      else
        ln -sf nodif.nii.gz $fldr/altExFunc_nodif.nii.gz
        altExFunc=$fldr/altExFunc_nodif.nii.gz
      fi

      # define magnitude and fieldmap
      fmap=$subjdir/$subj/$sess/fm/fmap_rads_masked.nii.gz
      if [ ! -f $fmap ] ; then echo "FDT : subj $subj , sess $sess : WARNING : Fieldmap image '$fmap' not found !" ; fi
      fmap_magn=$subjdir/$subj/$sess/fm/magn_brain.nii.gz
      if [ ! -f $fmap_magn ] ; then echo "FDT : subj $subj , sess $sess : WARNING : Fieldmap magnitude image '$fmap_magn' not found !" ; fi
      
      # carry out substitutions
      for uw_dir in -y +y ; do
        conffile=$fldr/unwarpDWI_${uw_dir}.fsf
        
        if [ $uw_dir = "-y" ] ; then dir=y- ; fi
        if [ $uw_dir = "+y" ] ; then dir=y ; fi
              
        echo "FDT : subj $subj , sess $sess : unwarping - creating config file $conffile"
        cp template_unwarpDWI.fsf $conffile
   
        sed -i "s|set fmri(outputdir) \"X\"|set fmri(outputdir) \"$fldr/unwarpDWI_${uw_dir}\"|g" $conffile # set output dir
        sed -i "s|set fmri(tr) X|set fmri(tr) $TR_diff|g" $conffile # set TR
        sed -i "s|set fmri(npts) X|set fmri(npts) $npts|g" $conffile # set number of volumes
        sed -i "s|set fmri(dwell) X|set fmri(dwell) $EES_diff|g" $conffile # set Eff. Echo Spacing
        sed -i "s|set fmri(te) X|set fmri(te) $TE_diff|g" $conffile # set TE
        sed -i "s|set fmri(signallossthresh) X|set fmri(signallossthresh) $FDT_SIGNLOSS_THRES|g" $conffile # set signal loss threshold in percent to zero - this is recommended in fsl list, but is that OK ? (?)
        sed -i "s|set fmri(smooth) X|set fmri(smooth) 0|g" $conffile # set smoothing kernel to zero
        sed -i "s|set fmri(unwarp_dir) .*|set fmri(unwarp_dir) $dir|g" $conffile # set unwarp dir.        
        sed -i "s|set feat_files(1) \"X\"|set feat_files(1) \"$fldr/ec_diff_merged\"|g" $conffile # set input files        
        sed -i "s|set unwarp_files(1) \"X\"|set unwarp_files(1) \"$(remove_ext $fmap)\"|g" $conffile # set fieldmap file (removing extension might be important for finding related files by feat) (?)
        sed -i "s|set unwarp_files_mag(1) \"X\"|set unwarp_files_mag(1) \"$(remove_ext $fmap_magn)\"|g" $conffile # set fieldmap magnitude file (removing extension might be important for finding related files by feat) (?)
        sed -i "s|set fmri(alternative_example_func) \"X\"|set fmri(alternative_example_func) \"$altExFunc\"|g" $conffile # set alternative example func
        sed -i "s|set fmri(regstandard) .*|set fmri(regstandard) \"$FSL_DIR/data/standard/MNI152_T1_2mm_brain\"|g" $conffile # set MNI template
             
        sed -i "s|set fmri(analysis) .*|set fmri(analysis) 1|g" $conffile # do only pre-stats     
        sed -i "s|set fmri(regunwarp_yn) .*|set fmri(regunwarp_yn) 1|g" $conffile # enable unwarp      
        sed -i "s|set fmri(temphp_yn) .*|set fmri(temphp_yn) 0|g" $conffile # unset highpass filter       
        sed -i "s|set fmri(mc) .*|set fmri(mc) 0|g" $conffile # unset motion correction (DWIs already eddy-corrected!)
        sed -i "s|set fmri(bet_yn) .*|set fmri(bet_yn) 0|g" $conffile # unset brain extraction        
        sed -i "s|set fmri(reginitial_highres_yn) .*|set fmri(reginitial_highres_yn) 0|g" $conffile # unset registration to initial highres
        sed -i "s|set fmri(reghighres_yn) .*|set fmri(reghighres_yn) 0|g" $conffile # unset registration to highres
        sed -i "s|set fmri(regstandard_yn) .*|set fmri(regstandard_yn) 0|g" $conffile # unset registration to standard space
        sed -i "s|fmri(overwrite_yn) .*|fmri(overwrite_yn) 1|g" $conffile # overwrite on re-run
        if [ $FDT_FEAT_NO_BROWSER -eq 1 ] ; then
          sed -i "s|set fmri(featwatcher_yn) .*|set fmri(featwatcher_yn) 0|g" $conffile
        else 
          sed -i "s|set fmri(featwatcher_yn) .*|set fmri(featwatcher_yn) 1|g" $conffile
        fi
      done
    done
  done
fi
  
waitIfBusy

# FDT execute FEAT to do the unwarping and extract unwarped B0...  
if [ $FDT_STG4 -eq 1 ] ; then
  echo "----- BEGIN FDT_STG4 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/fdt
      
      uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_dwi $subj $sess`

      # cleanup previous runs, execute FEAT and link to unwarped file
      # NOTE: feat self-submits to the cluster and should in fact not be used in conjunction with fsl_sub (but it seems to work anyway) (!)
      featdir=$fldr/unwarpDWI_${uw_dir}.feat
      if [ -d $featdir ] ; then
        echo "FDT : subj $subj , sess $sess : WARNING : removing previous .feat directory ('$featdir')..."     
        rm -rf $featdir
      fi
      
      conffile=${featdir%.feat}.fsf
      echo "FDT : subj $subj , sess $sess : running \"feat $conffile\"..."
      #fsl_sub -l $logdir -N fdt_feat_$(subjsess) feat $conffile
      feat $conffile
      ln -sf ./$(basename $featdir)/filtered_func_data.nii.gz $fldr/uw_ec_diff_merged.nii.gz

    done
  done
fi
    
waitIfBusy

# FDT estimate tensor model
if [ $FDT_STG5 -eq 1 ] ; then
  echo "----- BEGIN FDT_STG5 -----"
  for subj in `cat subjects` ; do
    for sess in `cat ${subj}/sessions_struc` ; do    
      fldr=$subj/$sess/fdt
      
      # get info for current subject
      f=`getBetThres ${subjdir}/config_bet_lowb $subj $sess`

      # bet, if necessary
      if [ $f = "mod" ] ; then
        if [ ! -f $fldr/nodif_brain_${f}.nii.gz  -o ! -f $fldr/nodif_brain_${f}_mask.nii.gz ] ; then   
          echo "FDT : subj $subj , sess $sess : externally modified volume (nodif_brain_${f}) & mask (nodif_brain_${f}_mask) not found - exiting..." ; exit          
        fi
      else
        echo "FDT : subj $subj , sess $sess : betting B0 image with fi=${f}..."
        bet $fldr/nodif $fldr/nodif_brain_${f} -m -f $f
      fi
      ln -sf nodif_brain_${f}.nii.gz $fldr/nodif_brain.nii.gz
      ln -sf nodif_brain_${f}_mask.nii.gz $fldr/nodif_brain_mask.nii.gz
      
      # link to unwarped brainmask
      uwdir=`getUnwarpDir ${subjdir}/config_unwarp_dwi $subj $sess`
      if [ $uwdir = -y ] ; then
        ln -sf ./unwarpDWI_-y.feat/unwarp/EF_UD_example_func.nii.gz $fldr/uw_nodif.nii.gz
        ln -sf ./unwarpDWI_-y.feat/unwarp/EF_UD_fmap_mag_brain_mask.nii.gz $fldr/uw_nodif_brain_mask.nii.gz
      fi
      if [ $uwdir = +y ] ; then
        ln -sf ./unwarpDWI_+y.feat/unwarp/EF_UD_example_func.nii.gz $fldr/uw_nodif.nii.gz
        ln -sf ./unwarpDWI_+y.feat/unwarp/EF_UD_fmap_mag_brain_mask.nii.gz $fldr/uw_nodif_brain_mask.nii.gz
      fi
      
      # display info
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model using nodif_brain_${f}_mask..."
      
      # concatenate bvals and bvecs within session
      concat_bvals $subj/$sess/"$pttrn_bvals" $fldr/bvals_concat.txt
      concat_bvecs $subj/$sess/"$pttrn_bvecs" $fldr/bvecs_concat.txt 
    
      # number of entries in bvals- and bvecs files consistent ?
      checkConsistency "$subj/$sess/$pttrn_diffs" $fldr/bvals_concat.txt $fldr/bvecs_concat.txt
      
      # rotate bvecs
      xfmrot $fldr/ec_diff_merged.ecclog $fldr/bvecs_concat.txt $fldr/bvecs_concat.rot
      
      # estimate tensor model (rotated bvecs)
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - eddy-corr. & corrected b-vectors..."
      fsl_sub -l $logdir -N fdt_dtifit_ec_bvecrot_$(subjsess) dtifit -k $fldr/ec_diff_merged -m $fldr/nodif_brain_mask -r $fldr/bvecs_concat.rot -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_ec_bvecrot
         
      # estimate tensor model (native bvecs)
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - eddy-corr. & native b-vectors..."
      fsl_sub -l $logdir -N fdt_dtifit_ec_norot_$(subjsess) dtifit -k $fldr/ec_diff_merged -m $fldr/nodif_brain_mask -r $fldr/bvecs_concat.txt -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_ec_norot
      
      # estimate tensor model - unwarped and eddy-corrected DWIs (rotated bvecs)
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - eddy-corr. unwarped DWIs & corrected b-vectors..."
      fsl_sub -l $logdir -N fdt_dtifit_uw_bvecot_$(subjsess) dtifit -k $fldr/uw_ec_diff_merged -m $fldr/uw_nodif_brain_mask -r $fldr/bvecs_concat.rot -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_uw_bvecrot
      
      # estimate tensor model - unwarped and eddy-corrected DWIs (native bvecs)
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - eddy-corr. unwarped DWIs & native b-vectors..."
      fsl_sub -l $logdir -N fdt_dtifit_uw_norot_$(subjsess) dtifit -k $fldr/uw_ec_diff_merged -m $fldr/uw_nodif_brain_mask -r $fldr/bvecs_concat.txt -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_uw_norot
        
      # estimate tensor model - no eddy-correction
      echo "FDT : subj $subj , sess $sess : dtifit is estimating tensor model - no eddy-correction..."
      fsl_sub -l $logdir -N fdt_dtifit_noec_$(subjsess) dtifit -k $fldr/diff_merged -m $fldr/nodif_brain_mask -r $fldr/bvecs_concat.txt -b $fldr/bvals_concat.txt  -o $fldr/$(subjsess)_dti_noec        
    done    
  done
fi

#####################
# ----- END FDT -----
#####################


waitIfBusy


###########################
# ----- BEGIN PLOT EC -----
###########################
      
# plotting eddy-correct motion parameters
if [ $PLOT_EC -eq 1 ] ; then
  echo "----- BEGIN PLOT_EC -----"
  ec_disp_subj="" ; ec_disp_subjsess=""  # initialise
  ec_rot_subj="" ; ec_rot_subjsess=""  # initialise
  ec_trans_subj="" ; ec_trans_subjsess=""  # initialise
  for  subj in `cat subjects` ; do     
    fldr=$subjdir/$subj/fdt
	
    if [ -f $fldr/ec_diff_merged.ecclog ] ; then
      cd $fldr
      
      # cleanup previous runs...
      rm -f ec_rot.txt ; rm -f ec_disp.txt ; rm -f ec_trans.txt
      
      # plot...
      echo "ECPLOT : subj $subj : plotting motion parameters from ec-log file..." 
      eddy_correct_plot ec_diff_merged.ecclog $subj
      
      # accumulate
      ec_disp_subj=$ec_disp_subj" "$fldr/ec_disp.png
      ec_rot_subj=$ec_rot_subj" "$fldr/ec_rot.png
      ec_trans_subj=$ec_trans_subj" "$fldr/ec_trans.png

      cd $subjdir
    fi
    
    for sess in `cat ${subj}/sessions_struc` ; do
      # skip if single session design
      if [ $sess = '.' ] ; then continue ; fi
      
      fldr=$subjdir/$subj/$sess/fdt
      if [ -f $fldr/ec_diff_merged.ecclog ] ; then		
        cd $fldr
        
        # cleanup previous runs...
        rm -f ec_rot.txt ; rm -f ec_disp.txt ; rm -f ec_trans.txt
        
        # plot...
        echo "ECPLOT : subj $subj , sess $sess : plotting motion parameters from ec-log file..." 
        eddy_correct_plot ec_diff_merged.ecclog $(subjsess)
        
        # accumulate
        ec_disp_subjsess=$ec_disp_subjsess" "$fldr/ec_disp.png
        ec_rot_subjsess=$ec_rot_subjsess" "$fldr/ec_rot.png
        ec_trans_subjsess=$ec_trans_subjsess" "$fldr/ec_trans.png
        
        cd $subjdir
      fi
    done
  done
  
  # Creating overall image
  echo "ECPLOT : creating overall plot..."
  n1=`echo $ec_disp_subj | wc -w`
  n2=`echo $ec_disp_subjsess | wc -w`
  n3=`echo $ec_rot_subj | wc -w`
  n4=`echo $ec_rot_subjsess | wc -w`
  n5=`echo $ec_trans_subj | wc -w`
  n6=`echo $ec_trans_subjsess | wc -w`
  
  if [ $n1 -gt 0 ] ; then montage -tile 1x${n1} -mode Concatenate $ec_disp_subj $subjdir/ec_disp_subj.png ; fi
  if [ $n2 -gt 0 ] ; then montage -tile 1x${n2} -mode Concatenate $ec_disp_subjsess $subjdir/ec_disp_subjsess.png ; fi
  if [ $n3 -gt 0 ] ; then montage -tile 1x${n3} -mode Concatenate $ec_rot_subj $subjdir/ec_rot_subj.png ; fi
  if [ $n4 -gt 0 ] ; then montage -tile 1x${n4} -mode Concatenate $ec_rot_subjsess $subjdir/ec_rot_subjsess.png ; fi
  if [ $n5 -gt 0 ] ; then montage -tile 1x${n5} -mode Concatenate $ec_trans_subj $subjdir/ec_trans_subj.png ; fi
  if [ $n6 -gt 0 ] ; then montage -tile 1x${n6} -mode Concatenate $ec_trans_subjsess $subjdir/ec_trans_subjsess.png ; fi

  if [ $n1 -gt 0 -o $n2 -gt 0 -o $n3 -gt 0 -o $n4 -gt 0 -o $n5 -gt 0 -o $n6 -gt 0 ] ; then
    echo "ECPLOT : saving composite file..." 
    montage -adjoin -geometry ^ $subjdir/ec_disp_*.png $subjdir/ec_rot_*.png $subjdir/ec_trans_*.png plot_ec_fdt.png
  
    # deleting intermediate files
    rm -f $subjdir/ec_disp_*.png $subjdir/ec_rot_*.png $subjdir/ec_trans_*.png
  else
    echo "ECPLOT : nothing to plot." 
  fi
fi

#########################
# ----- END PLOT EC -----
#########################

  
waitIfBusy


###################################
# ----- BEGIN PLOT_DWI_UNWARP -----
###################################

if [ $PLOT_DWI_UNWARP -eq 1 ] ; then
  echo "----- BEGIN PLOT_DWI_UNWARP -----"
  
  if [ -z "$PLOT_DWI_UNWARP_DIRNAMES" ] ; then echo "PLOT_DWI_UNWARP : WARNING : no directory specified." ; fi
  
  for dirnm in $PLOT_DWI_UNWARP_DIRNAMES ; do
    appends=""
    for subj in `cat $subjdir/subjects` ; do
      j=0
      for sess in `cat $subjdir/$subj/sessions_struc` ; do
        
        n=$(find $subjdir/$subj/$sess/fdt -mindepth 3 -maxdepth 3 -name EF_UD_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | wc -l)
        if [ $n -gt 1 ] ; then
          echo "WARNING : search pattern matches more than one directory:"
          echo "$(find $subjdir/$subj/$sess/fdt -mindepth 3 -maxdepth 3 -name EF_UD_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | xargs ls -rt | xargs -I {} dirname {} )"
          echo "...taking the last one, because it is newer."
        fi      
        dwi_D=$(find $subjdir/$subj/$sess/fdt -mindepth 3 -maxdepth 3 -name EF_D_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | xargs ls -rt | grep EF_D_example_func.nii.gz | tail -n 1)
        dwi_UD=$(find $subjdir/$subj/$sess/fdt -mindepth 3 -maxdepth 3 -name EF_UD_example_func.nii.gz -type f | grep $dirnm | grep /unwarp | xargs ls -rt | grep EF_UD_example_func.nii.gz | tail -n 1)
        if [ -z $dwi_UD ] ; then echo "PLOT_DWI_UNWARP : subj $subj , sess $sess : WARNING : no 'EF_UD_example_func.nii.gz' file found under '$subjdir/$subj/$sess/fdt/*${dirnm}*' - continuing loop..." ; continue ; fi
        
        echo "PLOT_DWI_UNWARP : subj $subj , sess $sess : processing '$dwi_D'..."
        cmd="slicer -s 2 $dwi_D $(dirname $dwi_UD)/EF_UD_fmap_mag_brain.nii.gz -a $(subjsess)_dwi_D2fmap.png"
        $cmd
        echo "PLOT_DWI_UNWARP : subj $subj , sess $sess : processing '$dwi_UD'..."
        cmd="slicer -s 2 $dwi_UD $(dirname $dwi_UD)/EF_UD_fmap_mag_brain.nii.gz -a $(subjsess)_dwi_UD2fmap.png"
        $cmd
        
        #montage -label "D" -pointsize 9  $(subjsess)_dwi_D2fmap.png  $(subjsess)_dwi_D2fmap.png 
        #montage -label "UD" -pointsize 9  $(subjsess)_dwi_UD2fmap.png  $(subjsess)_dwi_UD2fmap.png 
        
        dirnm_base0=$(basename $(dirname $(dirname $(dirname $dwi_UD)))) ; dirnm_base1=$(basename $(dirname $(dirname $dwi_UD)))
        montage -adjoin $(subjsess)_dwi_D2fmap.png $(subjsess)_dwi_UD2fmap.png -geometry ^ $(subjsess)_dwi2mag.png
        montage -label "D vs UD \n$(subjsess) ($dirnm_base0/\n$dirnm_base1)" -pointsize 9 -geometry ^ $(subjsess)_dwi2mag.png $(subjsess)_dwi2mag.png
        rm -f $(subjsess)_dwi_D2fmap.png $(subjsess)_dwi_UD2fmap.png
        
        if [ -z "$appends" ] ; then 
          appends=$(subjsess)_dwi2mag.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$(subjsess)_dwi2mag.png
        else
          appends=$appends" - "$(subjsess)_dwi2mag.png
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done
    
    if [ ! -z "$appends" ] ; then
      echo "PLOT_DWI_UNWARP : creating overall plot..."
      cmd="pngappend $appends plot_diff2mag_fdt_${dirnm}.png"
      echo $cmd ; $cmd        
      echo "PLOT_DWI_UNWARP : cleaning up..."
      rm -f $subjdir/*_dwi2mag.png
    else 
      echo "PLOT_DWI_UNWARP : nothing to plot."
    fi

  done
fi

#################################
# ----- END PLOT_DWI_UNWARP -----
#################################


waitIfBusy


############################
# ----- BEGIN BEDPOSTX -----
############################


if [ $BPX_STG1 -eq 1 ] ; then
  
  echo "----- BEGIN BPX_STG1 -----"  
  
  # define bedpostx subdirectories
  bpx_dir=""
  bpx_opts="-n 2 -w 1 -b 1000"

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
          cp -v $subjdir/$subj/$sess/topup/nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
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
          cp -v $subjdir/$subj/$sess/topup/nodif_brain_mask.nii.gz $bpx_dir/nodif_brain_mask.nii.gz 
          cp -v $subjdir/$subj/$sess/topup/avg_bvecs_topup_ec.rot $bpx_dir/bvecs
          cp -v $subjdir/$subj/$sess/topup/avg_bvals.txt $bpx_dir/bvals
          cp -v $subjdir/$subj/$sess/topup/$(subjsess)_topup_corr_ec_merged.nii.gz $bpx_dir/data.nii.gz
          
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
      file=`ls ${subj}/${sess}/${pttrn_strucs} | tail -n 1` # take last, check (!)
      fslmaths $file ${fldr}/$(subjsess)_t1_orig
      
      # reorient for fslview
      fslreorient2std $file ${fldr}/$(subjsess)_t1_flipped
      ln -sf $(subjsess)_t1_flipped.nii.gz $fldr/$(subjsess)_t1_struc.nii.gz
      
      # convert to .mnc & perform non-uniformity correction
      if [ $VBM_NU_CORRECT_T1 -eq 1 ] ; then
        echo "VBM PREPROC : subj $subj , sess $sess : performing non-uniformity correction..."
        mri_convert ${fldr}/$(subjsess)_t1_flipped.nii.gz $fldr/tmp.mnc # &>$logdir/vbm_mri_convert01_$(subjsess) 
        fsl_sub -l $logdir -N vbm_nu_correct_$(subjsess) nu_correct -clobber $fldr/tmp.mnc $fldr/t1_nu_struc.mnc
      fi
      
      # also obtain skull-stripped volumes from FREESURFER, if available
      if [ -f $FS_subjdir/$(subjsess)/mri/brain.mgz ] ; then
        echo "VBM PREPROC : subj $subj , sess $sess : obtaining skull-stripped FREESURFER volumes (-> '$(subjsess)_FS_brain.nii.gz' & '$(subjsess)_FS_struc.nii.gz')..."
        mri_convert $FS_subjdir/$(subjsess)/mri/brain.mgz $fldr/$(subjsess)_FS_brain.nii.gz
        mri_convert $FS_subjdir/$(subjsess)/mri/T1.mgz $fldr/$(subjsess)_FS_struc.nii.gz
        fslreorient2std $fldr/$(subjsess)_FS_brain.nii.gz $fldr/$(subjsess)_FS_brain.nii.gz
        fslreorient2std $fldr/$(subjsess)_FS_struc.nii.gz $fldr/$(subjsess)_FS_struc.nii.gz
      else
        echo "VBM PREPROC : subj $subj , sess $sess : FREESURFER processed MRIs not found."
      fi
    done
  done
  
  if [ $VBM_NU_CORRECT_T1 -eq 1 ] ; then
    # wait until nu_correct has finished...
    waitIfBusy       
    # re-convert to .nii.gz format and delete temporary files
    for subj in `cat subjects`; do 
      for sess in `cat ${subj}/sessions_struc` ; do
        fldr=$subjdir/$subj/$sess/vbm
        mri_convert $fldr/t1_nu_struc.mnc $fldr/$(subjsess)_t1_nu_struc.nii.gz &>$logdir/vbm01_mri_convert02_$(subjsess)
        rm -f $fldr/tmp.mnc
        rm -f $fldr/t1_nu_struc.mnc
        ln -sf $(subjsess)_t1_nu_struc.nii.gz $fldr/$(subjsess)_t1_struc.nii.gz
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

      # betting (if no externally modified skull-stripped volume is supplied)
      if [ $f = "mod" ] ; then 
        imcp ${fldr}/$(subjsess)_t1_betted_initbrain_mod ${fldr}/$(subjsess)_t1_betted_initbrain
        ln -sf $(subjsess)_t1_betted_initbrain_mod $fldr/$(subjsess)_t1_initbrain.nii.gz       
      else
        fsl_sub -l $logdir -N vbm_bet_$(subjsess) bet ${fldr}/$(subjsess)_t1_struc  ${fldr}/$(subjsess)_t1_betted_initbrain `getBetCoGOpt "$CoG"` `getBetFIOpt $f`
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
      fldr="${subj}/${sess}/vbm"
      t1Brain="${fldr}/$(subjsess)_t1_initbrain"      
      echo "VBM PREPROC : subj $subj , sess $sess : flirting $t1Brain to MNI..."
      fsl_sub -l $logdir -N vbm_flirt_$(subjsess) flirt -in ${t1Brain} -ref $FSLDIR/data/standard/MNI152_T1_1mm_brain -out ${fldr}/flirted_t1_brain -dof 12 -omat ${fldr}/t1_to_MNI        
    done
  done

  waitIfBusy

  # VBM PREPROC SSM flirting standard mask to T1 space
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr="${subj}/${sess}/vbm"; t1=${fldr}/$(subjsess)_t1_struc
      echo "VBM PREPROC : subj $subj , sess $sess : flirting standard mask to T1 space..."
      convert_xfm -omat ${fldr}/MNI_to_t1 -inverse ${fldr}/t1_to_MNI
      fsl_sub -l $logdir -N vbm_flirt_$(subjsess) flirt -in  $FSLDIR/data/standard/MNI152_T1_1mm_first_brain_mask -out ${fldr}/t1_mask -ref $t1 -applyxfm -init ${fldr}/MNI_to_t1         
    done
  done

  waitIfBusy

  # VBM PREPROC SSM creating mask
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subj}/${sess}/vbm
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
        fldr=${subj}/${sess}/vbm
        echo "VBM PREPROC : subj $subj , sess $sess : eroding mask - iteration ${n_ero} / ${VBM_SSM_ERODE_STEPS}..."
        fsl_sub -l $logdir -N vbm_fslmaths_$(subjsess) fslmaths ${fldr}/t1_mask_inv_ero$(echo $n_ero -1 | bc -l) -ero -bin ${fldr}/t1_mask_inv_ero${n_ero}
      done
    done
    
    waitIfBusy
    
  done

  ## VBM PREPROC SSM eroding mask
  #for subj in `cat subjects`; do 
    #for sess in `cat ${subj}/sessions_struc` ; do
      #fldr="${subj}/${sess}/vbm"
      #echo "VBM PREPROC : subj $subj , sess $sess : eroding mask..."
      #fsl_sub -l $logdir -N vbm_fslmaths_$(subjsess) fslmaths ${fldr}/t1_mask_inv_ero -ero -bin ${fldr}/t1_mask_inv_ero2
    #done
  #done

  #waitIfBusy

  ## VBM PREPROC SSM eroding mask
  #for subj in `cat subjects`; do 
    #for sess in `cat ${subj}/sessions_struc` ; do
      #fldr=${subj}/${sess}/vbm
      #echo "VBM PREPROC : subj $subj , sess $sess : eroding mask..."
      #fsl_sub -l $logdir -N vbm_fslmaths_$(subjsess) fslmaths ${fldr}/t1_mask_inv_ero2 -ero -bin ${fldr}/t1_mask_inv_ero3
    #done
  #done

  #waitIfBusy

  # VBM PREPROC SSM masking native T1
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=${subj}/${sess}/vbm;  t1=${fldr}/$(subjsess)_t1_struc
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
      fldr=$subj/$sess/vbm
      
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
      fldr=$subj/$sess/vbm
      
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
      fldr=$subj/$sess/vbm
      
      # watershed...
      echo "VBM PREPROC : subj $subj , sess $sess : watershedding..."
      fsl_sub -l $logdir -N vbm_watershed1_$(subjsess) mri_watershed $fldr/$(subjsess)${input} $fldr/$(subjsess)_t1_watershed${masked}_brain.nii.gz
      fsl_sub -l $logdir -N vbm_watershed2_$(subjsess) mri_watershed $fldr/$(subjsess)_t1_betted${masked}_brain.nii.gz $fldr/$(subjsess)_t1_watershed_betted${masked}_brain.nii.gz
    done
  done
  
  waitIfBusy
  
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subj/$sess/vbm
      
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
# ----- BEGIN BIASMAP -----
###########################
  
# BIASMAP creating bias map if applicable
if [ $BIASMAP_STG1 -eq 1 ] ; then
  echo "----- BEGIN BIASMAP_STG1 -----"
  # search pattern for anatomicals set ?
  if [ -z $pttrn_strucs ] ; then echo "BIASMAP : search pattern for anatomical files not set - exiting..." ; exit ; fi
  
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do    
      # mkdir
      fldr=$subj/$sess/bias ; mkdir -p $fldr
      
      # prepare
      src0=`ls $subjdir/$subj/$sess/$pttrn_strucs | head -n 1`
      mask=$subjdir/$subj/$sess/vbm/$(subjsess)_t1_betted_masked_brain_mask.nii.gz
      if [ ! -f $mask ] ; then echo "BIASMAP : subj $subj , sess $sess : $mask not found; you must run the VBM stream first - continuing loop..." ; continue ; fi
      ln -sf $mask $fldr/t1_mask.nii.gz
      echo "BIASMAP : subj $subj , sess $sess : skull-stripping $src0 using `basename $mask`..."
      fslreorient2std $src0 $fldr/t1_biased
      fslmaths $fldr/t1_biased -mas $fldr/t1_mask.nii.gz $fldr/t1_biased_brain -odt float
      
      # creating biasmap using fsl-fast...          
      echo "BIASMAP : subj $subj , sess $sess : creating bias map using fsl-fast..."
      fsl_sub -l $logdir -N bias_fast_$(subjsess) fast -v -b $fldr/t1_biased_brain.nii.gz  
      
      # check if prescan unbiased scan is presumably available
      n_strucs=`ls $subjdir/$subj/$sess/$pttrn_strucs | wc -l`
      if [ $n_strucs -gt 1 ] ; then 
        echo "BIASMAP : subj $subj , sess $sess : $n_strucs t1 images found. Asuming the last one is prescan-unbiased. Creating bias map by division..."
      else 
        echo "BIASMAP : subj $subj , sess $sess : only $n_strucs t1 images found - cannot create pre-scan based bias-map. Continuing loop..."
        continue
      fi
      
      # create biasmap based on pre-scan unbiased...
      src1=`ls $subjdir/$subj/$sess/$pttrn_strucs | tail -n 1`      

      fslreorient2std $src1 $fldr/t1_prescan_unbiased
      fslmaths $fldr/t1_prescan_unbiased -mas $fldr/t1_mask.nii.gz $fldr/t1_prescan_unbiased_brain -odt float
      
      echo "BIASMAP : subj $subj , sess $sess : applying non-uniformity correction to (putatively) pre-scan unbiased T1 volume `basename $src1`..."
      mri_convert $fldr/t1_prescan_unbiased_brain.nii.gz $fldr/t1_prescan_unbiased_brain.mnc &>$logdir/bias_mri_convert01_$(subjsess) 
      nu_correct -clobber $fldr/t1_prescan_unbiased_brain.mnc  $fldr/t1_prescan_unbiased_nuc_brain.mnc  &>$logdir/bias_nu_correct_$(subjsess) 
      
      echo "BIASMAP : subj $subj , sess $sess : creating bias map by division..."
      mri_convert $fldr/t1_prescan_unbiased_nuc_brain.mnc $fldr/t1_unbiased_brain.nii.gz &>$logdir/bias_mri_convert02_$(subjsess) 
      fslmaths $fldr/t1_unbiased_brain -div $fldr/t1_biased_brain $fldr/t1_biasmap
       
      # cleanup
      imrm $fldr/t1_biased
      imrm $fldr/t1_prescan_unbiased
      imrm $fldr/t1_prescan_unbiased_brain
      rm $fldr/t1_prescan_unbiased_nuc_brain.mnc    
      rm $fldr/t1_prescan_unbiased_nuc_brain.imp      
    
    done
  done
  
  waitIfBusy
  
  # fsl-fast's biasmap: take reciproc...
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subj/$sess/bias
      
      # does fsl-fast output exist ?
      if [ ! -f $fldr/t1_biased_brain_bias.nii.gz ] ; then echo "BIASMAP : subj $subj , sess $sess : $fldr/t1_biased_brain_bias.nii.gz not found; has fsl's fast finished ? Continuing loop..." ; continue ; fi
      
      # take reciproc
      fslmaths $fldr/t1_biased_brain_bias.nii.gz -recip $fldr/t1_biasmap_fast.nii.gz
      
      # cleanup
      imrm $fldr/t1_biased
    done
  done
fi

waitIfBusy

# BIASMAP applying bias map
if [ $BIASMAP_STG2 -eq 1 ] ; then
  echo "----- BEGIN BIASMAP_STG2 -----"
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$subjdir/$subj/$sess/bias   
      
      bold=`find $subjdir/$subj/$sess/ -maxdepth 1 -name "*feat*" -type d | sort | tail -n 1`/filtered_func_data.nii.gz # must be adapted (!)
      mat=`find $(dirname $bold) -maxdepth 1 -name "*ica*" -type d | sort | tail -n 1`/reg/example_func2highres.mat # must be adapted (!)
      
      if [ -z $bold -o ! -f $bold ] ; then echo "BIASMAP : subj $subj , sess $sess : filtered_func_data.nii.gz not found in latest FEAT directory - continuing loop..." ; continue ; fi
      if [ -z $mat -o ! -f $mat ] ; then echo "BIASMAP : subj $subj , sess $sess : transformation matrix func -> highres not found in latest ICA (Melodic) directory - continuing loop..." ; continue ; fi
      
      ln -sf $mat $fldr/bold_to_t1
      ln -sf $bold $fldr/filtered_func.nii.gz
      
      echo "BIASMAP : subj $subj , sess $sess : inverting transformation matrix func -> highres ($mat)..."
      convert_xfm -omat $fldr/t1_to_bold -inverse $fldr/bold_to_t1
      
      echo "BIASMAP : subj $subj , sess $sess : resampling bias-map..."
      flirt -in $fldr/t1_biasmap_fast -out $fldr/t1_biasmap_fast_bold -ref $fldr/filtered_func -applyxfm -init $fldr/t1_to_bold
      flirt -in $fldr/t1_biasmap  -out $fldr/t1_biasmap_bold -ref $fldr/filtered_func -applyxfm -init $fldr/t1_to_bold

      echo "BIASMAP : subj $subj , sess $sess : applying bias-map..."
      fsl_sub -l $logdir -N bias_fslmaths fslmaths $fldr/filtered_func -mul $fldr/t1_biasmap_bold $fldr/filtered_func_unbiased
      fsl_sub -l $logdir -N bias_fslmaths fslmaths $fldr/filtered_func -mul $fldr/t1_biasmap_fast_bold $fldr/filtered_func_unbiased_fast
    done
  done
fi

#########################
# ----- END BIASMAP -----
#########################


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
      echo "RECON : subj $subj , sess $sess : reorienting T1 to please fslview..." 
      file=`ls ${subj}/${sess}/${pttrn_strucs} | tail -n 1` # take last, check pattern (!)
      fslreorient2std $file $fldr/tmp_t1
      
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
      echo '#!/bin/bash' > $fldr/recon-all_cuda.sh
      echo 'cudadetect &>/dev/null' >>  $fldr/recon-all_cuda.sh
      echo "if [ \$? = $exitflag ] ; then recon-all -all -use-gpu -no-isrunning -noappend -clean-tal -subjid $(subjsess)" >> $fldr/recon-all_cuda.sh # you may want to remove clean-tal flag (!)
      echo "else  recon-all -all -no-isrunning -noappend -clean-tal -subjid $(subjsess) ; fi" >> $fldr/recon-all_cuda.sh 
      chmod +x $fldr/recon-all_cuda.sh
      
      # execute...
      $scriptdir/fsl_sub_NOPOSIXLY -l $logdir -N recon-all_$(subjsess) $fldr/recon-all_cuda.sh
    done
  done
fi

waitIfBusy

if [ $RECON_STG3 -eq 1 ] ; then
  echo "----- BEGIN RECON_STG3 -----"
  for subj in `cat subjects`; do
    if [ "$(cat ${subj}/sessions_struc)" = "." ] ; then echo "RECON : subj $subj : single-session design ! Skipping longtitudinal freesurfer stream..." ; continue ; fi
    
    # create template dir.
    fldr=$FS_subjdir/$subj
    mkdir -p $fldr
    
    # init. command line
    cmd="recon-all -base $subj"
    
    # generate command line
    for sess in `cat ${subj}/sessions_struc` ; do
      cmd="$cmd -tp $(subjsess)" 
    done
    
    # executing...
    echo "RECON : subj $subj , sess $sess : executing recon-all - unbiased template generation..."
    cmd="$cmd -all -no-isrunning -noappend -clean-tal"
    echo $cmd | tee $fldr/recon-all_base.cmd
    $scriptdir/fsl_sub_NOPOSIXLY -l $logdir -N recon-all_base_${subj} -t $fldr/recon-all_base.cmd
  done
fi 

waitIfBusy

if [ $RECON_STG4 -eq 1 ] ; then
  echo "----- BEGIN RECON_STG4 -----"
  for subj in `cat subjects`; do
    if [ "$(cat ${subj}/sessions_struc)" = "." ] ; then echo "RECON : subj $subj : single-session design ! Skipping longtitudinal freesurfer stream..." ; continue ; fi
    
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$FS_subjdir/$(subjsess)
      
      # generate command line
      cmd="recon-all -long $(subjsess) $subj -all -no-isrunning -noappend -clean-tal"
      
      # executing...
      echo "RECON : subj $subj , sess $sess : executing recon-all - longtitudinal stream..."
      echo $cmd | tee $fldr/recon-all_long.cmd
      $scriptdir/fsl_sub_NOPOSIXLY -l $logdir -N recon-all_long_$(subjsess) -t $fldr/recon-all_long.cmd
    done    
  done
fi 

waitIfBusy

if [ $RECON_STG5 -eq 1 ] ; then
  echo "----- BEGIN RECON_STG5 -----"

  # register Freesurfer's longt. template to FSL'S MNI152
  for subj in `cat subjects` ; do
    if [ "$(cat ${subj}/sessions_struc)" = "." ] ; then echo "RECON : subj $subj : single-session design ! Skipping..." ; continue ; fi
        
    # display info
    echo "RECON : subj $subj : registering Freesurfer's longtitudinal template to FSL's MNI152 template..."
    
    # check
    if [ ! -f $FS_subjdir/$subj/mri/norm_template.mgz ] ; then "RECON : subj $subj : longtitudinal template not found ! Skipping..." ; continue ; fi
    
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
    $scriptdir/fs_convert.sh $FS_subjdir/$subj/mri/norm_template.mgz $FS_fldr/longt_brain.nii.gz 0 
          
    #MNI_head_LIA=$FS_fldr/standard_head_LIA
    #MNI_brain_LIA=$FS_fldr/standard_brain_LIA
    #MNI_mask_LIA=$FS_fldr/standard_mask_LIA      
    #echo "BOLD : subj $subj : reorienting FSL's MNI152 template LAS -> LIA..."
    #fslswapdim $FSL_DIR/data/standard/MNI152_T1_2mm RL SI PA ${MNI_head_LIA}
    #fslswapdim $FSL_DIR/data/standard/MNI152_T1_2mm_brain RL SI PA ${MNI_brain_LIA}
    #fslswapdim $FSL_DIR/data/standard/MNI152_T1_2mm_brain_mask_dil RL SI PA ${MNI_mask_LIA}      
    #echo "BOLD : subj $subj : registering Freesurfer longtitudinal template to FSL's MNI152 space..."
    #$scriptdir/fs_convert.sh $FS_subjdir/$subj/mri/T1.mgz $FS_fldr/longthead.nii.gz 0
    #$scriptdir/fs_convert.sh $FS_subjdir/$subj/mri/norm_template.mgz $FS_fldr/longtbrain.nii.gz 0
    #$scriptdir/feat_T1_2_MNI.sh $FS_fldr/longthead $FS_fldr/longtbrain $FS_fldr/longthead2standard "none" "corratio" ${MNI_head_LIA} ${MNI_brain_LIA} ${MNI_mask_LIA} $subj "/"
    
    # generate command line
    cmd="$scriptdir/feat_T1_2_MNI.sh $FS_fldr/longt_head $FS_fldr/longt_brain $FS_fldr/longt_head2longt_standard none corratio $MNI_head $MNI_brain $MNI_mask $subj --"
    
    # executing...
    cmd_file=$FS_subjdir/$subj/recon_longt2MNI.cmd
    echo "RECON : subj $subj : executing '$cmd_file'"
    echo "$cmd" | tee $cmd_file
    fsl_sub -l $logdir -N recon_longt2MNI_${subj} -t $cmd_file
  done
fi

#########################
# ----- END RECON -----
#########################


waitIfBusy


###########################
# ----- BEGIN TRACULA -----
###########################

# TRACULA prepare 
if [ $TRACULA_STG1 -eq 1 ] ; then
  echo "----- BEGIN TRACULA_STG1 -----"
  if [ ! -f template_tracula.rc ] ; then echo "TRACULA : template file not found. Exiting..." ; exit ; fi
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
      cp template_tracula.rc $fldr/tracula.rc
      
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
          concat_bvals $subj/$sess/"$pttrn_bvals" $fldr/bvals_concat.txt
          concat_bvecs $subj/$sess/"$pttrn_bvecs" $fldr/bvecs_concat.txt
        else 
          ln -sfv ../../$subj/$sess/fdt/bvals_concat.txt $fldr/bvals_concat.txt
          ln -sfv ../../$subj/$sess/fdt/bvecs_concat.txt $fldr/bvecs_concat.txt
        fi        
        
        # are DWIs already concatenated ?
        if [ -f $subj/$sess/fdt/diff_merged.nii.gz ] ; then
          ln -sfv ../../$subj/$sess/fdt/diff_merged.nii.gz $fldr/diff_merged.nii.gz
        else
          echo "TRACULA : subj $subj , sess $sess : no pre-existing 4D file found - merging diffusion files..."
          diffs=`ls $subj/$sess/$pttrn_diffs`          
          fsl_sub -l $logdir -N trac_fslmerge_$(subjsess) fslmerge -t $fldr/diff_merged $diffs 
        fi
        
        # tracula shall perform eddy-correction
        sed -i "s|set doeddy = .*|set doeddy = 1|g" $fldr/tracula.rc
        sed -i "s|set dorotbvecs = .*|set dorotbvecs = 1|g" $fldr/tracula.rc 
      elif [ $TRACULA_USE_UNWARPED_BVECROT -eq 1 ] ; then          
        # is fdt directory present ?
        if [ ! -d $subjdir/$subj/$sess/fdt ] ; then echo "TRACULA : subj $subj , sess $sess : ERROR : you must run the FDT-stream first - breaking loop..." ; break ; fi
        
        echo "TRACULA : subj $subj , sess $sess : linking to unwarped DWIs (and corrected b-vectors)..."
        ln -sfv ../../$subj/$sess/fdt/bvals_concat.txt $fldr/bvals_concat.txt
        ln -sfv ../../$subj/$sess/fdt/bvecs_concat.rot $fldr/bvecs_concat.txt
        ln -sfv ../../$subj/$sess/fdt/uw_ec_diff_merged.nii.gz $fldr/diff_merged.nii.gz
        
        # tracula shall not eddy-correct
        sed -i "s|set doeddy = .*|set doeddy = 0|g" $fldr/tracula.rc
        sed -i "s|set dorotbvecs = .*|set dorotbvecs = 0|g" $fldr/tracula.rc
      elif [ $TRACULA_USE_TOPUP_NOEC_BVECROT -eq 1 ] ; then
        # is topup directory present ?
        if [ ! -d $subjdir/$subj/$sess/topup ] ; then echo "TRACULA : subj $subj , sess $sess : ERROR : you must run the TOPUP-stream first - breaking loop..." ; break ; fi
        
        echo "TRACULA : subj $subj , sess $sess : linking to TOPUP corrected DWIs (and corrected b-vectors)..."
        ln -sfv ../../$subj/$sess/topup/avg_bvals.txt $fldr/bvals_concat.txt
        ln -sfv ../../$subj/$sess/topup/avg_bvecs_topup.rot $fldr/bvecs_concat.txt
        ln -sfv ../../$subj/$sess/topup/$(subjsess)_topup_corr_merged.nii.gz $fldr/diff_merged.nii.gz
        
        # tracula shall not eddy-correct
        sed -i "s|set doeddy = .*|set doeddy = 0|g" $fldr/tracula.rc
        sed -i "s|set dorotbvecs = .*|set dorotbvecs = 0|g" $fldr/tracula.rc # b-vec. correction in TRACULA will be incorrect for TOPUP corrected files, bc. TOPUP does a rigid body alignment that must be accounted for before running TRACULA
      elif [ $TRACULA_USE_TOPUP_EC_BVECROT -eq 1 ] ; then
        # is topup directory present ?
        if [ ! -d $subjdir/$subj/$sess/topup ] ; then echo "TRACULA : subj $subj , sess $sess : ERROR : you must run the TOPUP-stream first - breaking loop..." ; break ; fi
        
        echo "TRACULA : subj $subj , sess $sess : linking to TOPUP corrected, eddy-corrected DWIs (and corrected b-vectors)..."
        ln -sfv ../../$subj/$sess/topup/avg_bvals.txt $fldr/bvals_concat.txt
        ln -sfv ../../$subj/$sess/topup/avg_bvecs_topup_ec.rot $fldr/bvecs_concat.txt
        ln -sfv ../../$subj/$sess/topup/$(subjsess)_topup_corr_ec_merged.nii.gz $fldr/diff_merged.nii.gz
       
        # tracula shall not eddy-correct
        sed -i "s|set doeddy = .*|set doeddy = 0|g" $fldr/tracula.rc
        sed -i "s|set dorotbvecs = .*|set dorotbvecs = 0|g" $fldr/tracula.rc
      fi
      
      # transpose bvals and bvecs files to please TRACULA
      echo "TRACULA : subj $subj , sess $sess : transpose fsl-style bvals / bvecs files to please TRACULA..."
      transpose $fldr/bvals_concat.txt > $fldr/bvals_transp.txt; cat $fldr/bvals_transp.txt | wc
      transpose $fldr/bvecs_concat.txt > $fldr/bvecs_transp.txt; cat $fldr/bvecs_transp.txt | wc   
                
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
      if [ ! -f $fldr/mri/aparc+aseg.mgz ] ; then echo "TRACULA : subj $subj , sess $sess : aparc+aseg.mgz file not found - did you run recon-all ?" ; errflag=1 ;  fi
    done
  done
  if [ $errflag = 1 ] ; then echo "TRACULA : subj $subj , sess $sess : you must run recon-all for all subjects before executing TRACULA - exiting..." ; exit ; fi
  
  for subj in `cat subjects`; do 
    for sess in `cat ${subj}/sessions_struc` ; do
      fldr=$FS_subjdir/$(subjsess)
      echo "TRACULA : subj $subj , sess $sess : executing trac-all -prep command:"
      echo "$scriptdir/fsl_sub_NOPOSIXLY -l $logdir -N trac-all-prep_$(subjsess) trac-all -no-isrunning -noappendlog -prep -c $fldr/tracula.rc" | tee $fldr/trac-all_prep.cmd
      #echo "trac-all -no-isrunning -noappendlog -prep -c $fldr/tracula.rc -log $logdir/trac-all-prep_$(subjsess)_$$" | tee $fldr/trac-all_prep.cmd 
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
      #echo "$scriptdir/fsl_sub_NOPOSIXLY -l $logdir -N trac-all-bedp_$(subjsess) trac-all -no-isrunning -noappendlog -bedp -c $fldr/tracula.rc" | tee $fldr/trac-all_bedp.cmd
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
      echo "$scriptdir/fsl_sub_NOPOSIXLY -l $logdir -N trac-all-paths_$(subjsess) trac-all -no-isrunning -noappendlog -path -c $fldr/tracula.rc" | tee $fldr/trac-all_path.cmd
      #echo "trac-all -no-isrunning -noappendlog -path -c $fldr/tracula.rc -log $logdir/trac-all-paths_$(subjsess)_$$" | tee $fldr/trac-all_path.cmd
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
      
      fldr=$subjdir/$subj/$sess/bold
      
      # create directory
      mkdir -p $fldr
                  
      # link bold file
      bold_bn=`basename $(ls $subjdir/$subj/$sess/$pttrn_bolds | tail -n 1)`
      bold_ext=`echo ${bold_bn#*.}`
      bold_lnk=bold.${bold_ext}
      if [ -L $fldr/bold.nii -o -L $fldr/bold.nii.gz ] ; then rm -f $fldr/bold.nii $fldr/bold.nii.gz ; fi # delete link if already present
      echo "BOLD : subj $subj , sess $sess : creating link '$bold_lnk' to '$bold_bn'"
      ln -sf ../$bold_bn $fldr/$bold_lnk
      
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
      fmap=$subjdir/$subj/$sess/fm/fmap_rads_masked.nii.gz
      if [ ! -f $fmap ] ; then echo "BOLD : subj $subj , sess $sess : WARNING : Fieldmap image '$fmap' not found !" ; fi
      fmap_magn=$subjdir/$subj/$sess/fm/magn_brain.nii.gz
      if [ ! -f $fmap_magn ] ; then echo "BOLD : subj $subj , sess $sess : WARNING : Fieldmap magnitude image '$fmap_magn' not found !" ; fi
      
      # create symlinks to t1-structurals (highres registration reference)
      if [ $BOLD_REGISTER_TO_MNI -eq 1 ] ; then
        echo "BOLD : subj $subj , sess $sess : creating symlinks to t1-structurals (highres registration reference)..."
        line=`cat $subjdir/config_func2highres.reg | awk '{print $1}' | grep -nx $(subjsess) | cut -d : -f1`
        sess_t1=`cat $subjdir/config_func2highres.reg | awk '{print $2}' | sed -n ${line}p `
        if [ $sess_t1 = '.' ] ; then sess_t1="" ; fi # single-session design   
        t1_brain=$fldr/${subj}${sess_t1}_t1_brain.nii.gz
        t1_struc=$fldr/${subj}${sess_t1}_t1.nii.gz
        feat_t1struc=`ls $subj/$sess_t1/vbm/$BOLD_PTTRN_HIGHRES_STRUC` ; feat_t1brain=`ls $subj/$sess_t1/vbm/$BOLD_PTTRN_HIGHRES_BRAIN`
        echo "BOLD : subj $subj , sess $sess : creating symlink '$(basename $t1_struc)' to '../../$sess_t1/vbm/$(basename $feat_t1struc)'"
        ln -sf ../../$sess_t1/vbm/$(basename $feat_t1struc) $t1_struc
        echo "BOLD : subj $subj , sess $sess : creating symlink '$(basename $t1_brain)' to '../../$sess_t1/vbm/$(basename $feat_t1brain)'"
        ln -sf ../../$sess_t1/vbm/$(basename $feat_t1brain) $t1_brain
      fi
      
      # preparing alternative example func
      if [ $BOLD_BET_EXFUNC -eq 1 ] ; then
        mid_pos=$(echo "scale=0 ; $npts / 2" | bc) # equals: floor($npts / 2)
        echo "BOLD : subj $subj , sess $sess : betting bold at pos. $mid_pos / $npts and using as example_func..."
        altExFunc=$fldr/exfunc_betted
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
              cp template_preprocBOLD.fsf $conffile
             
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
                echo "set highres_files(1) \"$(remove_ext $t1_brain)\"" >> $conffile # removing the file extension is very important, otw. the non-brain extracted T1 is not found and non-linear registration will become highly inaccurate (feat does not throw an error here!) (!)
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
            done # end stc_val
          done # end uw_dir          
        done # end sm_krnl
      done # end hpf_cut
            
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
            
            # link...
            echo "BOLD : subj $subj , sess $sess : creating symlink to unwarped 4D BOLD."
            lname=$(echo "$featdir" | sed "s|"uw[+-0][y0]"|"uw"|g") # remove unwarp direction from link's name
            ln -sfv ./$(basename $featdir)/filtered_func_data.nii.gz ${lname%.feat}_filtered_func_data.nii.gz
   
          done # end stc_val
        done # end sm_krnl        
      done # end hpf_cut
      
    done
  done
fi

waitIfBusy

# BOLD denoise
if [ $BOLD_STG3 -eq 1 ] ; then
  echo "----- BEGIN BOLD_STG3 -----"
  
  for subj in `cat subjects` ; do
    
    if [ x"$BOLD_DENOISE_MASKS" = "x" ] ; then echo "BOLD : subj $subj : ERROR : no masks for signal extraction specified -> no denoising possible -> breaking loop..." ; break ; fi
    
    for sess in `cat ${subj}/sessions_func` ; do
      
      fldr=$subjdir/$subj/$sess/bold
      sess_t1=`getT1Sess4FuncReg $subjdir/config_func2highres.reg $subj $sess`
      
      if [ $BOLD_UNWARP -eq 1 ] ; then
        uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess`
      else 
        uw_dir=00
      fi
      
      for hpf_cut in Inf ; do
        for sm_krnl in 0 ; do # denoising only with non-smoothed data -> smoothing carried out at the end.
          for stc_val in $BOLD_SLICETIMING_VALUES ; do
            
            # define feat-dir
            _hpf_cut=$(echo $hpf_cut | sed "s|\.||g") ; _sm_krnl=$(echo $sm_krnl | sed "s|\.||g") # remove '.'
            featdir=$fldr/${BOLD_FEATDIR_PREFIX}_uw${uw_dir}_st${stc_val}_s${_sm_krnl}_hpf${_hpf_cut}.feat
            
            if [ ! -d $featdir ] ; then echo "BOLD : subj $subj , sess $sess : feat-directory '$featdir' not found ! -> breaking loop..." ; break ; fi
            
            # cleanup prev. bbreg. runs
            rm -rf $featdir/noise/tmp.bbregister.*
            
            # display info
            echo "BOLD : subj $subj , sess $sess : creating masks in functional native space using FS's bbreg..."
            echo "BOLD : subj $subj , sess $sess : denoising..."
            echo "BOLD : subj $subj , sess $sess : smoothing..."
            
            # creating command for fsl_sub
            mkdir -p $featdir/noise
            ln -sf ../filtered_func_data.nii.gz $featdir/noise/filtered_func_data.nii.gz
            echo "$scriptdir/fs_create_masks.sh $SUBJECTS_DIR ${subj}${sess_t1} $featdir/example_func $featdir/noise $subj $sess ; \
            $scriptdir/denoise4D.sh $featdir/noise/filtered_func_data \"$BOLD_DENOISE_MASKS\" $featdir/mc/prefiltered_func_data_mcf.par \"$BOLD_DENOISE_USE_MOVPARS\" $featdir/noise/filtered_func_data_denoised $subj $sess ; \
            $scriptdir/feat_smooth.sh $featdir/noise/filtered_func_data_denoised $featdir/filtered_func_data_denoised \"$BOLD_DENOISE_SMOOTHING_KRNLS\" \"$BOLD_DENOISE_HPF_CUTOFFS\" $TR_bold $subj $sess" > $featdir/denoise.cmd
            
            # executing...
            fsl_sub -l $logdir -N bold_denoise_$(subjsess) -t $featdir/denoise.cmd
            
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
  
  for subj in `cat subjects` ; do
    
    if [ -z "$BOLD_MNI_RESAMPLE_RESOLUTIONS" -o "$BOLD_MNI_RESAMPLE_RESOLUTIONS" = "0" ] ; then echo "BOLD : ERROR : no resampling-resolutions for the MNI-registered BOLDs defined - breaking loop..." ; break ; fi

    for sess in `cat ${subj}/sessions_func` ; do
    
      # did we unwarp ?
      if [ $BOLD_UNWARP -eq 1 ] ; then
        uw_dir=`getUnwarpDir ${subjdir}/config_unwarp_bold $subj $sess`
      else 
        uw_dir=00
      fi     
      
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
            
            if [ $BOLD_USE_FS_LONGT_TEMPLATE -eq 1 ] ; then
            
              T1_file=$featdir/reg_longt/longt_brain # see RECON_STG5
              MNI_file=$featdir/reg_longt/longt_standard
              affine=$featdir/reg_longt/example_func2longt_brain.mat
              warp=$featdir/reg_longt/longt_head2longt_standard_warp
              ltag="_longt"
              
              echo "BOLD : subj $subj , sess $sess : copying registrations from '$FS_subjdir/$subj/fsl_reg/' to '$featdir/reg_longt/'..."
              mkdir -p $featdir/reg_longt
              cp $FS_subjdir/$subj/fsl_reg/* $featdir/reg_longt/

              # cleanup prev. bbreg. runs
              rm -rf $featdir/reg_longt/tmp.bbregister.*
              
              sess_t1=`getT1Sess4FuncReg $subjdir/config_func2highres.reg $subj $sess`              
              echo "BOLD : subj $subj , sess $sess : converting '${subj}${sess_t1}_to_${subj}.lta' -> '${subj}${sess_t1}_to_${subj}.mat' (FSL-style)..."
              tkregister2 --noedit --mov $FS_subjdir/${subj}${sess_t1}/mri/norm.mgz --targ $FS_subjdir/$subj/mri/norm_template.mgz --lta $FS_subjdir/$subj/mri/transforms/${subj}${sess_t1}_to_${subj}.lta --fslregout $featdir/reg_longt/${subj}${sess_t1}_to_${subj}.mat --reg $tmpdir/deleteme.reg.dat 1>/dev/null
              
              echo "BOLD : subj $subj , sess $sess : using FS's bbreg to register 'example_func.nii.gz' -> FS's structural (ID '${subj}${sess_t1}')..."
              bbregister --s ${subj}${sess_t1} --mov $featdir/example_func.nii.gz --init-fsl --reg $featdir/reg_longt/example_func2highres_bbr.dat --t2 --fslmat $featdir/reg_longt/example_func2highres_bbr.mat 1>/dev/null
              
              echo "BOLD : subj $subj , sess $sess : writing example_func -> FS's structural..."
              mri_convert $FS_subjdir/${subj}${sess_t1}/mri/T1.mgz $featdir/reg_longt/T1.nii.gz 1>/dev/null
              flirt -in $featdir/example_func.nii.gz -ref $featdir/reg_longt/T1.nii.gz -init $featdir/reg_longt/example_func2highres_bbr.mat -applyxfm -out $featdir/reg_longt/example_func2highres_bbr
              fslreorient2std $featdir/reg_longt/T1 $featdir/reg_longt/highres
              fslreorient2std $featdir/reg_longt/example_func2highres_bbr $featdir/reg_longt/example_func2highres_bbr
              imrm $featdir/reg_longt/T1
              
              echo "BOLD : subj $subj , sess $sess : concatenating matrices..."
              convert_xfm -omat $affine -concat $featdir/reg_longt/${subj}${sess_t1}_to_${subj}.mat $featdir/reg_longt/example_func2highres_bbr.mat              
              
            else
            
              T1_file=$featdir/reg/highres
              MNI_file=$featdir/reg/standard
              affine=$featdir/reg/example_func2highres.mat
              warp=$featdir/reg/highres2standard_warp
              ltag=""
            
            fi

            # execute...
            for data_file in $BOLD_MNI_RESAMPLE_FUNCDATAS ; do
              
              if [ $(imtest $featdir/$data_file) != 1 ] ; then
                  echo "BOLD : subj $subj , sess $sess : WARNING : volume '$featdir/$data_file' not found -> this file cannot be written out in MNI-space. Continuing loop..."
                  continue
              fi
              in_file=$featdir/$(remove_ext $data_file)
              
              for mni_res in $BOLD_MNI_RESAMPLE_RESOLUTIONS ; do

                _mni_res=$(echo $mni_res | sed "s|\.||g") # remove '.'
                                  
                out_file=$featdir/reg_standard/$(basename $in_file)${ltag}_mni${_mni_res}
                resampled_MNI_file=$featdir/reg_standard/$(basename $MNI_file)_${_mni_res}.nii.gz
                MNI_T1_file=$featdir/reg_standard/$(basename $T1_file)_${_mni_res}.nii.gz
                cmd_file=$featdir/mni_write_$(basename $in_file)${ltag}_res${_mni_res}.cmd
                log_file=bold_write_MNI_$(basename $in_file)${ltag}_res${_mni_res}_$(subjsess)
                
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
                echo "$scriptdir/feat_writeMNI.sh $in_file $T1_file $MNI_file $out_file $mni_res $affine $warp $interp $subj $sess" > $cmd_file
                
                fsl_sub -l $logdir -N $log_file -t $cmd_file 
                
                # link...
                echo "BOLD : subj $subj , sess $sess : creating symlink to MNI-registered 4D BOLD."
                lname=$(echo "$featdir" | sed "s|"uw[+-0][y0]"|"uw"|g") # remove unwarp direction from link's name
                ln -sfv ./$(basename $featdir)/reg_standard/$(basename $out_file).nii.gz ${lname%.feat}_$(basename $out_file).nii.gz

              done # end mni_res            
            done # end data_file
          done # end stc_val
        done # end sm_krnl
      done # end hpf_cut
    
    done
  done
    
fi

######################
# ----- END BOLD -----
######################


waitIfBusy


################################
# ----- BEGIN PLOT_BOLD_MC -----
################################

if [ $PLOT_BOLD_MC -eq 1 ] ; then
  echo "----- BEGIN PLOT_BOLD_MC -----"
  
  if [ -z "$PLOT_BOLD_MC_DIRNAMES" ] ; then echo "PLOT_BOLD_MC : WARNING : no directory specified." ; fi
  
  for dirnm in $PLOT_BOLD_MC_DIRNAMES ; do
    appends=""
    for subj in `cat $subjdir/subjects` ; do
      j=0
      for sess in `cat $subjdir/$subj/sessions_func` ; do
        
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
        cmd="pngappend $disp + $rot + $trans $(subjsess)_mc.png"
        echo $cmd ; $cmd

        dirnm_base0=$(basename $(dirname $(dirname $(dirname $disp)))) ; dirnm_base1=$(basename $(dirname $(dirname $disp)))
        montage -label "$(subjsess) ($dirnm_base1)" -pointsize 10 -geometry ^ $(subjsess)_mc.png  $(subjsess)_mc.png
        
        if [ -z "$appends" ] ; then 
          appends=$(subjsess)_mc.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$(subjsess)_mc.png 
        else
          appends=$appends" - "$(subjsess)_mc.png 
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done    

    if [ ! -z "$appends" ] ; then
      echo "PLOT_BOLD_MC : creating overall plot..."
      cmd="pngappend $appends plot_mc_bold_${dirnm}.png"
      echo $cmd ; $cmd
      echo "PLOT_BOLD_MC : cleaning up..."
      rm -f $subjdir/*_mc.png
    else
      echo "PLOT_BOLD_MC : nothing to plot."
    fi    

  done
fi

##############################
# ----- END PLOT_BOLD_MC -----
##############################


waitIfBusy


####################################
# ----- BEGIN PLOT_BOLD_UNWARP -----
####################################

if [ $PLOT_BOLD_UNWARP -eq 1 ] ; then
  echo "----- BEGIN PLOT_BOLD_UNWARP -----"
  
  if [ -z "$PLOT_BOLD_UNWARP_DIRNAMES" ] ; then echo "PLOT_BOLD_UNWARP : WARNING : no directory specified." ; fi
  
  for dirnm in $PLOT_BOLD_UNWARP_DIRNAMES ; do
    appends=""
    for subj in `cat $subjdir/subjects` ; do
      j=0
      for sess in `cat $subjdir/$subj/sessions_func` ; do
        
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
        cmd="slicer -s 2 $bold_D $(dirname $bold_UD)/EF_UD_fmap_mag_brain.nii.gz -a $(subjsess)_bold_D2fmap.png"
        $cmd
        echo "PLOT_BOLD_UNWARP : subj $subj , sess $sess : processing '$bold_UD'..."
        cmd="slicer -s 2 $bold_UD $(dirname $bold_UD)/EF_UD_fmap_mag_brain.nii.gz -a $(subjsess)_bold_UD2fmap.png"
        $cmd
        
        #montage -label "D" -pointsize 9  $(subjsess)_bold_D2fmap.png  $(subjsess)_bold_D2fmap.png 
        #montage -label "UD" -pointsize 9  $(subjsess)_bold_UD2fmap.png  $(subjsess)_bold_UD2fmap.png 
        
        dirnm_base0=$(basename $(dirname $(dirname $(dirname $bold_UD)))) ; dirnm_base1=$(basename $(dirname $(dirname $bold_UD)))
        montage -adjoin $(subjsess)_bold_D2fmap.png $(subjsess)_bold_UD2fmap.png -geometry ^ $(subjsess)_bold2mag.png
        montage -label "D vs UD \n$(subjsess) ($dirnm_base0/\n$dirnm_base1)" -pointsize 9 -geometry ^ $(subjsess)_bold2mag.png $(subjsess)_bold2mag.png
        rm -f $(subjsess)_bold_D2fmap.png $(subjsess)_bold_UD2fmap.png
        
        if [ -z "$appends" ] ; then 
          appends=$(subjsess)_bold2mag.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$(subjsess)_bold2mag.png
        else
          appends=$appends" - "$(subjsess)_bold2mag.png
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done
    
    if [ ! -z "$appends" ] ; then
      echo "PLOT_BOLD_UNWARP : creating overall plot..."
      cmd="pngappend $appends plot_bold2mag_${dirnm}.png"
      echo $cmd ; $cmd        
      echo "PLOT_BOLD_UNWARP : cleaning up..."
      rm -f $subjdir/*_bold2mag.png
    else 
      echo "PLOT_BOLD_UNWARP : nothing to plot."
    fi

  done
fi

##################################
# ----- END PLOT_BOLD_UNWARP -----
##################################


waitIfBusy


###################################
# ----- BEGIN PLOT_BOLD_T1REG -----
###################################

if [ $PLOT_BOLD_T1REG -eq 1 ] ; then
  echo "----- BEGIN PLOT_BOLD_T1REG -----"
  
  if [ -z "$PLOT_BOLD_T1REG_DIRNAMES" ] ; then echo "PLOT_BOLD_T1REG : WARNING : no directory specified." ; fi
  
  for dirnm in $PLOT_BOLD_T1REG_DIRNAMES ; do
    appends="" 
    
    for subj in `cat $subjdir/subjects` ; do
      j=0
      for sess in `cat $subjdir/$subj/sessions_func` ; do
      
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
        montage -label "$(subjsess) ($dirnm_base0/\n$dirnm_base1)" -pointsize 42 $png -geometry ^ $subjdir/$(subjsess)_func2t1.png 
        
        if [ -z "$appends" ] ; then 
          appends=$(subjsess)_func2t1.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$(subjsess)_func2t1.png
        else
          appends=$appends" + "$(subjsess)_func2t1.png
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done
    
    if [ ! -z "$appends" ] ; then
      echo "PLOT_BOLD_T1REG : creating overall plot..."
      cmd="pngappend $appends plot_func2t1_bold_${dirnm}.png"
      echo $cmd ; $cmd    
      echo "PLOT_BOLD_T1REG : cleaning up..."
      rm -f $subjdir/*_func2t1.png    
    else
      echo "PLOT_BOLD_T1REG : nothing to plot."
    fi
    
  done
fi

#################################
# ----- END PLOT_BOLD_T1REG -----
#################################


waitIfBusy


####################################
# ----- BEGIN PLOT_BOLD_MNIREG -----
####################################

if [ $PLOT_BOLD_MNIREG -eq 1 ] ; then
  echo "----- BEGIN PLOT_BOLD_MNIREG -----"
  
  if [ -z "$PLOT_BOLD_MNIREG_DIRNAMES" ] ; then echo "PLOT_BOLD_MNIREG : WARNING : no directory specified." ; fi
  
  for dirnm in $PLOT_BOLD_MNIREG_DIRNAMES ; do
    appends="" 
    #for subj in `cat $subjdir/subjects` ; do
      #j=0
      #for sess in `cat $subjdir/$subj/sessions_func` ; do
      
        #n=$(find $subjdir/$subj/$sess -mindepth 4 -maxdepth 4 -name filtered_func_data*.nii.gz -type f | grep $dirnm | grep /reg_standard | wc -l)
        #if [ $n -gt 1 ] ; then
          #echo "WARNING : search pattern matches more than one directory:"
          #echo "$(find $subjdir/$subj/$sess -mindepth 4 -maxdepth 4 -name filtered_func_data*.nii.gz -type f | grep $dirnm | grep /reg_standard | xargs ls -rt | xargs -I {} dirname {} )"
          #echo "...taking the last one, because it is newer."
        #fi
        #bold=$(find $subjdir/$subj/$sess -mindepth 4 -maxdepth 4 -name filtered_func_data*.nii.gz -type f | grep $dirnm | grep /reg_standard | xargs ls -rt | grep filtered_func_data | tail -n 1)
        #if [ -z $bold ] ; then echo "PLOT_BOLD_MNIREG : subj $subj , sess $sess : WARNING : no 'filtered_func_data' file found under '*${dirnm}*' - continuing loop..." ; continue ; fi
        
        ##echo "find $subjdir/$subj/$sess -maxdepth 4 -name filtered_func_data*.nii.gz -type f | grep $dirnm | grep /reg_standard | xargs ls -rt | grep filtered_func_data | tail -n 1)"
        #echo "PLOT_BOLD_MNIREG : subj $subj , sess $sess : processing '$bold'..."
        #cmd="slicer -s 2 $(dirname $bold)/standard.nii.gz $bold -a $(subjsess)_func2std.png"
        #$cmd
        
        #dirnm_base1=$(basename $(dirname $(dirname $bold))) ; dirnm_base0=$(basename $(dirname $(dirname $(dirname $bold))))
        #montage -label "$(subjsess) ($dirnm_base0/\n$dirnm_base1)" -pointsize 9 $subjdir/$(subjsess)_func2std.png -geometry ^ $subjdir/$(subjsess)_func2std.png 
        
        #if [ -z "$appends" ] ; then 
          #appends=$(subjsess)_func2std.png 
        #elif [ $j = "0" ] ; then
          #appends=$appends" - "$(subjsess)_func2std.png
        #else
          #appends=$appends" + "$(subjsess)_func2std.png
        #fi
        #j=$(echo "$j + 1" | bc -l)
      #done
    #done
    
    for subj in `cat $subjdir/subjects` ; do
      j=0
      for sess in `cat $subjdir/$subj/sessions_func` ; do
      
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
        montage -label "$(subjsess) ($dirnm_base0/\n$dirnm_base1)" -pointsize 16 $png -geometry ^ $subjdir/$(subjsess)_func2std.png 
        
        if [ -z "$appends" ] ; then 
          appends=$(subjsess)_func2std.png 
        elif [ $j = "0" ] ; then
          appends=$appends" - "$(subjsess)_func2std.png
        else
          appends=$appends" + "$(subjsess)_func2std.png
        fi
        j=$(echo "$j + 1" | bc -l)
      done
    done
    
    if [ ! -z "$appends" ] ; then
      echo "PLOT_BOLD_MNIREG : creating overall plot..."
      cmd="pngappend $appends plot_func2std_bold_${dirnm}.png"
      echo $cmd ; $cmd    
      echo "PLOT_BOLD_MNIREG : cleaning up..."
      rm -f $subjdir/*_func2std.png    
    else
      echo "PLOT_BOLD_MNIREG : nothing to plot."
    fi
    
  done
fi

##################################
# ----- END PLOT_BOLD_MNIREG -----
##################################


waitIfBusy


#####################################
#####################################
# ----- BEGIN 2nLevel Analyses -----#
#####################################
#####################################

# change to 2nd level directory
cd $grpdir

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
      if [ ! -d $statdir ] ; then echo "TBSS: <$statdir> not found - continuing loop..." ; continue ; fi
    
      echo "TBSS: copying GLM designs to $statdir"
      cat $glmdir_tbss/designs | xargs -I{} cp -r $glmdir_tbss/{} $statdir; cp $glmdir_tbss/designs $statdir
      echo "TBSS: starting permutations..."
      _randomise $statdir tbss "all_FA_skeletonised" "-m ../mean_FA_skeleton_mask -d design.mat -t design.con -e design.grp --T2 -V -D -x -n $TBSS_RANDOMISE_NPERM" $TBSS_Z_TRANSFORM mean_FA_skeleton_mask.nii.gz $RANDOMISE_PARALLEL

    done
  done
fi

waitIfBusy

# TBSS prepare TBSSX
if [ $TBSS_STG4 -eq 1 ] ; then
  echo "----- BEGIN TBSS_STG4 -----"
  ## bedpostX files present ?
  #if [ ! -d $FS_subjdir/$(subjsess)/dmri.bedpostX ] ; then echo "TBSSX: dmri.bedpostX directory not found for TBSSX - you must run TRACULA first. Exiting ..." ; exit ; fi
  
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
    if [ ! $tbss_dir ] ; then echo "TBSS: $tbss_dir not found - exiting..." ; exit ; fi
    
    # define dti type
    FA_type=$(basename $tbss_dir | sed "s|^${TBSS_OUTDIR_PREFIX}_||g")
    
    # change directory
    echo "TBSSX: changing to <$tbss_dir>"
    cd  $tbss_dir
      if [ ! -d stats -a ! -d _stats ] ; then echo "TBSSX: $tbss_dir/[_]stats not found - you must run the TBSS stream first; exiting..." ; exit ; fi
       
      # cleanup prev. runs
      rm -f F1/* F2/* D1/* D2/*       
      
      # create TBSSX directories
      mkdir -p F1 F2 D1 D2
       
      if [ $TBSS_USE_BPX_FROM_TRACULA -eq 1 ] ; then
        # copy bedpostX files from TRACULA
        for subj in $TBSS_INCLUDED_SUBJECTS ; do
          for sess in $TBSS_INCLUDED_SESSIONS ; do
            fname=$(subjsess)_dti_${FA_type}_FA.nii.gz
            if [ ! -d $FS_subjdir/$(subjsess)/dmri.bedpostX ] ; then echo "TBSSX: ERROR: directory '$FS_subjdir/$(subjsess)/dmri.bedpostX' not found  - you must run the TRACULA stream first..." ; exit ; fi
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
        if [ $errflag -eq 1 ] ; then echo "... exiting." ; exit ; fi
        
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
        ln -sfnv `basename $statdir` stats # mind the -n option, otw. the dir-link is not overwritten on each iteration (!)
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
      if [ ! -d $statdir ] ; then echo "TBSSX: <$statdir> not found - continuing loop..." ; continue ; fi
    
      echo "TBSSX: copying GLM designs to $statdir"
      cat $glmdir_tbss/designs | xargs -I{} cp -r $glmdir_tbss/{} $statdir; cp $glmdir_tbss/designs $statdir
      echo "TBSSX: starting permutations..."
      _randomise $statdir tbssxF1 "all_F1_x_skeletonised" "-m ../mean_FA_skeleton_mask -d design.mat -t design.con -e design.grp --T2 -V -D -x -n $TBSS_RANDOMISE_NPERM" $TBSS_Z_TRANSFORM mean_FA_skeleton_mask.nii.gz $RANDOMISE_PARALLEL
      _randomise $statdir tbssxF2 "all_F2_x_skeletonised" "-m ../mean_FA_skeleton_mask -d design.mat -t design.con -e design.grp --T2 -V -D -x -n $TBSS_RANDOMISE_NPERM" $TBSS_Z_TRANSFORM mean_FA_skeleton_mask.nii.gz $RANDOMISE_PARALLEL
    done
  done
fi

######################
# ----- END TBSS -----
######################


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
    statdirs=`find $vbmdir -maxdepth 2 -mindepth 2 -type d  | sort | grep stats_s${krnl} || true` # added '|| true' to avoid abortion by 'set -e' statement
    if [ "x$statdirs" = "x" ] ; then echo "VBM_2NDLEV : no stats directories found - continuing loop..." ; continue ; fi
    
    for i in $statdirs ; do
      echo "VBM_2NDLEV : copying GLM designs to $i"
      cat $glmdir_vbm/designs | xargs -I{} cp -r $glmdir_vbm/{} $i; cp $glmdir_vbm/designs $i
      echo "VBM_2NDLEV : starting permutations..."
      _randomise $i vbm "GM_mod_merg_smoothed" "-m ../GM_mask -d design.mat -t design.con -e design.grp -T -V -D -x -n $VBM_RANDOMISE_NPERM" $VBM_Z_TRANSFORM GM_mask.nii.gz $RANDOMISE_PARALLEL
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
  fldr=$grpdir/melodic ; mkdir -p $fldr
  conffile=$fldr/${MELODIC_OUTDIRNAME}_$(remove_ext $MELODIC_INPUT_FILE).fsf
  templateICA=$grpdir/$MELODIC_TEMPLATE_FILENAME
  
  echo "MELODIC_GROUP: creating MELODIC configuration file '$conffile'..."
 
  if [ ! -f $templateICA ] ; then echo "MELODIC_GROUP: ERROR: MELODIC template file not found - exiting..." ; exit ; fi
  if [ ! -f $subjdir/config_func2highres.reg ] ; then echo "MELODIC_GROUP: ERROR: registration mapping between functionals and t1 reference not found - exiting..." ; exit ; fi

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
      echo "set feat_files($n) \"$(remove_ext $bold)\"" >> $conffile # remove extension, otw. *.ica directories are not properly named (!)
      
      #sess_t1=`cat $subjdir/config_func2highres.reg | grep ^$(subjsess) | cut -f2`
      line=`cat $subjdir/config_func2highres.reg | awk '{print $1}' | grep -nx $(subjsess) | cut -d : -f1`
      sess_t1=`cat $subjdir/config_func2highres.reg | awk '{print $2}' | sed -n ${line}p `
      if [ $sess_t1 = '.' ] ; then sess_t1="" ; fi # single-session design
      t1_brain=$grpdir/melodic/${subj}${sess_t1}_t1_brain
      
      echo "MELODIC_GROUP: using t1_brain from session '$sess_t1' as reference for '$bold'"
      echo "# Subject's structural image for analysis $n" >> $conffile
      echo "set highres_files($n) \"$t1_brain\"" >> $conffile # no file extension here, otw. the non-brain extracted T1 is not found and non-linear registration will become highly inaccurate (feat does not throw an error here!) (!)  
    done
  done
  
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
      
      cmd="ln -sfv ../../$(basename $subjdir)/$subj/$sess_t1/vbm/$(basename $melodic_t1struc) $grpdir/melodic/$(subjsess)_t1.nii.gz" ; $cmd
      cmd="ln -sfv ../../$(basename $subjdir)/$subj/$sess_t1/vbm/$(basename $melodic_t1brain) $grpdir/melodic/$(subjsess)_t1_brain.nii.gz " ; $cmd
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
    
    fldr=$grpdir/melodic/${MELODIC_CMD_OUTDIR_PREFIX}_$(remove_ext $melodic_input).gica
    
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
        
        if [ ! -f $bold ] ; then echo "MELODIC_CMD : subj $subj , sess $sess : ERROR : input file '$bold' not found - continuing loop..." ; err=1 ; continue ; fi
        
        echo "MELODIC_CMD  subj $subj , sess $sess : adding input-file '$bold'"
        echo $bold | tee -a $fldr/input.files
      
      done
    done
    
    if [ $err -eq 1 ] ; then echo "MELODIC_CMD : an ERROR has occurred - exiting..." ; exit ; fi
    
    # shall we bet ?
    opts=""
    if [ $MELODIC_CMD_BET -eq 0 ] ; then opts="--nobet --bgthreshold=10" ; fi
    
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

  for DUALREG_INPUT_ICA_DIRNAME in $DUALREG_INPUT_ICA_DIRNAMES ; do
    if [ $DUALREG_COMPATIBILITY -eq 0 ] ; then
      # this applies when MELODIC-GUI was used
      if [ -f $grpdir/melodic/${DUALREG_INPUT_ICA_DIRNAME}.fsf ] ; then
        echo "DUALREG : taking basic input filename from '${DUALREG_INPUT_ICA_DIRNAME}.fsf' (first entry therein)"
        _inputfile=$(basename $(cat $grpdir/melodic/${DUALREG_INPUT_ICA_DIRNAME}.fsf | grep "set feat_files(1)" | cut -d "\"" -f 2))  # get inputfile basename from melodic *.fsf file... (assuming same basename for all included subjects/sessions) (!)
        _inputfile=$(remove_ext $_inputfile)_${DUALREG_INPUT_ICA_DIRNAME}.ica/reg_standard/filtered_func_data.nii.gz
      # this applies when MELODIC command line tool was used
      elif [ -f $grpdir/melodic/${DUALREG_INPUT_ICA_DIRNAME}.gica/input.files ] ; then
        echo "DUALREG : taking basic input filename from '${DUALREG_INPUT_ICA_DIRNAME}.gica/input.files' (first entry therein)"
        _inputfile=$(basename $(head -n 1 $grpdir/melodic/${DUALREG_INPUT_ICA_DIRNAME}.gica/input.files)) # get inputfile basename from melodic input-file list...(assuming same basename for all included subjects/sessions) (!)
      fi
    fi

    # gather input-files
    inputfiles="" ; inputfile=""
    for subj in $DUALREG_INCLUDED_SUBJECTS ; do
      for sess in $DUALREG_INCLUDED_SESSIONS ; do        
        # test if inputfile is present
        if [ $DUALREG_COMPATIBILITY -eq 0 ] ; then
          inputfile=$subjdir/$subj/$sess/bold/${_inputfile}
        else
          inputfile=$(find $subjdir/$subj/$sess/ -maxdepth 4 -name filtered_func_data.nii.gz -type f | grep `remove_ext $DUALREG_INPUT_BOLD_STDSPC_FILE`_${DUALREG_INPUT_ICA_DIRNAME}.ica/reg_standard | xargs ls -rt | grep filtered_func_data.nii.gz | tail -n 1) # added '|| true' to avoid abortion by 'set -e' statement
          if [ -z $inputfile ] ; then echo "DUALREG : subj $subj , sess $sess : standard-space registered input file '$DUALREG_INPUT_BOLD_STDSPC_FILE' not defined - continuing..." ; continue ; fi
        fi
        
        if [ ! -f $inputfile ] ; then echo "DUALREG : subj $subj , sess $sess : standard-space registered input file '$inputfile' not found - continuing..." ; continue ; fi
        

        if [ `echo "$inputfile"|wc -w` -gt 1 ] ; then 
          echo "DUALREG : subj $subj , sess $sess : WARNING : more than one standard-space registered input file detected:"
          echo "DUALREG : subj $subj , sess $sess :           '$inputfile'"
          inputfile=`echo $inputfile | row2col | tail -n 1`
          echo "DUALREG : subj $subj , sess $sess :           taking the latest one:"
          echo "DUALREG : subj $subj , sess $sess :           '$inputfile'"
        fi
        echo "DUALREG : subj $subj , sess $sess : adding standard-space registered input file '$inputfile'"
        inputfiles=$inputfiles" "$inputfile
      done
    done
    
    # check if number of rows in design file and number of input-files 
    if [ ! -f $glmdir_dr/designs ] ; then echo "DUALREG : file '$glmdir_dr/designs' not found - exiting..." ; exit ; fi
    if [ -z "$(cat $glmdir_dr/designs)" ] ; then echo "DUALREG : no designs specified in file '$glmdir_dr/designs' - exiting..." ; exit ; fi
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
      ICfile=$grpdir/melodic/${DUALREG_INPUT_ICA_DIRNAME}.gica/groupmelodic.ica/${IC_fname}
      dr_outdir=$dregdir/${DUALREG_OUTDIR_PREFIX}_${DUALREG_INPUT_ICA_DIRNAME}_$(remove_ext $IC_fname)
      if [ ! -f $ICfile ] ; then echo "DUALREG : ERROR : group-level IC file '$ICfile' not found - exiting..." ; exit ; fi
      
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
      
      # executing dualreg...
      echo "DUALREG : executing dualreg script on group-level ICs in '$ICfile' - writing to folder '$dr_outdir'..."
      
      cmd="$scriptdir/dualreg.sh $ICfile 1 dummy.mat dummy.con dummy.grp dummy.randcmd $DUALREG_NPERM $dr_outdir 1 0 0 $(cat $dr_outdir/inputfiles)" ; echo "$cmd" > $dr_outdir/dualreg_prep.cmd
      $cmd ; waitIfBusy
      
      cmd="$scriptdir/dualreg.sh $ICfile 1 dummy.mat dummy.con dummy.grp dummy.randcmd $DUALREG_NPERM $dr_outdir 0 1 0 $(cat $dr_outdir/inputfiles)" ; echo "$cmd" >> $dr_outdir/dualreg_prep.cmd
      $cmd ; waitIfBusy
    done
  done
fi

waitIfBusy

# DUALREG execute randomise call
if [ $DUALREG_STG2 -eq 1 ] ; then
  echo "----- BEGIN DUALREG_STG2 -----"
  for DUALREG_INPUT_ICA_DIRNAME in $DUALREG_INPUT_ICA_DIRNAMES ; do
    for IC_fname in $DUALREG_IC_FILENAMES ; do
      dr_outdir=$dregdir/${DUALREG_OUTDIR_PREFIX}_${DUALREG_INPUT_ICA_DIRNAME}_$(remove_ext $IC_fname)
      ICfile=$grpdir/melodic/${DUALREG_INPUT_ICA_DIRNAME}.gica/groupmelodic.ica/${IC_fname}
      if [ ! -d $dr_outdir ] ; then echo "DUALREG : ERROR : output directory '$dr_outdir' not found - exiting..." ; exit ; fi
      if [ ! -f $dr_outdir/inputfiles ] ; then echo "DUALREG : ERROR : inputfiles textfile not found, you must run stage1 first - exiting..." ; exit ; fi
      if [ ! -f $ICfile ] ; then echo "DUALREG : ERROR : group-level IC file '$ICfile' not found - exiting..." ; exit ; fi

      echo "DUALREG : using output-directory '$dr_outdir'..."
      
      # check if number of rows in design file and number of input-files 
      if [ ! -f $glmdir_dr/designs ] ; then echo "DUALREG : file '$glmdir_dr/designs' not found - exiting..." ; exit ; fi
      if [ -z "$(cat $glmdir_dr/designs)" ] ; then echo "DUALREG : no designs specified in file '$glmdir_dr/designs' - exiting..." ; exit ; fi
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
              #rm -rf $dr_outdir/stats/$dr_glm_name/dr_stage3_*_logs
              #rm -f $dr_outdir/stats/$dr_glm_name/dr_stage3_*SEED*.nii.gz 
              #rm -f $dr_outdir/stats/$dr_glm_name/dr_stage3_*.generate
              #rm -f $dr_outdir/stats/$dr_glm_name/dr_stage3_*.defragment
              #rm -rf $dr_outdir/stats/$dr_glm_name/dr_stage3_${dr_glm_name}_*_logs
              #rm -f $dr_outdir/stats/$dr_glm_name/dr_stage3_${dr_glm_name}_*.nii.gz 
              #rm -f $dr_outdir/stats/$dr_glm_name/dr_stage3_${dr_glm_name}_*.generate
              #rm -f $dr_outdir/stats/$dr_glm_name/dr_stage3_${dr_glm_name}_*.defragment
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
        mkdir -p $dr_outdir/stats ; cp -r $glmdir_dr/$dr_glm_name $dr_outdir/stats/ ; cp $ICfile $dr_outdir/stats/
        echo "DUALREG : calling '$RANDCMD' for folder '$dr_outdir/stats/$dr_glm_name' ($DUALREG_NPERM permutations)."
        cmd="${scriptdir}/dualreg.sh $ICfile 1 $glmdir_dr/$dr_glm_name/design.mat $glmdir_dr/$dr_glm_name/design.con $glmdir_dr/$dr_glm_name/design.grp $RANDCMD $DUALREG_NPERM $dr_outdir 0 0 1 $(cat $dr_outdir/inputfiles)" ; echo "$cmd" > $dr_outdir/dualreg_rand_${dr_glm_name}.cmd
        $cmd ; waitIfBusy # CAVE: waiting here is necessary, otherwise the drD script is deleted before its execution is finished... (!)
      done
    done
  done
fi

#########################
# ----- END DUALREG -----
#########################


waitIfBusy


#############################
# ----- BEGIN PSEUDOSWI -----
#############################

# PSEUDOSWI register fieldmap to MNI
if [ $PSEUDOSWI_STG1 -eq 1 ]; then
  echo "----- BEGIN PSEUDOSWI_STG1 -----"
  for subj in `cat $subjdir/subjects` ; do
    for sess in `cat $subjdir/$subj/sessions_func` ; do
      fldr=$subjdir/$subj/$sess/fm
      fmap=$fldr/uphase_rad_filt
      fmap0=$fldr/fmap_rads_masked
      magn=$fldr/magn
      
      echo "PSEUDOSWI : subj $subj , sess $sess : registering `basename $fmap` and brain magnitude to MNI template - using transforms from latest .feat and .ica directories."
      
      FM_2_EF=`find $subjdir/$subj/$sess/ -name FM_2_EF.mat -type f | grep ".feat" | grep "/unwarp/" | xargs ls -rt | grep FM_2_EF.mat | grep -v /fdt/ | tail -n 1` # should be adapted (!)
      EF_2_T1=`find $subjdir/$subj/$sess/ -name example_func2highres.mat -type f | grep ".ica" | grep "/reg/" | xargs ls -rt | grep example_func2highres.mat | grep -v /fdt/ | tail -n 1` # should be adapted (!)
      T1_2_MNI=`dirname $EF_2_T1`/highres2standard_warp.nii.gz
      
      if [ ! -f $T1_2_MNI ] ; then echo "PSEUDOSWI : subj $subj , sess $sess : file '$T1_2_MNI' not found - continuing loop..." ; continue ; fi
      
      echo "PSEUDOSWI : subj $subj , sess $sess : fieldmap->bold:  $FM_2_EF"
      echo "PSEUDOSWI : subj $subj , sess $sess : bold->T1:        $EF_2_T1"
      echo "PSEUDOSWI : subj $subj , sess $sess : T1->MNI:         $T1_2_MNI"
        
      echo "PSEUDOSWI : subj $subj , sess $sess : concatenate matrices..."
      convert_xfm -omat $fldr/fm_to_t1.mat -concat $EF_2_T1 $FM_2_EF
      
      echo "PSEUDOSWI : subj $subj , sess $sess : apply transform to `basename $fmap`..."
      applywarp --ref=$FSLDIR/data/standard/MNI152_T1_2mm_brain --in=$fmap --out=$fldr/pseudoSWI_MNI --warp=$T1_2_MNI --premat=$fldr/fm_to_t1.mat
      
      echo "PSEUDOSWI : subj $subj , sess $sess : apply transform to `basename $fmap0`..."
      applywarp --ref=$FSLDIR/data/standard/MNI152_T1_2mm_brain --in=$fmap0 --out=$fldr/fmap_MNI --warp=$T1_2_MNI --premat=$fldr/fm_to_t1.mat
      
      echo "PSEUDOSWI : subj $subj , sess $sess : apply transform to `basename $magn`..."
      applywarp --ref=$FSLDIR/data/standard/MNI152_T1_2mm_brain --in=$magn --out=$fldr/magn_brain_MNI --warp=$T1_2_MNI --premat=$fldr/fm_to_t1.mat
    done
  done
fi

###########################
# ----- END PSEUDOSWI -----
###########################


waitIfBusy


cd $wd
date
echo "Exiting."
exit
