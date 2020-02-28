#! /bin/bash
set -x
TAG=$1  # Optional. If given, the tag will be used in the image name *and* in the filenames.
pipeline=dcan-infant-pipeline
datestamp=$( date +%Y%m%d )
if [ -n "${TAG}" ] ; then
    imagename=dcanlabs/${pipeline}_${TAG}
    tarfile=${pipeline}_${TAG}.tar
else
    imagename=dcanlabs/${pipeline}
    tarfile=${pipeline}_${datestamp}.tar
fi

pushd /mnt/max/shared/code/internal/utilities/dcan-stack_dockerfiles/infant-abcd-bids-pipeline
./change_permissions.sh
docker build . -t ${imagename}
popd

pushd /mnt/max/shared/code/internal/utilities/docker_images
docker save -o ${tarfile} ${imagename}
chmod g+rw ${tarfile}
gzip -f ${tarfile}
popd

