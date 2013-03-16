#!/bin/bash
# Searches recursively in current working directory for tracula's pathstats.overall.txt and extracts values belonging to a given variable name.

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 11/18/2012

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo ""
    echo "Searches recursively in current working directory for TRACULA's 'pathstats.overall.txt' and extracts values belonging to <var>."
    echo "Usage:   `basename $0` <var> <out-dir>"
    echo "Example: `basename $0` FA_Avg_Weight ./trac-results"
    echo "NOTE:    <var> can be:"    
    echo "          AD_Avg"
    echo "          AD_Avg_Weight"
    echo "          AD_Avg_Center"
    echo "          RD_Avg"
    echo "          RD_Avg_Weight"
    echo "          RD_Avg_Center"
    echo "          MD_Avg"
    echo "          MD_Avg_Weight"
    echo "          MD_Avg_Center"
    echo "          FA_Avg"
    echo "          FA_Avg_Weight"
    echo "          FA_Avg_Center"
    
    exit 1
}

[ "$2" = "" ] && Usage

# define vars.
depvar="$1"
outdir="$2"
regs="bbr flt"
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

# create output directory
mkdir -p $outdir

echo ""

# display info
echo "`basename $0` : tracts available:"
i=1
for j in $tracts ; do 
  echo "    $i $j"
  i=$[$i+1]
done

echo ""

# gather variables of interest
echo "`basename $0` : gathering '$depvar' values..."
for reg in $regs ; do
	for tract in $tracts ; do

	pd=${tract}_${reg}
  echo "`basename $0` : creating $outdir/${pd}.txt from:"
	echo $pd > $outdir/${pd}.txt
  stattxts=$(find ./ -name pathstats.overall.txt | grep reg${reg} | grep $pd | sort)
  i=1
  for stattxt in $stattxts ; do 
    echo "    $i $stattxt"
    i=$[$i+1]
  done
	find ./ -name pathstats.overall.txt | grep reg${reg} | grep $pd | sort | xargs cat | grep "$depvar" | cut -d " " -f 2 | sed "s|\.|,|g" >> $outdir/${pd}.txt
  done
  echo ""
done

# create summary textfile via concatenation (1 col. for each tract) and clean up
for reg in $regs ; do
  summary=$outdir/${depvar}_${reg}.txt
  echo "`basename $0` : creating $summary."
  pds=""
  for tract in $tracts ; do
    pd=$outdir/${tract}_${reg}.txt
    pds=$pds" "$pd
  done
  paste $pds > $summary
  echo "`basename $0` : cleaning up."
  rm -f $pds # cleanup
done

# done.
echo "`basename $0` : done."

