#!/bin/sh


echo [`date`] [`hostname`] [`uname -a`] [`pwd`] [$0 $@] >> .fslvbmlog

mkdir -p stats
cd struc

echo "Now running the preprocessing steps and the pre-analyses"

/bin/rm -f fslvbm3a


for g in `$FSLDIR/bin/imglob *_longt-struc.*` ; do
  echo $g
  subj=$(echo $g | cut -d _ -f 1) ; _gg=$(imglob $subj*_struc.*) ;
  #echo "${FSLDIR}/bin/fsl_reg ${g}_GM template_GM ${g}_GM_to_template_GM -fnirt \"--config=GM_2_MNI152GM_2mm.cnf --jout=${g}_JAC_nl\"; \
        #$FSLDIR/bin/fslmaths ${g}_GM_to_template_GM -mul ${g}_JAC_nl ${g}_GM_to_template_GM_mod -odt float" >> fslvbm3a
  echo "${FSLDIR}/bin/fsl_reg ${g}_GM template_GM ${g}_GM_to_template_GM -flirt \"-init ${subj}_init.mat\" -fnirt \"--config=GM_2_MNI152GM_2mm.cnf --jout=${g}_JAC_nl\"" >> fslvbm3a
  for gg in $_gg ; do
    subjsess=$(echo $gg | cut -d _ -f 1) ;  gg_mat=${subjsess}_to_${subj}.mat
    echo "convert_xfm -omat ${gg}_GM_to_template_GM.mat ${g}_GM_to_template_GM.mat ${gg_mat} ;\
    applywarp -i ${gg}_GM -r template_GM -o ${gg}_GM_to_template_GM --premat=${gg}_GM_to_template_GM.mat -w ${g}_GM_to_template_GM_warp ;\
    $FSLDIR/bin/fslmaths ${gg}_GM_to_template_GM -mul ${g}_JAC_nl ${gg}_GM_to_template_GM_mod -odt float" >> fslvbm3aa
  done
done
#for g in `$FSLDIR/bin/imglob *_struc.*` ; do
  #echo $g
  #echo "${FSLDIR}/bin/fsl_reg ${g}_GM template_GM ${g}_GM_to_template_GM -fnirt \"--config=GM_2_MNI152GM_2mm.cnf --jout=${g}_JAC_nl\"; \
        #$FSLDIR/bin/fslmaths ${g}_GM_to_template_GM -mul ${g}_JAC_nl ${g}_GM_to_template_GM_mod -odt float" >> fslvbm3a
#done
chmod a+x fslvbm3a
chmod a+x fslvbm3aa
fslvbm3a_id=`${FSLDIR}/bin/fsl_sub -T 40 -N fslvbm3a -t ./fslvbm3a`
fslvbm3aa_id=`${FSLDIR}/bin/fsl_sub -j $fslvbm3a_id -T 40 -N fslvbm3aa -t ./fslvbm3aa`
echo Doing registrations: ID=$fslvbm3a_id

cd ../stats

cat <<stage_preproc2 > fslvbm3b
#!/bin/sh

\$FSLDIR/bin/imcp ../struc/template_GM template_GM

\$FSLDIR/bin/fslmerge -t GM_merg     \`\${FSLDIR}/bin/imglob ../struc/*_struc_GM_to_template_GM.*\`
\$FSLDIR/bin/fslmerge -t GM_mod_merg \`\${FSLDIR}/bin/imglob ../struc/*_struc_GM_to_template_GM_mod.*\`

\$FSLDIR/bin/fslmaths GM_merg -Tmean -thr 0.01 -bin GM_mask -odt char

/bin/cp ../design.* .

for i in GM_mod_merg ; do
  for j in 2 3 4 ; do
    \$FSLDIR/bin/fslmaths \$i -s \$j \${i}_s\${j} 
    \$FSLDIR/bin/randomise -i \${i}_s\${j} -o \${i}_s\${j} -m GM_mask -d design.mat -t design.con -V
  done
done

stage_preproc2

chmod a+x fslvbm3b

fslvbm3b_id=`${FSLDIR}/bin/fsl_sub -T 15 -N fslvbm3b -j $fslvbm3aa_id ./fslvbm3b`

echo Doing subject concatenation and initial randomise: ID=$fslvbm3b_id

echo "Once this has finished, run randomise with 5000 permutations on the 'best' smoothed 4D GM_mod_merg. We recommend using the -T (TFCE) option. For example:"
echo "randomise -i GM_mod_merg_s3 -o GM_mod_merg_s3 -m GM_mask -d design.mat -t design.con -n 5000 -T -V"

