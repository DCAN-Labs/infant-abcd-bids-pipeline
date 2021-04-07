#! /bin/bash

# The file mapper uses a 'template' json file and replaces {SUBJECT}, {SESSION}, and
# {PIPELINE} strings with the subject number, session number, and pipeline name provided
# to it. However, it does not handle task-specific files (esp. motion regressors). This
# wrapper looks for task-specific files for each of the tasks it finds in the pipeline's
# output. It copies the task files to the appropriate locations/names and then calls
# file_mapper_script.py to copy the non-task files.
#

# Required
SUB=$1            # subject number - no 'sub-'.
SES=$2            # session number - no 'ses-'.
FILES=$3          # path to subject/session/files.
TEMPLATE_JSON=$4  # json file to use as a template.
shift 4

PIPE=infant-abcd-bids-pipeline

if [ -z "${SUB}" ] || [ -z "${SES}" ]  || [ -z "${FILES}" ]  || [ -z "${TEMPLATE_JSON}" ] ; then
    echo "usage: $0 subject-id session-id path-to-processed-data path-to-template-json "
    exit 1
fi

# Set up strings to use for subject, session, paths etc.
session_dir=$( dirname ${FILES} )
session=$( basename ${session_dir} )
subject_dir=$( dirname ${session_dir} )
subject=$(basename ${subject_dir} )
if [[ "${session}" == "ses-${SES}" ]] && [[ "${subject}" == "sub-${SUB}" ]] ; then
    ROOT=$( dirname ${subject_dir} )
else
    echo There is a problem with the processed data. Expected path to end with sub-${SUB}/ses-${SES}/files.
    echo The path provided does not match that pattern. Path is: ${FILES}.
fi

results=${FILES}/MNINonLinear/Results
if ! [ -d ${results} ]; then
    echo "ERROR: Filemapper is unable to find directory ${results}. "
    exit 1
fi

derivs="${ROOT}/derivatives/${PIPE}/${subject}/${session}"
func="${derivs}/func"
mkdir -p ${func}


####### START PROCESSING #############
# Handle special cases.
#
# Each subject/session can have a different set of tasks and different numbers
# of runs of each.
#
# Furthermore, we may or may not have filtered files.
#
# These special cases cannot be handled with the json, because we would need
# to put in source and destination files for every possible combination.

shopt -s nullglob
pushd ${files}/${results} > /dev/null
pushd ${results} > /dev/null

# Each fMRI (task/run combination) has a subdirectory in processed files, in
# MNINonLinear/Results. We can use those subdirectories to get the names of the
# fMRIs.
# If filtering (bandstop) was used, there will be one file of filtered movement
# regressors for each fMRI.
# For example:
#    MNINonLinear/Results/ses-1_task-rest_run-02/DCANBOLDProc_v4.0.0/DCANBOLDProc_v4.0.0_bs18.582_25.7263_filtered_Movement_Regressors.txt

filtered=( */DCANBOLDProc_v4.0.0/DCANBOLDProc_v4.0.0*filtered_Movement_Regressors.txt )
num=${#filtered[@]}
if (( num > 0 )) ; then
    for filtered_in in ${filtered[@]} ; do
        TASK=${filtered_in%%/*}  # task name is *top* dirname.
        if [[ ${TASK} =~ ses- ]] ; then
            bids_prefix=${subject}_${TASK}
        elif [[ ${TASK} =~ task- ]] ; then
            bids_prefix=${subject}_${session}_${TASK}
        else
            echo "WARNING: Unable to make a valid bids name from ${TASK}."
            bids_prefix=${subject}_${TASK}
        fi

        # Get the filtered motion file for this task.
        filtered_out=${func}/${bids_prefix}_desc-filtered_motion.tsv
        tr ' ' '\t' <<< "X Y Z RotX RotY RotZ XDt YDt ZDt RotXDt RotYDt RotZDt" > ${filtered_out}
        cat ${filtered_in} | tr ' ' '\t' >> ${filtered_out}
    done

    # If we are here, then there was at least one filtered file. Therefore, the
    # ptseries **are** filtered, even though the names don't reflect that. So,
    # while we are in this part of the code, where we know we had at least one
    # filtered movement regressors file, make the string to be used in the
    # destination ptseries files (below).
    ptseries_end="desc-filtered_timeseries.ptseries.nii"
else
    # Since there were no filtered movement regressors files, we know that
    # filtering was not used. The ptseries files are unfiltered.
    ptseries_end="timeseries.ptseries.nii"
fi

# There should always be unfiltered motion regressors. Visit each task directory.
# Get the Atlas time series for each as well.
for TASK in $( ls -1d *task*/ ) ; do
    TASK=${TASK%/}
    if [[ ${TASK} =~ ses- ]] ; then
        bids_prefix=${subject}_${TASK}
    elif [[ ${TASK} =~ task- ]] ; then
        bids_prefix=${subject}_${session}_${TASK}
    else
        echo "WARNING: Unable to make a valid bids name from ${TASK}."
        bids_prefix=${subject}_${TASK}
    fi

    unfiltered_in="${TASK}/Movement_Regressors.txt"
    unfiltered_out="${func}/${bids_prefix}_motion.tsv"

    if [ -e ${unfiltered_in} ] ; then
        # To be valid motion.tsv files, the motion regressors are required to have
        # column headers and be tab-separated (per BEP012).
        tr ' ' '\t' <<< "X Y Z RotX RotY RotZ XDt YDt ZDt RotXDt RotYDt RotZDt" > ${unfiltered_out}
        cat ${unfiltered_in} | tr ' ' '\t' >> ${unfiltered_out}
    else
        echo "ERROR: Filemapper is unable to find file ${unfiltered_in}."
        continue
    fi

    cp ${TASK}/${TASK}_Atlas.dtseries.nii ${func}/${bids_prefix}_bold_timeseries.dtseries.nii
done

popd > /dev/null
shopt -u nullglob


fmscript=${FILEMAPPERDIR}/file_mapper_script.py
CMD="${fmscript} ${TEMPLATE_JSON} -a copy -o -s -sp ${FILES} -dp ${ROOT} -t SUBJECT=${SUB},SESSION=${SES},PIPELINE=${PIPE}"
set -x
eval ${CMD}
set +x

result=$?
if (( 0 == result )) ; then
    echo "FileMapper was successful."
else
    echo "FileMapper had errors."
    false
fi


