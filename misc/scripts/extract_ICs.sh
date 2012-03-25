#!/bin/bash

# artefakte (sicher) (gemeint ist der Index (IC -1))
# 1 2 5 9 11 13 14 17 18 19 20 23 24 26 28 29 32

# visuell (gemeint ist der Index (IC -1))
# 15 16 25

for IC_idx in 2 8 11 24 26 29 31 ; do

	ic_n=$(echo "$IC_idx + 1" | bc)
	ic_n=$(printf '%03i' $ic_n)
	fslroi melodic_IC.nii.gz melodic_art_IC${ic_n} $IC_idx 1

done

otherICs=

#fslmerge -t melodic_ICVisual $(ls melodic_vis_IC*)
