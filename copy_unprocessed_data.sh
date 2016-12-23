#!/bin/bash

# Copyright: (C) 2016 The Human Connectome Project
# Author: Timothy B. Brown (tbbrown at wustl dot edu)
# Modified by Alex Cohen for general subject lndir replication

# Subjects with at least T1+T2
# g_subjects="Case001 Case002 Case003 Case004 Case009 Case010 Case011 Case012 Case014 Case015 Case016 Case017 Case018 Case019 Case021 Case022 Case027 Case028 Case029 Case030 \
# Control001 Control002 Control003 Control004 Control005 Control006 Control007 Control008 Control009 Control010 Control011 Control013 Control014 Control015 Control016 Control017 \
# Control018 Control019 Control020 Control021 Control022 Control023 Control024 Control025 Control028 Control029 Control030 Control032 Control033 Control035 Control037 Control038"
g_subjects="Control038"

# Subjects with T1+T2+fMRI+fieldmaps
# g_subjects="Case001 Case002 Case003 Case009 Case010 Case011 Case014 Case015 Case027 Case029 \
# Control001 Control002 Control003 Control004 Control005 Control006 Control007 Control008 Control009 Control010 Control011 Control013 Control014 Control015 Control016 Control017 \
# Control018 Control019 Control021 Control022 Control023 Control024 Control025 Control028 Control032"

parent_dir=$analysis
orig_study_name="TSC-RO1-HCP"
new_study_name="TSC-RO1-FS"

get_unprocessed_data()
{
    subject=${1}
    
    local link_from=${parent_dir}/${orig_study_name}/${subject}/unprocessed
    local link_to=${parent_dir}/${new_study_name}/${subject}/unprocessed

    echo "Linking unprocessed data for subject: ${subject}"
    
    mkdir --parents ${link_to}
    local link_cmd="lndir -silent ${link_from} ${link_to}"
    ${link_cmd}
}

main()
{
    for subject in ${g_subjects} ; do
	get_unprocessed_data ${subject}
    done
}

# invoke the main function to get things started
main $@
