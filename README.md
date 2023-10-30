# dcanumn/infant-abcd-bids-pipeline

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7683282.svg)](https://doi.org/10.5281/zenodo.7683282)

This pipeline leverages the [The DCAN Labs Infant Processing Pipeline](https://github.com/DCAN-Labs/dcan-infant-pipeline).

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

