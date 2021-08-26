#! /bin/bash
set -x
TAG=$1  # Optional. If given, the tag will be used in the image name *and* in the filenames.
pipeline=infant-abcd-bids-pipeline
if [ -n "${TAG}" ] ; then
    imagename=dcanlabs/${pipeline}:${TAG}
    tarfile=${pipeline}_${TAG}.tar
else
    imagename=dcanlabs/${pipeline}:latest
    tarfile=${pipeline}_${datestamp}.tar
fi

pushd /mnt/max/shared/code/internal/utilities/dcan-stack_dockerfiles/infant-abcd-bids-pipeline
./change_permissions.sh
docker build . -t ${imagename}
popd


