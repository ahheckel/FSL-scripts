#!/bin/bash
if [ ! -f ./globalvars ] ; then exit ; fi
. ./globalvars

cd $subjdir
find ./ -name vbm -type d | xargs rm -r
find ./ -name trac -type d | xargs rm -r
find ./ -name fm -type d | xargs rm -r
find ./ -name fdt -type d | xargs rm -r
find ./ -name topup -type d | xargs rm -r
find ./ -name bold -type d | xargs rm -r
find ./ -name bpx -type d | xargs rm -r
find ./ -name "*tmp*.nii.gz" -type f | xargs rm
find ./ -name "*test*.nii.gz" -type f | xargs rm
find ./ -name "*nodif*.nii.gz" | xargs rm
find ./ -name "*datain*.txt" | xargs rm
find ./ -name "ec_b0.idx" | xargs rm
find ./ -name core | xargs rm
find ./ -name ec_*.txt | xargs rm
find ./ -name ec_*.png | xargs rm
find ./ -name grot_ts.txt | xargs rm
rm -r FS_subj
rm -r FS_sess
rm -r ../logs
