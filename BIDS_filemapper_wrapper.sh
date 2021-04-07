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

scripts_dir=$(pwd)
if [ -d ${scripts_dir} ] && [ -e ${scripts_dir}/SubmitterEnv.sh ] ; then
    source ${scripts_dir}/SubmitterEnv.sh
fi

fmscript=${FILEMAPPERDIR}/file-mapper.py
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


