#!/bin/bash
# set -x
# Created by Alex Cohen to convert chosen files into BIDS formatted dirs.

# g_subjects="010"


# Cases with at least a T1
# g_subjects="001 002 003 004 009 010 011 012 014 015 016 017 018 019 021 022 027 028 029 030"

# Controls with at least a T1
g_subjects="001 002 003 004 005 006 007 008 009 010 011 013 014 015 016 017 018 019 020 021 022 023 024 025 028 029 030 032 033 035 037 038"

# Subjects with at least T1+T2
# g_subjects="Case001 Case002 Case003 Case004 Case009 Case010 Case011 Case012 Case014 Case015 Case016 Case017 Case018 Case019 Case021 Case022 Case027 Case028 Case029 Case030 \
# Control001 Control002 Control003 Control004 Control005 Control006 Control007 Control008 Control009 Control010 Control011 Control013 Control014 Control015 Control016 Control017 \
# Control018 Control019 Control020 Control021 Control022 Control023 Control024 Control025 Control028 Control029 Control030 Control032 Control033 Control035 Control037 Control038"

# Subjects with T1+T2+fMRI+fieldmaps
# g_subjects="Case001 Case002 Case003 Case009 Case010 Case011 Case014 Case015 Case027 Case029 \
# Control001 Control002 Control003 Control004 Control005 Control006 Control007 Control008 Control009 Control010 Control011 Control013 Control014 Control015 Control016 Control017 \
# Control018 Control019 Control021 Control022 Control023 Control024 Control025 Control028 Control032"

sourcedir=/common/tsc/TSC-R01/Controls/RAW
sourceprefix="case"
labeldir=/common/collections/Analyses/TSC-RO1-HCP
studydir=/common/collections/Analyses/TSC-R01-BIDS/Controls
labelprefix="Control"

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
    subject_labeldir=${labeldir}/${labelprefix}${subject}/unprocessed/source
    sessions=`ls ${subject_labeldir} | awk -F[._] '{print $(NF-3)}' | sort | uniq`

    for session in ${sessions} ; do
        # set locations
        session_sourcedir=${sourcedir}/${sourceprefix}${subject}/*/scan0${session}/DICOM
        session_targetdir=${studydir}/sub-${subject}/ses-0${session}
        mkdir --parents ${session_targetdir}/anat
        mkdir --parents ${session_targetdir}/func
        
        # get file lists
        T1s_that_are_MEMPRAGE=`ls ${subject_labeldir}/${labelprefix}${subject}_T1w_MEMPRAGE_${session}* 2>/dev/null`
        T1s_that_are_MPRAGE=`ls ${subject_labeldir}/${labelprefix}${subject}_T1w_${session}* 2>/dev/null`
        T2s_that_are_Flair=`ls ${subject_labeldir}/${labelprefix}${subject}_T2w_Flair_${session}* 2>/dev/null`
        T2s_that_are_not_Flair=`ls ${subject_labeldir}/${labelprefix}${subject}_T2w_${session}* 2>/dev/null`

        # base script
        dcm2niix_cmd="dcm2niix -b y -z i"
        # dcm2niix_cmd="docker run -ti --rm \
        #                     -v ${session_sourcedir}:/input \
        #                     -v ${session_targetdir}:/output \
        #                     alex/dcm2niix -b y -z i"

        if [ ! -z "${T1s_that_are_MEMPRAGE}" ]; then
            for MEMPRAGE in ${T1s_that_are_MEMPRAGE} ; do
                sequence=`echo $MEMPRAGE | awk -F[._] '{print $(NF-2)}'`
                dcmDIR=`dcmdump --scan-directories --search 0020,0011 ${session_sourcedir}/*${sequence}* +Fs | grep -B 1 "\[${sequence}\]" | head -n 1 | awk -F[:/] '{print $(NF-1)}'`
                
                dcm2niix_CMD="${dcm2niix_cmd}"
                dcm2niix_CMD="${dcm2niix_CMD} -f sub-${subject}_ses-${session}_acq-memprage_run-${sequence}_T1w"
                dcm2niix_CMD="${dcm2niix_CMD} -o ${session_targetdir}/anat"
                dcm2niix_CMD="${dcm2niix_CMD} ${session_sourcedir}/${dcmDIR}"
            done
        fi
    done

    printf "\n"

    # run dcm2niix
    echo Running ${dcm2niix_CMD}
    ${dcm2niix_CMD} >> ${log}
}

main()
{
    for subject in ${g_subjects} ; do
	run_dcm2niix ${subject}
    done
}

# invoke the main function to get things started
main $@
