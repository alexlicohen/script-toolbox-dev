#!/bin/bash


export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12  # controls multi-threading

export ANTSPATH=/home/ch186161/bin/ants/bin/ # path to ANTs binaries
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

echo This will use ${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS} threads at a time
echo Using the ANTs version installed at ${ANTSPATH}

temp_dir=./ants_Temp
mkdir -p $temp_dir

template=$1
sub_T1=$2
sub_lesion=$3
sub_prefix=$4
sub_neg_lesion=${temp_dir}/${sub_prefix}_neg_lesion.nii.gz
sub_masked_T1=${temp_dir}/${sub_prefix}_T1_lesioned.nii.gz

# ImageMath 3 $sub_neg_lesion Neg $sub_lesion

# MultiplyImages 3 $sub_T1 $sub_neg_lesion $sub_masked_T1

# In the SyNQuick script, the mask applies to fixed image, so the template is moving to the subject, and 
# the inverse warp is what we'll want to apply to the lesion data.

antsRegistrationSyNQuick.sh \
	-d 3 \
	-m $template \
	-f $sub_masked_T1 \
	-t a \
	-o MNI_to_${sub_prefix}_ \
	-x $sub_neg_lesion \
	-j 1 

# Then we apply the inverse transform to bring the lesion mask to MNI space.

antsApplyTransforms \
	-d 3 \
	-i ${sub_lesion} \
	-r ${template} \
	-t [MNI_to_${sub_prefix}_0GenericAffine.mat, 1] \
	-n GenericLabel[Linear] \
	-o ${sub_prefix}_lesions_in_MNI.nii.gz

# WarpImageMultiTransform 3 $sub_lesion sub_lesion_in_MNI.nii.gz \
# 	-R $template -i ${nm}0GenericAffine.mat ${nm}1InverseWarp.nii.gz