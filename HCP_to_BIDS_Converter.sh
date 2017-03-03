#!/bin/bash
# set -x
# Created by Alex Cohen to convert chosen files into BIDS formatted dirs.

# g_subjects="019"


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

# sourcedir=/common/tsc/TSC-R01/Autism/RAW
# sourceprefix="Case"
# labeldir=/common/collections/Analyses/TSC-R01/HCP
# studydir=/common/collections/Analyses/TSC-R01-BIDS/sourcedata/autism
# labelprefix="Case"

sourcedir=/common/tsc/TSC-R01/Controls/RAW
sourceprefix="case"
labeldir=/common/collections/Analyses/TSC-R01/HCP
studydir=/common/collections/Analyses/TSC-R01-BIDS/sourcedata/controls
labelprefix="Control"

#################################################################

log=/tmp/ImportProcessing.log
echo "Logging will be output to: $log"

# for ad hoc testing/rerunning
if [ ! -z $1 ] ; then
	echo -e "Bypassing hard coded subject list and using command_line input of SUBJECT = $1 instead\n"
	g_subjects=$1
fi

 # base script
dcm2niix_cmd="dcm2niix -b y -z y"
# dcm2niix_cmd="docker run --user=4135:1003 -ti --rm \
#                     -v ${session_sourcedir}:/input \
#                     -v ${session_targetdir}:/output \
#                     alex/dcm2niix -b y -z y"


dcm2niix_CMD()
{
    sequence=`echo $sourcefile | awk -F[._] '{print $(NF-2)}'`
                
    
    dcm2niix_command="${dcm2niix_cmd}"
    if [ -n "${multiple_runs}" ]; then
        run_tag="_run-0${run_number}"
    else
        run_tag=""
    fi
    target_filename="sub-${subject}_ses-0${session}${task_label}${acq_label}${run_tag}_${file_type}"
    
    # dcm2niix_command="${dcm2niix_command} -o /output/anat"
    # dcm2niix_command="${dcm2niix_command} /input/*/scan0${session}/DICOM/${dcmDIR}"

    # run dcm2niix
    if [ ! -e ${session_targetdir}/${folder_type}/sub-${subject}_ses-0${session}${task_label}${acq_label}*${run_tag}_${file_type}.json ]; then
        
        dcmDIR=`dcmdump --scan-directories --search 0020,0011 ${session_sourcedir}/*${sequence}* +Fs | grep -B 1 "\[${sequence}\]" | head -n 1 | awk -F[:/] '{print $(NF-1)}'`
        dcm2niix_command="${dcm2niix_command} -f ${target_filename}"
        dcm2niix_command="${dcm2niix_command} -o ${session_targetdir}/${folder_type}"
        dcm2niix_command="${dcm2niix_command} ${session_sourcedir}/${dcmDIR}"
        echo Running ${dcm2niix_command}
        ${dcm2niix_command} >> ${log}
        
        # adding resolution to acq tag
        im_resolution=`fslinfo ${session_targetdir}/${folder_type}/${target_filename}.nii.gz | grep pixdim | head -3 | awk '{print $2}' | xargs printf "x%.1f" | cut -c 2- | sed 's/\.//g'`
        # echo "im_resolution=fslinfo ${session_targetdir}/${folder_type}/${target_filename}.nii.gz | grep pixdim | head -3 | awk '{print $2}' | xargs printf "x%.1f" | cut -c 2-"
        echo ${im_resolution}
        mv ${session_targetdir}/${folder_type}/${target_filename}.nii.gz ${session_targetdir}/${folder_type}/sub-${subject}_ses-0${session}${task_label}${acq_label}${im_resolution}${run_tag}_${file_type}.nii.gz
        mv ${session_targetdir}/${folder_type}/${target_filename}.json ${session_targetdir}/${folder_type}/sub-${subject}_ses-0${session}${task_label}${acq_label}${im_resolution}${run_tag}_${file_type}.json
        target_filename="sub-${subject}_ses-0${session}${task_label}${acq_label}${im_resolution}${run_tag}_${file_type}"
        echo "filename is now ${target_filename}"
        echo -e "ses-${session}/${folder_type}/${target_filename}.nii.gz\t${dcmDIR}" >> ${studydir}/sub-${subject}/sub-${subject}_scans.tsv
        if [ ${folder_type} == "func" ]; then
            taskname=`echo ${task_label} | awk -F[-] '{print $(NF)}'`
            jq '. + { "TaskName": "'"${taskname}"'" }' ${session_targetdir}/${folder_type}/${target_filename}.json > ${session_targetdir}/${folder_type}/temp.json
            mv ${session_targetdir}/${folder_type}/temp.json ${session_targetdir}/${folder_type}/${target_filename}.json
        fi
    else
        echo "Files already exist, moving on: ${session_targetdir}/${folder_type}/${target_filename}.json"
    fi
}


