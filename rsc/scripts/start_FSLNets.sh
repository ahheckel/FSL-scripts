#!/bin/bash
# Adapts and runs FSLNets' nets_examples.m

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 02/27/2013

# set error flag
set -e

# define error trap
trap 'echo "$0 : An ERROR has occured."' ERR

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

Usage() {
    echo ""
    echo "Usage:   `basename $0` <template_nets_examples.m> <dreg_stage1_path> <groupIC> <good_comp> <design_path> <t-thresh> <nperm> <out-dir> <[install-path]>"
    echo "Example: `basename $0` ./template_nets_examples.m ./dreg ./melodic/melodicIC.nii.gz \"[1 2 3 4 5 6 7 8 9 10]\" \"0:2:8\" ./glm/design 5000 ./grp/FSLNETS/dreg /FSL-scripts/rsc/scripts/FSLNets"
    echo ""
    exit 1
}

[ "$8" = "" ] && Usage

template="$1"
dreg_path="$2"
group_maps="$3"
good_comp="$4"
t_thresh="$5"
design_path="$6"
nperm=$7
outdir="$8"
install_path="$9"

if [ x"$install_path" = x ] ; then install_path="/FSL-scripts/rsc/scripts/FSLNets" ; fi
l1prec_path="$install_path/L1precision"
causal_path="$install_path/pwling"
design_mat="$design_path/design.mat"
design_con="$design_path/design.con"
design_grp="$design_path/design.grp"

for file in $template $dreg_path $group_maps $install_path $l1prec_path $causal_path $design_path $design_mat $design_con $design_grp ; do
  if [ ! -e $file ] ; then echo "`basename $0`: '$file' not found - exiting..." ; exit 1 ; fi
done

echo ""
echo "`basename $0` : FSLNets  loc.:        $install_path"
echo "`basename $0` : L1PREC   loc.:        $l1prec_path"
echo "`basename $0` : PWLING   loc.:        $causal_path"
echo "`basename $0` : template loc.:        $template"
echo "---------------------------------"
echo "`basename $0` : dr_stage1:            $dreg_path"
echo "`basename $0` : ICMaps:               $group_maps"
echo "`basename $0` : good components:      $good_comp"
echo "`basename $0` : design_mat:           $design_mat"
echo "`basename $0` : design_con:           $design_con"
echo "`basename $0` : design_grp:           $design_grp"
echo "`basename $0` : T-thres:              $t_thresh"
echo "`basename $0` : NPERM:                $nperm"
echo "`basename $0` : output-dir:           $outdir"
echo ""

cp $template $tmpdir/nets_examples.m$$ 

sed -i "s|design_nperm=.*|design_nperm=${nperm}|g"   $tmpdir/nets_examples.m$$
sed -i "s|design_mat=.*|design_mat='$design_mat'|g"  $tmpdir/nets_examples.m$$
sed -i "s|design_con=.*|design_con='$design_con'|g"  $tmpdir/nets_examples.m$$
sed -i "s|design_grp=.*|design_grp='$design_grp'|g"  $tmpdir/nets_examples.m$$

sed -i "s|addpath FSLNETS.*|addpath $install_path|g"   $tmpdir/nets_examples.m$$
sed -i "s|addpath L1PREC.*|addpath $l1prec_path|g"     $tmpdir/nets_examples.m$$
sed -i "s|addpath PAIRCAUSAL.*|addpath $causal_path|g" $tmpdir/nets_examples.m$$

sed -i "s|group_maps=.*|group_maps='$(remove_ext $group_maps)'|g" $tmpdir/nets_examples.m$$
sed -i "s|ts.DD=.*|ts.DD=${good_comp}|g"              $tmpdir/nets_examples.m$$  
sed -i "s|ts_dir='.*|ts_dir='${dreg_path}'|g"         $tmpdir/nets_examples.m$$  

sed -i "s|outputdir=.*|outputdir='${outdir}'|g"       $tmpdir/nets_examples.m$$

sed -i "s|for t=.*|for t=${t_thresh}|g"               $tmpdir/nets_examples.m$$

# check
echo "---------------------------------"
echo "---------------------------------"
echo ""
cat $tmpdir/nets_examples.m$$ # | head -n 40
echo ""
echo "---------------------------------"
echo "---------------------------------"
read -p "Press Key to continue..."


# check if size / resolution matches to have a background image for slices_summary
set +e
MNItemplates="${FSLDIR}/data/standard/MNI152_T1_4mm_brain ${FSLDIR}/data/standard/MNI152_T1_2mm_brain"
bg=""
for MNI in $MNItemplates ; do
  fslmeants -i $group_maps -m $MNI &>/dev/null
  if [ $? -gt 0 ] ; then 
    echo "$(basename $0) : WARNING : size / resolution does not match btw. '$group_maps' and '$MNI' - continuing loop..."
    continue
  else
    if [ $(echo $MNI | grep _4mm_ | wc -l) -eq 1 ] ; then bg=$FSLDIR/data/standard/MNI152_T1_4mm ; fi
    if [ $(echo $MNI | grep _2mm_ | wc -l) -eq 1 ] ; then bg=$FSLDIR/data/standard/MNI152_T1_2mm ; fi
    break
  fi
done # end MNI
set -e  

# execute slices_summary (needed for nets_examples.m to work)
echo "$(basename $0) : executing slices_summary..."
cmd="slices_summary $(remove_ext $group_maps) 4 $bg $(remove_ext $group_maps).sum"
echo "    $cmd" ; $cmd

# start MATLAB
mkdir -p $outdir
cd $outdir
mv $tmpdir/nets_examples.m$$ ./nets_examples.m
#xterm -e "matlab -nodesktop -r nets_examples"
matlab -nodesktop -r nets_examples
