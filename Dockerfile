FROM dcanumn/internal-tools:v1.0.9

ARG DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------
# Install common dependencies
#----------------------------------------------------------
ENV LANG="en_US.UTF-8" \
    LC_ALL="C.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN apt-get update && apt-get install -yq --no-install-recommends \
        apt-utils \
        graphviz \
        python-pip \
        python3 \
        python3-dev \
        wget

RUN pip install setuptools wheel
RUN pip install pyyaml numpy pillow pandas
RUN apt-get update && apt-get install -yq --no-install-recommends python3-pip
RUN pip3 install setuptools wheel

COPY ["app", "/app"]
RUN python3 -m pip install -r "/app/requirements.txt"

# insert pipeline code
ADD https://github.com/DCAN-Labs/dcan-infant-pipeline.git version.json
RUN git clone -b 'v0.0.14' --single-branch --depth 1 https://github.com/DCAN-Labs/dcan-infant-pipeline.git /opt/pipeline


# unless otherwise specified...
ENV OMP_NUM_THREADS=1
ENV SCRATCHDIR=/tmp/scratch
ENV ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
ENV TMPDIR=/tmp

# make app directories
RUN mkdir /bids_input /output /atlases

# Copy custom clean json.
COPY ["./baby_BIDS_cleaning.json", "/opt/dcan-tools/customclean/"]
COPY ["./baby_BIDS_no_session_cleaning.json", "/opt/dcan-tools/customclean/"]

# Copy file mapper files.
COPY ["./current_infant.json", "/opt/dcan-tools/filemapper/"]
COPY ["./current_infant_no_session.json", "/opt/dcan-tools/filemapper/"]
COPY ["./BIDS_filemapper_wrapper.sh", "/opt/dcan-tools/filemapper/"]

# setup ENTRYPOINT
COPY ["./entrypoint.sh", "/entrypoint.sh"]
COPY ["./SetupEnv.sh", "/SetupEnv.sh"]
RUN chmod -R 777 /SetupEnv.sh
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /
CMD ["--help"]



