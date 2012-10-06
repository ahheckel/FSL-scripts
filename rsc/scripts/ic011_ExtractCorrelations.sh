#!/bin/bash

# finde files für session A-E

file=""
for i in `seq -f %05g 00000 00049` ; do
echo $i
sess_n=`expr $i % 5`
echo $sess_n
if [ $sess_n -eq 0 ] ; then 
  echo $sess
  file_sessA=$file" "/home/andi/kira_data/grp/dualreg/ica_50/dr_stage2_subject${i}.nii.gz
  echo $file
fi
done

for i in `seq -f %05g 00000 00049` ; do
echo $i
sess_n=`expr $i % 5`
echo $sess_n
if [ $sess_n -eq 1 ] ; then 
  echo $sess
  file_sessB=$file" "/home/andi/kira_data/grp/dualreg/ica_50/dr_stage2_subject${i}.nii.gz
  echo $file
fi
done

for i in `seq -f %05g 00000 00049` ; do
echo $i
sess_n=`expr $i % 5`
echo $sess_n
if [ $sess_n -eq 2 ] ; then 
  echo $sess
  file_sessC=$file" "/home/andi/kira_data/grp/dualreg/ica_50/dr_stage2_subject${i}.nii.gz
  echo $file
fi
done

for i in `seq -f %05g 00000 00049` ; do
echo $i
sess_n=`expr $i % 5`
echo $sess_n
if [ $sess_n -eq 3 ] ; then 
  echo $sess
  file_sessD=$file" "/home/andi/kira_data/grp/dualreg/ica_50/dr_stage2_subject${i}.nii.gz
  echo $file
fi
done

for i in `seq -f %05g 00000 00049` ; do
echo $i
sess_n=`expr $i % 5`
echo $sess_n
if [ $sess_n -eq 4 ] ; then 
  echo $sess
  file_sessE=$file" "/home/andi/kira_data/grp/dualreg/ica_50/dr_stage2_subject${i}.nii.gz
  echo $file
fi
done

# extrahiere den Voxel für die gefundenen Files

for i in file_sessA ; do
	fslroi $i ${i}_sessA_extracted.nii.gz 32 1 16 1 24 1 11 1
done
for i in file_sessB ; do
	fslroi $i ${i}_sessB_extracted.nii.gz 32 1 16 1 24 1 11 1
done
for i in file_sessC ; do
	fslroi $i ${i}_sessC_extracted.nii.gz 32 1 16 1 24 1 11 1
done
for i in file_sessD ; do
	fslroi $i ${i}_sessD_extracted.nii.gz 32 1 16 1 24 1 11 1
done
for i in file_sessE ; do
	fslroi $i ${i}_sessE_extracted.nii.gz 32 1 16 1 24 1 11 1
done










