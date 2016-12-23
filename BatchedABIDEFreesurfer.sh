#!/bin/bash

# Created by Alex Cohen to run multiple subjects through Freesurfer in HCP style directories

# ABIDEII-EMC
g_subjects="29864 29867 29870 29873 29876 29879 29882 29885 29888 29891 29894 29897 29900 29903 29906 29909 29912 29915 29865 29868 29871 29874 29877 9880 \
29883 29886 29889 29892 29895 29898 29901 29904 29907 29910 29913 29916 29866 29869 29872 29875 29878 29881 29884 29887 29890 29893 29896 29899 29902 29905 \
29908 29911 29914 29917"


parent_dir=${analysis}/ABIDE-FS
source_dir=/common/collections/ABIDE/ABIDEII
study_name="ABIDEII-EMC_1"
num_cores=1


#################################################################

export STUDY_DIR=${parent_dir}/${study_name}

log=${STUDY_DIR}/recon-all-commands.log
echo "Logging will be output to: $log"

# for ad hoc testing/rerunning
if [ ! -z $1 ] ; then
	echo -e "Bypassing hard coded subject list and using command_line input of SUBJECT = $1 instead\n"
	g_subjects=$1
fi

run_freesurfer()
{
    subject=${1}
    echo -e "Starting work on: $subject"
    # set locations
    local SUBJECTS_DIR=${STUDY_DIR}/${subject}/T1w
    local source_dcmdir=${source_dir}/${study_name}/${subject}/session_1/anat_1
    local dcmdir=${STUDY_DIR}/${subject}/unprocessed
    if [ ! -e $dcmdir ] ; then
    	mkdir --parents ${dcmdir}
    	ln -s ${source_dcmdir}/anat.nii.gz ${dcmdir}/${subject}_T1w1.nii.gz
    fi
    mkdir --parents ${SUBJECTS_DIR}
    
    # base script
    local fs_cmd="recon-all -subjid ${subject} -all -sd ${SUBJECTS_DIR} -openmp ${num_cores} -time"

    # # load in multiple T1s
    # for T1w in `ls ${dcmdir}/${subject}_T1*gz` ; do
    # 	local fs_cmd+=" -i $T1w"
    # done

    local fs_cmd+=" -i ${dcmdir}/${subject}_T1w1.nii.gz"
    # # load in only 1 T1 for now due to differing resolutions. give preference to MEMPRAGEs if available
    # T1w_that_are_MEMPRAGE=`ls -l ${dcmdir}/*T1w* | grep MEMPRAGE`
    # if [ ! -z "${T1w_that_are_MEMPRAGE}" ] ; then
    # 	One_T1w_that_is_an_MEMPRAGE=`ls -l ${dcmdir}/*T1w* | grep MEMPRAGE | awk '{print $(NF-2)}'`
    # 	echo "Using an MEMPRAGE: ${One_T1w_that_is_an_MEMPRAGE} > `readlink ${One_T1w_that_is_an_MEMPRAGE}`"
    # 	local fs_cmd+=" -i ${One_T1w_that_is_an_MEMPRAGE}"
    # else
    # 	One_T1w_that_is_an_MPRAGE=`ls -1 ${dcmdir}/*T1w* | head -n 1`
    # 	echo "  Using an MPRAGE: ${One_T1w_that_is_an_MPRAGE} > `readlink ${One_T1w_that_is_an_MPRAGE}`"
    # 	local fs_cmd+=" -i ${One_T1w_that_is_an_MPRAGE}"
    # fi

    # # load in only 1 T2 or Flair
    # T2w_that_are_Flair=`ls -l ${dcmdir}/*T2w* | grep Flair`
    # if [ -z "${T2w_that_are_Flair}" ] ; then
    # 	One_T2w=`ls -1 ${dcmdir}/*T2w* | head -n 1`
    # 	echo "      Using a T2w: ${One_T2w} > `readlink ${One_T2w}`"
    # 	local fs_cmd+=" -T2 ${One_T2w} -T2pial"
    # else
    # 	One_T2w_that_is_a_Flair=`ls -1 ${dcmdir}/*T2w* | head -n 1`
    # 	echo "    Using a Flair: ${One_T2w_that_is_a_Flair} > `readlink ${One_T2w_that_is_a_Flair}`"
    # 	local fs_cmd+=" -FLAIR ${One_T2w_that_is_a_Flair} -FLAIRpial"
    # fi

printf "\n"

    # run freesurfer
    echo Running ${fs_cmd}
    ${fs_cmd} >> ${log}
}

main()
{
    for subject in ${g_subjects} ; do
	run_freesurfer ${subject}
    done
}

# invoke the main function to get things started
main $@
