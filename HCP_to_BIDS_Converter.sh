#!/bin/bash

# Created by Alex Cohen to convert chosen files into BIDS formatted dirs.

g_subjects="Control010"

# Subjects with at least a T1
# g_subjects="Case001 Case002 Case003 Case004 Case009 Case010 Case011 Case012 Case014 Case015 Case016 Case017 Case018 Case019 Case021 Case022 Case027 Case028 Case029 Case030 \
# Control001 Control002 Control003 Control004 Control005 Control006 Control007 Control008 Control009 Control010 Control011 Control013 Control014 Control015 Control016 Control017 \
# Control018 Control019 Control020 Control021 Control022 Control023 Control024 Control025 Control028 Control029 Control030 Control032 Control033 Control035 Control037 Control038"

# Subjects with at least T1+T2
# g_subjects="Case001 Case002 Case003 Case004 Case009 Case010 Case011 Case012 Case014 Case015 Case016 Case017 Case018 Case019 Case021 Case022 Case027 Case028 Case029 Case030 \
# Control001 Control002 Control003 Control004 Control005 Control006 Control007 Control008 Control009 Control010 Control011 Control013 Control014 Control015 Control016 Control017 \
# Control018 Control019 Control020 Control021 Control022 Control023 Control024 Control025 Control028 Control029 Control030 Control032 Control033 Control035 Control037 Control038"

# Subjects with T1+T2+fMRI+fieldmaps
# g_subjects="Case001 Case002 Case003 Case009 Case010 Case011 Case014 Case015 Case027 Case029 \
# Control001 Control002 Control003 Control004 Control005 Control006 Control007 Control008 Control009 Control010 Control011 Control013 Control014 Control015 Control016 Control017 \
# Control018 Control019 Control021 Control022 Control023 Control024 Control025 Control028 Control032"

sourcedir=/common/tsc/TSC-R01/Controls/RAW/
labeldir=/common/collections/Analysis/TSC-RO1-HCP
studydir=/common/collections/Analysis/TSC-R01-BIDS


#################################################################

log=${studydir}/ImportProcessing.log
echo "Logging will be output to: $log"

# for ad hoc testing/rerunning
if [ ! -z $1 ] ; then
	echo -e "Bypassing hard coded subject list and using command_line input of SUBJECT = $1 instead\n"
	g_subjects=$1
fi

run_dcm2niix()
{
    subject=${1}
    echo -e "Starting work on: $subject"
    
    # Determine which sessions are used
    subject_labeldir=${labeldir}/${subject}/unprocessed/source
    sessions=`ls ${subject_labeldir} | awk -F[._] '{print $(NF-3)}' | sort | uniq`

    for session in ${sessions} ; do
        # set locations
        session_sourcedir=${sourcedir}/${subject}/*/scan0${session}
        session_targetdir=${studydir}/sub-${subject}/ses-0${session}
        mkdir --parents ${session_targetdir}/anat
        mkdir --parents ${session_targetdir}/func
        
        # get file lists
        T1s_that_are_MEMPRAGE=`ls -l ${subject_labeldir}/${subject}_T1w_MEMPRAGE_${session}*`
        T1s_that_are_MPRAGE=`ls -l ${subject_labeldir}/${subject}_T1w_${session}*`
        T2s_that_are_Flair=`ls -l ${subject_labeldir}/${subject}_T2w_Flair_${session}*`
        T2s_that_are_not_Flair=`ls -l ${subject_labeldir}/${subject}_T2w_${session}*`

        # base script
        dcm2niix_cmd="docker run -ti --rm \
                            -v ${session_sourcedir}:/input \
                            -v ${session_targetdir}:/output \
                            alex/dcm2niix -b y -z i"

        for MEMPRAGE in ${T1s_that_are_MEMPRAGE} ; do
            # session='echo $MEMPRAGE | awk -F[._] '{print $(NF-3)}''
            sequence='echo $MEMPRAGE | awk -F[._] '{print $(NF-2)}''
            dcmDIR=`dcmdump --scan-directories --search 0020,0011 *${sequence}* +Fs | grep -B 1 "\[${sequence}\]" | head -n 1 | awk -F[:/] '{print $(NF-1)}'`
            
            dcm2niix_CMD=dcm2niix_cmd
            dcm2niix_CMD+=" -f sub-${subject}_ses-${session}_acq-memprage_run-${sequence}_T1w"
            dcm2niix_CMD+=" -o /output/anat"
            dcm2niix_CMD+=" /input/*/scan0${session}/${dcmDIR}"
        done





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
	run_dcm2niix ${subject}
    done
}

# invoke the main function to get things started
main $@
