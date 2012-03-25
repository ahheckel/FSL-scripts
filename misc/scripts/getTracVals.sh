#!/bin/bash

tracts="\
fmajor_PP_avg33_mni \
fminor_PP_avg33_mni \
lh.atr_PP_avg33_mni \
lh.cab_PP_avg33_mni \
lh.ccg_PP_avg33_mni \
lh.cst_AS_avg33_mni \
lh.ilf_AS_avg33_mni \
lh.slfp_PP_avg33_mni \
lh.slft_PP_avg33_mni \
lh.unc_AS_avg33_mni \
rh.atr_PP_avg33_mni \
rh.cab_PP_avg33_mni \
rh.ccg_PP_avg33_mni \
rh.cst_AS_avg33_mni \
rh.ilf_AS_avg33_mni \
rh.slfp_PP_avg33_mni \
rh.slft_PP_avg33_mni \
rh.unc_AS_avg33_mni"

regs="bbr flt"
for reg in $regs ; do
	for tract in $tracts ; do

	pd=${tract}_${reg}
	echo $pd >${pd}.txt
	find ./ -name pathstats.overall.txt | grep reg${reg} | grep $pd | sort | xargs cat | grep FA_Avg_Weight | cut -d " " -f 2 | sed "s|\.|,|g" >> ${pd}.txt
  done
done

pds=""
for tract in $tracts ; do
	reg=bbr
	pd=${tract}_${reg}.txt
	pds=$pds" "$pd
done

paste $pds > bbr_all.txt

pds=""
for tract in $tracts ; do
	reg=flt
	pd=${tract}_${reg}.txt
	pds=$pds" "$pd
done

paste $pds > flt_all.txt
