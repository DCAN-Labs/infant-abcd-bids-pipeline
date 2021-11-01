# dcanumn/infant-abcd-bids-pipeline
A pipeline, based on abcd-hcp-pipeline, to process fMRI data for human infants.

The repository contains the Dockerfile, entrypoint.sh, SetupEnv.sh and the app
folder containing the BIDS App source. All of this is needed in order for
Docker Hub to build the infant-abcd-bids-pipeline.

When a release is made and Docker Hub's auto-build has completed, the Docker
image can be loaded on your server as follows:
```
docker pull dcanumn/infant-abcd-bids-pipeline
```

Optionally, a user can clone the repository and build the Docker image in place
using the build-and-zip.sh script.

