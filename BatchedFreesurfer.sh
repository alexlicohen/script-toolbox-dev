#!/bin/bash

# Created by Alex Cohen to run multiple subjects through Freesurfer in HCP style directories

# Subjects with at least T1+T2
# g_subjects="Case001 Case002 Case003 Case004 Case009 Case010 Case011 Case012 Case014 Case015 Case016 Case017 Case018 Case019 Case021 Case022 Case027 Case028 Case029 Case030 \
# Control001 Control002 Control003 Control004 Control005 Control006 Control007 Control008 Control009 Control010 Control011 Control013 Control014 Control015 Control016 Control017 \
# Control018 Control019 Control020 Control021 Control022 Control023 Control024 Control025 Control028 Control029 Control030 Control032 Control033 Control035 Control037 Control038"
g_subjects="Control038"

# Subjects with T1+T2+fMRI+fieldmaps
# g_subjects="Case001 Case002 Case003 Case009 Case010 Case011 Case014 Case015 Case027 Case029 \
# Control001 Control002 Control003 Control004 Control005 Control006 Control007 Control008 Control009 Control010 Control011 Control013 Control014 Control015 Control016 Control017 \
# Control018 Control019 Control021 Control022 Control023 Control024 Control025 Control028 Control032"

# g_subjects="Case001"

parent_dir=$analysis
study_name="TSC-RO1-FS"
num_cores=10


#################################################################

export STUDY_DIR=${analysis}/${study_name}

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
    local dcmdir=${STUDY_DIR}/${subject}/unprocessed
    mkdir --parents ${SUBJECTS_DIR}
    
    # base script
    local fs_cmd="recon-all -subjid ${subject} -all -sd ${SUBJECTS_DIR} -openmp ${num_cores} -time"

    # # load in multiple T1s
    # for T1w in `ls ${dcmdir}/${subject}_T1*gz` ; do
    # 	local fs_cmd+=" -i $T1w"
    # done

    # load in only 1 T1 for now due to differing resolutions. give preference to MEMPRAGEs if available
    T1w_that_are_MEMPRAGE=`ls -l ${dcmdir}/*T1w* | grep MEMPRAGE`
    if [ ! -z "${T1w_that_are_MEMPRAGE}" ] ; then
    	One_T1w_that_is_an_MEMPRAGE=`ls -l ${dcmdir}/*T1w* | grep MEMPRAGE | awk '{print $(NF-2)}'`
    	echo "Using an MEMPRAGE: ${One_T1w_that_is_an_MEMPRAGE} > `readlink ${One_T1w_that_is_an_MEMPRAGE}`"
    	local fs_cmd+=" -i ${One_T1w_that_is_an_MEMPRAGE}"
    else
    	One_T1w_that_is_an_MPRAGE=`ls -1 ${dcmdir}/*T1w* | head -n 1`
    	echo "  Using an MPRAGE: ${One_T1w_that_is_an_MPRAGE} > `readlink ${One_T1w_that_is_an_MPRAGE}`"
    	local fs_cmd+=" -i ${One_T1w_that_is_an_MPRAGE}"
    fi

    # load in only 1 T2 or Flair
    T2w_that_are_Flair=`ls -l ${dcmdir}/*T2w* | grep Flair`
    if [ -z "${T2w_that_are_Flair}" ] ; then
    	One_T2w=`ls -1 ${dcmdir}/*T2w* | head -n 1`
    	echo "      Using a T2w: ${One_T2w} > `readlink ${One_T2w}`"
    	local fs_cmd+=" -T2 ${One_T2w} -T2pial"
    else
    	One_T2w_that_is_a_Flair=`ls -1 ${dcmdir}/*T2w* | head -n 1`
    	echo "    Using a Flair: ${One_T2w_that_is_a_Flair} > `readlink ${One_T2w_that_is_a_Flair}`"
    	local fs_cmd+=" -FLAIR ${One_T2w_that_is_a_Flair} -FLAIRpial"
    fi

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
