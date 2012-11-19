#!/bin/sh


Usage() {
    echo ""
    echo "Usage: fslvbm_2_template [options]"
    echo ""
    echo "-n  : nonlinear registration (recommended)"
    echo "-a  : affine registration (discouraged)"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage

echo [`date`] [`hostname`] [`uname -a`] [`pwd`] [$0 $@] >> .fslvbmlog

HOWLONG=30
if [ $1 = -a ] ; then
    REG="-a"
    HOWLONG=5
fi

cd struc

T=${FSLDIR}/data/standard/tissuepriors/avg152T1_gray

### segmentation
/bin/rm -f fslvbm2a
for g in `$FSLDIR/bin/imglob *_longt-struc.*` ; do
    echo $g
    echo "$FSLDIR/bin/fast -R 0.3 -H 0.1 ${g}_brain ; \
          $FSLDIR/bin/immv ${g}_brain_pve_1 ${g}_GM" >> fslvbm2a
done
for gg in `$FSLDIR/bin/imglob *_struc.*` ; do
    echo $gg
    echo "$FSLDIR/bin/fast -R 0.3 -H 0.1 ${gg}_brain ; \
          $FSLDIR/bin/immv ${gg}_brain_pve_1 ${gg}_GM" >> fslvbm2a
done
chmod a+x fslvbm2a
fslvbm2a_id=`$FSLDIR/bin/fsl_sub -T 30 -N fslvbm2a -t ./fslvbm2a`
echo Running segmentation: ID=$fslvbm2a_id

### Estimation of the registration parameters of GM to grey matter standard template
/bin/rm -f fslvbm2b
for g in `$FSLDIR/bin/imglob *_longt-struc.*` ; do
  subj=$(echo $g | cut -d _ -f 1) ; _gg=$(imglob $subj*_struc.*) ;
  echo "flirt -in ${g} -ref $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -init LIA_to_LAS_conformed.mat -omat ${subj}_init.mat ;\
  ${FSLDIR}/bin/fsl_reg ${g}_GM $T ${g}_GM_to_T -a -flirt \"-init ${subj}_init.mat\"" >> fslvbm2b
  for gg in $_gg ; do
    subjsess=$(echo $gg | cut -d _ -f 1) ;  gg_mat=${subjsess}_to_${subj}.mat ; gg_lta=${subjsess}_to_${subj}.lta
    echo "tkregister2 --noedit --mov ${gg}.nii.gz --targ ${g}.nii.gz --lta $gg_lta --fslregout $gg_mat --reg deleteme.reg.dat  ;\
    convert_xfm -omat ${gg}_GM_to_T.mat ${g}_GM_to_T.mat ${gg_mat} ;\
    flirt -in ${gg}_GM -ref $T -init ${gg}_GM_to_T.mat -applyxfm -out ${gg}_GM_to_T" >> fslvbm2ba
  done 
done
#for g in `$FSLDIR/bin/imglob *_struc.*` ; do
  #echo "${FSLDIR}/bin/fsl_reg ${g}_GM $T ${g}_GM_to_T -a" >> fslvbm2b
#done
chmod a+x fslvbm2b
chmod a+x fslvbm2ba
fslvbm2b_id=`$FSLDIR/bin/fsl_sub -j $fslvbm2a_id -T $HOWLONG -N fslvbm2b -t ./fslvbm2b`
fslvbm2ba_id=`$FSLDIR/bin/fsl_sub -j $fslvbm2b_id -T $HOWLONG -N fslvbm2ba -t ./fslvbm2ba`

echo Running initial registration: ID=$fslvbm2b_id

### Creation of the GM template by averaging all (or following the template_list for) the GM_nl_0 and GM_xflipped_nl_0 images
cat <<stage_tpl3 > fslvbm2c
#!/bin/sh
if [ -f ../template_list ] ; then
    template_list=\`cat ../template_list\`
    template_list=\`\$FSLDIR/bin/remove_ext \$template_list\`
else
    template_list=\`echo *_longt-struc.* | sed 's/_struc\./\./g'\`
    template_list=\`\$FSLDIR/bin/remove_ext \$template_list | sort -u\`
    echo "WARNING - study-specific template will be created from ALL input data - may not be group-size matched!!!"
fi
for g in \$template_list ; do
    mergelist="\$mergelist \${g}_GM_to_T"
done
\$FSLDIR/bin/fslmerge -t template_4D_GM \$mergelist
\$FSLDIR/bin/fslmaths template_4D_GM -Tmean template_GM
\$FSLDIR/bin/fslswapdim template_GM -x y z template_GM_flipped
\$FSLDIR/bin/fslmaths template_GM -add template_GM_flipped -div 2 template_GM_init
stage_tpl3
chmod +x fslvbm2c
fslvbm2c_id=`fsl_sub -j $fslvbm2ba_id -T 15 -N fslvbm2c ./fslvbm2c`
echo Creating first-pass template: ID=$fslvbm2c_id

### Estimation of the registration parameters of GM to grey matter standard template
/bin/rm -f fslvbm2d
T=template_GM_init
for g in `$FSLDIR/bin/imglob *_longt-struc.*` ; do
  subj=$(echo $g | cut -d _ -f 1) ; _gg=$(imglob $subj*_struc.*) ;
  echo "${FSLDIR}/bin/fsl_reg ${g}_GM $T ${g}_GM_to_T_init $REG -flirt \"-init ${subj}_init.mat\" -fnirt \"--config=GM_2_MNI152GM_2mm.cnf\"" >> fslvbm2d
  for gg in $_gg ; do
    subjsess=$(echo $gg | cut -d _ -f 1) ;  gg_mat=${subjsess}_to_${subj}.mat
    echo "convert_xfm -omat ${gg}_GM_to_T_init.mat ${g}_GM_to_T_init.mat ${gg_mat} ;\
    applywarp -i ${gg}_GM -r $T -o ${gg}_GM_to_T_init --premat=${gg}_GM_to_T_init.mat -w ${g}_GM_to_T_init_warp" >> fslvbm2da
  done
done
chmod a+x fslvbm2d
chmod a+x fslvbm2da
fslvbm2d_id=`$FSLDIR/bin/fsl_sub -j $fslvbm2c_id -T $HOWLONG -N fslvbm2d -t ./fslvbm2d`
fslvbm2da_id=`$FSLDIR/bin/fsl_sub -j $fslvbm2d_id -T $HOWLONG -N fslvbm2da -t ./fslvbm2da`
echo Running registration to first-pass template: ID=$fslvbm2d_id

### Creation of the GM template by averaging all (or following the template_list for) the GM_nl_0 and GM_xflipped_nl_0 images
cat <<stage_tpl4 > fslvbm2e
#!/bin/sh
if [ -f ../template_list ] ; then
    template_list=\`cat ../template_list\`
    template_list=\`\$FSLDIR/bin/remove_ext \$template_list\`
else
    template_list=\`echo *_longt-struc.* | sed 's/_struc\./\./g'\`
    template_list=\`\$FSLDIR/bin/remove_ext \$template_list | sort -u\`
    echo "WARNING - study-specific template will be created from ALL input data - may not be group-size matched!!!"
fi
for g in \$template_list ; do
    mergelist="\$mergelist \${g}_GM_to_T_init"
done
\$FSLDIR/bin/fslmerge -t template_4D_GM \$mergelist
\$FSLDIR/bin/fslmaths template_4D_GM -Tmean template_GM
\$FSLDIR/bin/fslswapdim template_GM -x y z template_GM_flipped
\$FSLDIR/bin/fslmaths template_GM -add template_GM_flipped -div 2 template_GM
stage_tpl4
chmod +x fslvbm2e
fslvbm2e_id=`fsl_sub -j $fslvbm2da_id -T 15 -N fslvbm2e ./fslvbm2e`
echo Creating second-pass template: ID=$fslvbm2e_id

echo "Study-specific template will be created, when complete, check results with:"
echo "fslview struc/template_4D_GM"
echo "and turn on the movie loop to check all subjects, then run:"
echo "fslview " ${FSLDIR}/data/standard/tissuepriors/avg152T1_gray " struc/template_GM"
echo "to check general alignment of mean GM template vs. original standard space template."

