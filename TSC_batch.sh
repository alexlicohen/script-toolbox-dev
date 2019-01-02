#!/bin/bash

# This script will automatically convert a bunch of lesions (given a T1) into MNI space

template=./icbm152_t1_tal_nlin_asym_09c_masked.nii.gz
T1_dir=./T1
Lesion_dir=./Automated_segmentation
Output_dir=./Lesions_in_MNI

mkdir -p ${Output_dir}/warps

ls -1 T1 | cut -d _ -f -2 > list_of_subjects

for i in `cat short_list`; do 
	echo Working on subject: $i;
	./ants_Lesion_to_MNI.sh $template ${T1_dir}/${i}_t1.nii.gz ${Lesion_dir}/${i}_segmentation.nii.gz $i
	mv ${i}* $Output_dir
	mv *${i}* ${Output_dir}/warps
	cp ${Output_dir}/warps/MNI_to_${i}_InverseWarped.nii.gz ${Output_dir}/${i}_T1_in_MNI.nii.gz
done