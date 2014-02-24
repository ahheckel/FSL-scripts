#!/bin/sh
# Original version by C. Beckmann. For more information see http://www.fmrib.ox.ac.uk/analysis/dualreg/dual_regression

# Adapted by HKL (11/22/2012): address sections (mask / dualreg / randomise) separately & insert exchangeability block file into randomise call & voxel-wise stats & naming of randomise results based on 
# the name of the design used & delete ${LOGDIR}/dr[ABCD] cmd-file to avoid accumulation on re-run. randomise_parallel or randomise are used on demand, randomise_parallel, however,
# only works if /bin/sh points to /bin/bash ! (!) High-pass filtered motion parameters can be used for dr_stage2.
# This script is self-submitting and should never be submitted to a cluster.

Usage() {
    cat <<EOF

dual_regression v0.5 (beta)

***NOTE*** ORDER OF COMMAND-LINE ARGUMENTS IS DIFFERENT FROM PREVIOUS VERSION

Usage: $(basename $0) <group_IC_maps> <des_norm> <design.mat> <design.con> <design.grp> <randomise||randomise_parallel> <n_perm> <output_directory> <USE_MOVPARS> <USE_MOVPARS_TR> <USE_MOVPARS_HPF> <USE_4DMASK> <DO_MASK> <DO_DUALREG> <DO_RANDOMISE> <ICOFINTEREST|all> <input1> <input2> <input3> .........
e.g.   $(basename $0) groupICA.gica/groupmelodic.ica/melodic_IC 1 design.mat design.con design.grp randomise_parallel 500 outdir 1,2,4,6 3.330 100 1 1 0 0,1,13,17,19 \`cat groupICA.gica/.filelist\`

<group_IC_maps_4D>                 4D image containing spatial IC maps (melodic_IC) from the whole-group ICA analysis
<des_norm>                         0 or 1 (1 is recommended). Whether to variance-normalise the timecourses used as the stage-2 regressors
<design.mat>                       Design matrix for final cross-subject modelling with randomise
<design.con>                       Design contrasts for final cross-subject modelling with randomise
<design.grp>                       Exchangeability block file
<randomise||randomise_parallel>    use either randomise or randomise_parallel (the latter will not work in FSLv5)
<n_perm>                           Number of permutations for randomise; set to 1 for just raw tstat output, set to 0 to not run randomise at all.
<output_directory>                 This directory will be created to hold all output and logfiles
<USE_MOVPARS>                      Use motion parameters as confound regressors (0:none, 1:c, 2:c^2, 3:abs(c), 4:[0;diff(c)], 5:[diff(c);0], 6:[0;diff(c)]^2, 7:[diff(c);0]^2)
<USE_MOVPARS_TR>                   TR for high pass filtering of motion parameters
<USE_MOVPARS_HPF>                  High pass filter cutoff (s), \"Inf\" to switch off
<USE_4DMASK>                       Restrict statistics to mask for each IC
<DO_MASK>                          Enable stage1
<DO_DUALREG>                       Enable stage2
<DO_RANDOMISE>                     Enable stage3
<ICOFINTEREST>                     Comma separated list of ICs of Interest (index in melodic_IC) starting with 0. Enter \"all\" for all ICs.
<input1> <input2> ...              List all subjects' preprocessed, standard-space 4D datasets
<design.mat> <design.con>          can be replaced with just
-1                                 for group-mean (one-group t-test) modelling.

If you need to add other randomise option then just edit the line after "EDIT HERE" below

EOF
    exit 1
}

function rem_blanks()
{
  local array="$1"
  local i=""
  for i in $array ; do echo -n $i ; done
}

############################################################################

[ "$6" = "" ] && Usage

ORIG_COMMAND=$*

ICA_MAPS=`${FSLDIR}/bin/remove_ext $1` ; shift

DES_NORM=--des_norm
if [ $1 = 0 ] ; then
  DES_NORM=""
fi ; shift

if [ $1 = "-1" ] ; then
  DESIGN="-1"
  shift
else
  dm=$1
  dc=$2
  dgrp=$3
  DESIGN="-d $1 -t $2 -e $3"
  RANDCMD="$4"
  shift 4
fi

NPERM=$1 ; shift

OUTPUT=`${FSLDIR}/bin/remove_ext $1` ; shift

USE_MOVPARS=$1 ; shift
USE_MOVPARS_TR=$1 ; shift
USE_MOVPARS_HPF=$1 ; shift
USE_4DMASK=$1 ; shift

DO_MASK=$1 ; shift
DO_DUALREG=$1 ; shift
DO_RANDOMISE=$1 ; shift
ICOFINTEREST="$1" ; shift

while [ _$1 != _ ] ; do
  INPUTS="$INPUTS `${FSLDIR}/bin/remove_ext $1`"
  shift
done

# rem commas (HKL)
USE_MOVPARS="$(echo "$USE_MOVPARS" | sed 's|,| |g')"
ICOFINTEREST="$(echo "$ICOFINTEREST" | sed 's|,| |g')" 

# rem blanks (HKL)
movpars_tag=$(rem_blanks "$USE_MOVPARS")

# create working dir. (HKL)
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap (HKL)
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

echo "`basename $0` : ICA_MAPS:        $ICA_MAPS"
echo "`basename $0` : DES_NORM:        $DES_NORM"
echo "`basename $0` : DESIGN:          $DESIGN"
echo "`basename $0` : NPERM:           $NPERM"
echo "`basename $0` : OUTPUT:          $OUTPUT"
echo "`basename $0` : USE_MOVPARS:     $USE_MOVPARS"
echo "`basename $0` : USE_MOVPARS_TR:  $USE_MOVPARS_TR"
echo "`basename $0` : USE_MOVPARS_HPF: $USE_MOVPARS_HPF"
echo "`basename $0` : DO_MASK:         $DO_MASK"
echo "`basename $0` : DO_DUALREG:      $DO_DUALREG"
echo "`basename $0` : DO_RANDOMISE:    $DO_RANDOMISE"
echo "`basename $0` : ICOFINTEREST:    $ICOFINTEREST"
echo "---------------------------"

mkdir -p $OUTPUT
LOGDIR=${OUTPUT}/scripts+logs
mkdir -p $LOGDIR
echo $ORIG_COMMAND > $LOGDIR/command
JID=1 # dummy jobID (HKL)


########################################################################
########################################################################


if [ $DO_MASK -eq 1 ] ; then

rm -f ${LOGDIR}/drA # delete cmd-file to avoid accumulation on re-run (HKL)
rm -f ${LOGDIR}/drB # delete cmd-file to avoid accumulation on re-run (HKL)

echo "`basename $0` : creating common mask"
j=0
for i in $INPUTS ; do
  echo "$FSLDIR/bin/fslmaths $i -Tstd -bin ${OUTPUT}/mask_`${FSLDIR}/bin/zeropad $j 5` -odt char" >> ${LOGDIR}/drA
  j=`echo "$j 1 + p" | dc -`
done
ID_drA=`$FSLDIR/bin/fsl_sub -T 10 -N drA -l $LOGDIR -t ${LOGDIR}/drA`
# this masking is sometimes too conservative...(HKL)
cat <<EOF > ${LOGDIR}/drB
#!/bin/sh
\$FSLDIR/bin/fslmerge -t ${OUTPUT}/maskALL \`\$FSLDIR/bin/imglob ${OUTPUT}/mask_*\`
\$FSLDIR/bin/fslmaths $OUTPUT/maskALL -Tmin $OUTPUT/mask
\$FSLDIR/bin/imrm $OUTPUT/mask_*
EOF
chmod a+x ${LOGDIR}/drB
JID=`$FSLDIR/bin/fsl_sub -j $ID_drA -T 5 -N drB -l $LOGDIR ${LOGDIR}/drB`
fi

########################################################################
########################################################################


if [ $DO_DUALREG -eq 1 ] ; then

rm -f ${LOGDIR}/drC # delete cmd-file to avoid accumulation on re-run (HKL)

# find motion parameter files... (added by HKL)
if [ x"$USE_MOVPARS" != "x0" ] ; then
  movpar=1 
  for i in $INPUTS ; do
    i=$(remove_ext $i)
    featdir=$(dirname $i)/$(readlink ${i}.nii.gz | cut -d / -f 2 | grep .feat$)
    movparfile=$featdir/mc/prefiltered_func_data_mcf.par
    echo "`basename $0` : detecting motion parameter file: '$movparfile'"
    if [ ! -f $movparfile ] ; then echo "`basename $0` : WARNING : motion-parameter file '$movparfile' does not exist." ; movpar=0 ; fi
  done
  # define motion related regressors and high-pass filter them... (HKL)
  if [ $movpar -eq 1 ] ; then
    j=0
    for i in $INPUTS ; do
      s=subject`${FSLDIR}/bin/zeropad $j 5`
      i=$(remove_ext $i)
      featdir=$(dirname $i)/$(readlink ${i}.nii.gz | cut -d / -f 2 | grep .feat$)
      movparfile=$featdir/mc/prefiltered_func_data_mcf.par      
      
      movpar_calc_list=""
      for calc in $USE_MOVPARS ; do
        if [ $calc -eq 1 ] ; then formula="output_precision(8); c" ; fi
        if [ $calc -eq 2 ] ; then formula="output_precision(8); c.*c" ; fi
        if [ $calc -eq 3 ] ; then formula="output_precision(8); abs(c)" ; fi
        if [ $calc -eq 4 ] ; then formula="output_precision(8); c=diff(c); c=[0 ; c]" ; fi
        if [ $calc -eq 5 ] ; then formula="output_precision(8); c=diff(c); c=[c ; 0]" ; fi
        if [ $calc -eq 6 ] ; then formula="output_precision(8); c=diff(c); c=[0 ; c]; c.*c" ; fi
        if [ $calc -eq 7 ] ; then formula="output_precision(8); c=diff(c); c=[c ; 0]; c.*c" ; fi
        echo "`basename $0` : applying OCTAVE formula '$formula' to motion parameter regressors in '$movparfile'..." 
        $(dirname $0)/textcalc.sh $movparfile "$formula" $tmpdir/movpar_${s}_calc${calc}
        movpar_calc_list=$movpar_calc_list" "$tmpdir/movpar_${s}_calc${calc}
      done
      paste -d " " $movpar_calc_list > $tmpdir/movpar_${s}
      
      $(dirname $0)/hpf_movpar.sh $tmpdir/movpar_${s} $OUTPUT/movpar${movpars_tag}_${s}.hpf${USE_MOVPARS_HPF} $USE_MOVPARS_HPF $USE_MOVPARS_TR
      j=`echo "$j 1 + p" | dc -`
      echo "---------------------------"
    done
  else
    echo "`basename $0` : ERROR : at least one motion parameter file is missing -> cannot include motion parameters as confounds in DUALREG-stage2... exiting." ; exit 1
  fi
else
  movpar=0 
fi
# end HKL

echo "`basename $0` : doing the dual regressions"
j=0
for i in $INPUTS ; do
  s=subject`${FSLDIR}/bin/zeropad $j 5`
  if [ $movpar -eq 1 ] ; then
  echo "$FSLDIR/bin/fsl_glm -i $i -d $ICA_MAPS -o $OUTPUT/_dr_stage1_${s}.txt --demean -m $OUTPUT/mask ; \
        paste $OUTPUT/_dr_stage1_${s}.txt $OUTPUT/movpar${movpars_tag}_${s}.hpf${USE_MOVPARS_HPF} > $OUTPUT/dr_stage1_${s}.txt ; \
        rm $OUTPUT/_dr_stage1_${s}.txt ; \
        $FSLDIR/bin/fsl_glm -i $i -d $OUTPUT/dr_stage1_${s}.txt -o $OUTPUT/dr_stage2_$s --out_z=$OUTPUT/dr_stage2_${s}_Z --demean -m $OUTPUT/mask $DES_NORM ; \
        $FSLDIR/bin/fslsplit $OUTPUT/dr_stage2_$s $OUTPUT/dr_stage2_${s}_ic" >> ${LOGDIR}/drC
  else
  echo "$FSLDIR/bin/fsl_glm -i $i -d $ICA_MAPS -o $OUTPUT/dr_stage1_${s}.txt --demean -m $OUTPUT/mask ; \
        $FSLDIR/bin/fsl_glm -i $i -d $OUTPUT/dr_stage1_${s}.txt -o $OUTPUT/dr_stage2_$s --out_z=$OUTPUT/dr_stage2_${s}_Z --demean -m $OUTPUT/mask $DES_NORM ; \
        $FSLDIR/bin/fslsplit $OUTPUT/dr_stage2_$s $OUTPUT/dr_stage2_${s}_ic" >> ${LOGDIR}/drC
  fi
  j=`echo "$j 1 + p" | dc -`
done
JID=`$FSLDIR/bin/fsl_sub -j $JID -T 30 -N drC -l $LOGDIR -t ${LOGDIR}/drC` # HKL removed  switch "-j $ID_drB"
fi


########################################################################
########################################################################


if [ $DO_RANDOMISE -eq 1 ] ; then

rm -f ${LOGDIR}/drD # delete cmd-file to avoid accumulation on re-run (HKL)

if [ "$DESIGN" != -1 ] ; then
  dname=$(echo `basename $(dirname $dm)`) # HKL: note that the design's name = the folder's name where the *.con, *.mat, etc. files reside.
  mkdir -p $OUTPUT/stats/$dname
  /bin/cp $dm $OUTPUT/stats/$dname/
  /bin/cp $dc $OUTPUT/stats/$dname/
  /bin/cp $dgrp $OUTPUT/stats/$dname/
  fcon=$(basename $dc) ; fcon="${fcon%.*}".fts
  if [ -f $(dirname $dc)/$fcon ] ; then # added by HKL
    cp $(dirname $dc)/$fcon $OUTPUT/stats/$dname/
    echo "`basename $0` : F-test contrast file is '$OUTPUT/stats/$dname/$fcon'"
    fopts="-f $OUTPUT/stats/$dname/$fcon"
  else 
    fopts=""
  fi
fi

echo "`basename $0` : sorting maps and running randomise on design '$dname'"
j=0
Nics=`$FSLDIR/bin/fslnvols $ICA_MAPS`
rm -f $OUTPUT/stats/$dname/randomise.cmd # added by HKL
while [ $j -lt $Nics ] ; do
  jj=`$FSLDIR/bin/zeropad $j 4`
  
  # only process ICs of Interest (HKL)
  skipit=1
  for nIC in $ICOFINTEREST ; do
    if [ "$nIC" = "all" ] ; then skipit=0 ; fi
    nIC=`$FSLDIR/bin/zeropad $nIC 4`
    if [ "$jj" = "$nIC" ] ; then skipit=0 ; fi
  done
  if [ $skipit -eq 1 ] ; then 
    echo "`basename $0` : Skipping randomise call on IC-index '$jj' in '$ICA_MAPS' as requested."
    j=`echo "$j 1 + p" | dc -`
    continue
  fi
  
  # check whether 4D mask is present (HKL)
  mask=$OUTPUT/mask
  if [ x"$USE_4DMASK" = "x1" ] ; then
    if [ $(imtest ${ICA_MAPS}_masks) -eq 1 ] ; then
      echo "`basename $0` : extracting mask from ${ICA_MAPS}_masks at pos. $j ..."
      fslroi ${ICA_MAPS}_masks $tmpdir/mask_${jj} j 1
      mask=$tmpdir/mask_${jj}
    else
      echo "`basename $0` : WARNING : 4D mask file '${ICA_MAPS}_masks' not found!"
    fi
  fi  
  
  # create cmd
  RAND=""
  if [ $NPERM -eq 1 ] ; then
    RAND="$FSLDIR/bin/${RANDCMD} -i $OUTPUT/dr_stage2_ic$jj -o $OUTPUT/stats/$dname/dr_stage3_ic$jj -m $mask $DESIGN -n 1 -V -R -x" # HKL added -x switch
  fi
  if [ $NPERM -gt 1 ] ; then
    # EDIT HERE
    RAND="$FSLDIR/bin/${RANDCMD} -i $OUTPUT/dr_stage2_ic$jj -o $OUTPUT/stats/$dname/dr_stage3_${dname}_ic$jj -m $mask $DESIGN -n $NPERM -T -V -x $fopts"  # randomise_parallel only works if /bin/sh points to /bin/bash ! (!) ; HKL added -x switch and $fopts
    echo $RAND >> $OUTPUT/stats/$dname/randomise.cmd # added by HKL
  fi

  echo "$FSLDIR/bin/fslmerge -t $OUTPUT/dr_stage2_ic$jj \`\$FSLDIR/bin/imglob $OUTPUT/dr_stage2_subject*_ic${jj}.*\` ; \
        $FSLDIR/bin/imrm \`\$FSLDIR/bin/imglob $OUTPUT/dr_stage2_subject*_ic${jj}.*\` ; $RAND" >> ${LOGDIR}/drD
  j=`echo "$j 1 + p" | dc -`
done # end while-loop
JID=`$FSLDIR/bin/fsl_sub -j $JID -T 60 -N drD -l $LOGDIR -t ${LOGDIR}/drD` # HKL removed  switch "-j $ID_drC"
fi