run_dcm2niix()
{
    subject=${1}
    echo -e "Starting work on: $subject"
    
    mkdir --parents ${studydir}/sub-${subject}
    if [ ! -e ${studydir}/sub-${subject}/sub-${subject}_scans.tsv ]; then
        echo -e "filename\tsource_data" > ${studydir}/sub-${subject}/sub-${subject}_scans.tsv
    fi


    # Determine which sessions are used
    subject_labeldir=${labeldir}/${labelprefix}${subject}/unprocessed/source
    sessions=`ls ${subject_labeldir} | awk -F[._] '{print $(NF-3)}' | sort | uniq`

    for session in ${sessions} ; do
        # set locations
        
        # workaround for weird docker behavior:
        # session_sourcedir=${sourcedir}/${sourceprefix}${subject}
        session_sourcedir=${sourcedir}/${sourceprefix}${subject}/*/scan0${session}/DICOM
        
        session_targetdir=${studydir}/sub-${subject}/ses-0${session}
        mkdir --parents ${session_targetdir}/anat
        mkdir --parents ${session_targetdir}/func
        
        # get file lists
        T1s_that_are_MEMPRAGE=`ls ${subject_labeldir}/${labelprefix}${subject}_T1w_MEMPRAGE_${session}* 2>/dev/null`
        T1s_that_are_MPRAGE=`ls ${subject_labeldir}/${labelprefix}${subject}_T1w_${session}* 2>/dev/null`
        T2s_that_are_Flair=`ls ${subject_labeldir}/${labelprefix}${subject}_T2w_Flair_${session}* 2>/dev/null`
        T2s_that_are_not_Flair=`ls ${subject_labeldir}/${labelprefix}${subject}_T2w_${session}* 2>/dev/null`
        fMRI_runs=`ls ${subject_labeldir}/${labelprefix}${subject}_fMRI_${session}* 2>/dev/null`

        if [ ! -z "${T1s_that_are_MEMPRAGE}" ]; then
            if [ `echo ${T1s_that_are_MEMPRAGE} | wc -w` -gt 1 ]; then
                multiple_runs="True"
                run_number=1
            else
                multiple_runs=""
            fi
            for sourcefile in ${T1s_that_are_MEMPRAGE} ; do
                acq_label="_acq-memprage"
                task_label=""
                file_type="T1w"
                folder_type="anat"
                dcm2niix_CMD
                ((run_number++))
            done
        fi

        if [ ! -z "${T1s_that_are_MPRAGE}" ]; then
            if [ `echo ${T1s_that_are_MPRAGE} | wc -w` -gt 1 ]; then
                multiple_runs="True"
                run_number=1
            else
                multiple_runs=""
            fi
            for sourcefile in ${T1s_that_are_MPRAGE} ; do
                acq_label="_acq-mprage"
                task_label=""
                file_type="T1w"
                folder_type="anat"
                dcm2niix_CMD
                ((run_number++))
            done
        fi

        if [ ! -z "${T2s_that_are_Flair}" ]; then
            if [ `echo ${T2s_that_are_Flair} | wc -w` -gt 1 ]; then
                multiple_runs="True"
                run_number=1
            else
                multiple_runs=""
            fi
            for sourcefile in ${T2s_that_are_Flair} ; do
                acq_label="_acq-"
                task_label=""
                file_type="FLAIR"
                folder_type="anat"
                dcm2niix_CMD
                ((run_number++))
            done
        fi
        
        if [ ! -z "${T2s_that_are_not_Flair}" ]; then
            if [ `echo ${T2s_that_are_not_Flair} | wc -w` -gt 1 ]; then
                multiple_runs="True"
                run_number=1
            else
                multiple_runs=""
            fi
            for sourcefile in ${T2s_that_are_not_Flair} ; do
                if [ ! -z `echo ${sourcefile} | grep coronal` ]; then
                    acq_label="_acq-coronal"
                    task_label=""
                    file_type="T2w"
                    folder_type="anat"
                    dcm2niix_CMD
                    ((run_number++))
                elif [ ! -z `echo ${sourcefile} | grep axial` ]; then
                    acq_label="_acq-axial"
                    task_label=""
                    file_type="T2w"
                    folder_type="anat"
                    dcm2niix_CMD
                    ((run_number++))
                else
                    acq_label="_acq-"
                    task_label=""
                    file_type="T2w"
                    folder_type="anat"
                    dcm2niix_CMD
                    ((run_number++))
                fi
            done
        fi

        if [ ! -z "${fMRI_runs}" ]; then
            if [ `echo ${fMRI_runs} | wc -w` -gt 1 ]; then
                multiple_runs="True"
                run_number=1
            else
                multiple_runs=""
            fi
            for sourcefile in ${fMRI_runs} ; do
                acq_label="_acq-"
                task_label="_task-rest"
                file_type="bold"
                folder_type="func"
                dcm2niix_CMD
                ((run_number++))
            done
        fi



    done

    printf "\n"


}

main()
{
    for subject in ${g_subjects} ; do
	run_dcm2niix ${subject}
    done
}

# invoke the main function to get things started
main $@
