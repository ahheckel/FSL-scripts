#! /bin/bash

set -e

if [ $# -lt 4 ]  ; then echo "Usage: `basename $0` <in> <out> <ref_pos> <struc>" ; exit 1 ; fi

flirt_in=`remove_ext $1`
flirt_out=`remove_ext $2`
ref_pos=`remove_ext $3`
struc=`remove_ext $4`
fldr=$(dirname $flirt_out)
al_exf=$fldr/al_example_func
exf=$fldr/example_func


echo "extracting example_func from '$flirt_in' at position ${ref_pos}..."
fslroi $flirt_in $exf $ref_pos 1

echo "flirting example_func to '$struc'"
#flirt -in $exf -ref $struc -dof 12 -cost corratio -omat $fldr/BOLD2T1.mat -out $al_exf
flirt -in $exf -ref $struc -dof 12 -cost mutualinfo -omat $fldr/BOLD2T1.mat -out $al_exf # mutualinfo is much better than corratio!

echo "flirting 4D-BOLD to structural...."
rm -f ${flirt_out}.flirtlog ${flirt_out}_tmp_????.*
fslsplit $flirt_in ${flirt_out}_tmp_
full_list=`imglob ${flirt_out}_tmp_????.*`
for i in $full_list ; do
  echo processing $i
  #flirt -in $i -ref $al_exf -init $fldr/BOLD2T1.mat -applyxfm -o $(echo $i | sed "s|"_tmp"|""|g")
  rm ${i}.nii.gz
done
#fslmerge -t $flirt_out $full_list

# run fast, if not already done so...
if [ ! -e ${struc}_pve_2.nii.gz ] ; then
  echo "fasting '$struc'..."
  #fast -t 1 -n 3 $struc
fi

echo "creating masks..."
echo "    WholeBrain..."
min=`fslstats $al_exf -P 15`
fslmaths $al_exf -thr $min -bin $fldr/WB_mask 
echo "    CSF..."
fslmaths ${struc}_pve_0 -thr 1 -bin -ero -mas $fldr/WB_mask $fldr/CSF_mask 
echo "    GreyMatter..."
fslmaths ${struc}_pve_1 -thr 1 -bin -ero -mas $fldr/WB_mask $fldr/GM_mask 
echo "    WhiteMatter..."
fslmaths ${struc}_pve_2 -thr 1 -bin -ero -mas $fldr/WB_mask $fldr/WM_mask

# extracting timecourses
full_list=`imglob ${flirt_out}_????.*`
for mask in CSF_mask WB_mask WM_mask ; do
  rm -f $fldr/tc_$mask
  echo "extracting timecourse for mask '$mask'..."
  for i in $full_list ; do
    fslmeants -i $i -m $fldr/$mask | sed '/^$/d' >> $fldr/tc_$mask
  done
done

# cleanup
rm ${flirt_out}_????.*
