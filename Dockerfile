FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------
# Install common dependencies
#----------------------------------------------------------
ENV LANG="en_US.UTF-8" \
    LC_ALL="C.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN apt-get update && apt-get install -yq --no-install-recommends \
        apt-utils \
        build-essential \
        bzip2 \
        ca-certificates \
        curl \
        dirmngr\
        git \
        gnupg2 \
        graphviz \
        libglib2.0-0 \
        libssl1.0.0\
        libssl-dev\
        locales \
        m4 \
        make \
        python2.7 \
        python-pip \
        python3 \
        python3-dev \
        rsync \
        unzip \
        wget

RUN wget -O- http://neuro.debian.net/lists/bionic.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list

RUN apt-key adv --recv-keys --keyserver pgp.mit.edu 0xA5D32F012649A5A9 || apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xA5D32F012649A5A9
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && localedef --force --inputfile=en_US --charmap=UTF-8 C.UTF-8 \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
        echo '#!/usr/bin/env bash' >> $ND_ENTRYPOINT \
        && echo 'set +x' >> $ND_ENTRYPOINT \
        && echo 'if [ -z "$*" ]; then /usr/bin/env bash; else $*; fi' >> $ND_ENTRYPOINT; \
    fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker

# make this run with Singularity, too.
RUN ldconfig

# install connectome workbench
RUN mkdir -p /opt
WORKDIR /opt
RUN curl --retry 5 https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.5.0.zip --output workbench-linux64-v1.5.0.zip && \
  unzip workbench-linux64-v1.5.0.zip && \
  rm workbench-linux64-v1.5.0.zip


#-------------------
# Install ANTs 2.2.0
#-------------------
RUN echo "Downloading ANTs ..." \
    && curl -sSL --retry 5 https://dl.dropbox.com/s/2f4sui1z6lcgyek/ANTs-Linux-centos5_x86_64-v2.2.0-0740f91.tar.gz \
    | tar zx -C /opt
ENV ANTSPATH=/opt/ants \
    PATH=/opt/ants:$PATH

#------------------------
# Install Convert3D 1.0.0
#------------------------
RUN echo "Downloading C3D ..." \
    && mkdir /opt/c3d \
    && curl -sSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download \
    | tar -xzC /opt/c3d --strip-components=1
ENV C3DPATH=/opt/c3d/bin \
    PATH=/opt/c3d/bin:$PATH

#--------------------------
# Install FreeSurfer v5.3.0-HCP
#--------------------------
RUN apt-get update -qq && apt-get install -yq --no-install-recommends bc libgomp1 libxmu6 libxt6 tcsh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "Downloading FreeSurfer ..." \
    && curl -sSL --retry 5 https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/5.3.0-HCP/freesurfer-Linux-centos6_x86_64-stable-pub-v5.3.0-HCP.tar.gz \
    | tar xz -C /opt \
    --exclude='freesurfer/average/mult-comp-cor' \
    --exclude='freesurfer/lib/cuda' \
    --exclude='freesurfer/lib/qt' \
    --exclude='freesurfer/subjects/V1_average' \
    --exclude='freesurfer/subjects/bert' \
    --exclude='freesurfer/subjects/cvs_avg35' \
    --exclude='freesurfer/subjects/cvs_avg35_inMNI152' \
    --exclude='freesurfer/subjects/fsaverage3' \
    --exclude='freesurfer/subjects/fsaverage4' \
    --exclude='freesurfer/subjects/fsaverage5' \
    --exclude='freesurfer/subjects/fsaverage6' \
    --exclude='freesurfer/subjects/fsaverage_sym' \
    --exclude='freesurfer/trctrain' \
    && sed -i '$isource $FREESURFER_HOME/SetUpFreeSurfer.sh' $ND_ENTRYPOINT

ENV FREESURFER_HOME=/opt/freesurfer

# FreeSurfer uses matlab and tries to write the startup.m to the HOME dir.
# Therefore, HOME needs to be a writable dir.
ENV HOME=/opt

#-----------------------------------------------------------
# Install FSL v5.0.10
# FSL is non-free. If you are considering commerical use
# of this Docker image, please consult the relevant license:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence
#-----------------------------------------------------------
RUN apt-get update -qq && apt-get install -yq --no-install-recommends bc dc libfontconfig1 libfreetype6 libgl1-mesa-dev libglu1-mesa-dev libgomp1 libice6 libxcursor1 libxft2 libxinerama1 libxrandr2 libxrender1 libxt6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "Downloading FSL ..." \
    && curl -sSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-5.0.10-centos6_64.tar.gz \
    | tar zx -C /opt \
    && sed -i '$iecho Some packages in this Docker container are non-free' $ND_ENTRYPOINT \
    && sed -i '$iecho If you are considering commercial use of this container, please consult the relevant license:' $ND_ENTRYPOINT \
    && sed -i '$iecho https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence' $ND_ENTRYPOINT \
    && sed -i '$isource $FSLDIR/etc/fslconf/fsl.sh' $ND_ENTRYPOINT

ENV FSLDIR=/opt/fsl \
    FSL_DIR=/opt/fsl \
    PATH=/opt/fsl/bin:$PATH


#---------------------
# Install MATLAB Compiler Runtime
#---------------------
RUN mkdir /opt/mcr /opt/mcr_download
WORKDIR /opt/mcr_download
RUN wget https://ssd.mathworks.com/supportfiles/downloads/R2017a/deployment_files/R2017a/installers/glnxa64/MCR_R2017a_glnxa64_installer.zip \
    && unzip MCR_R2017a_glnxa64_installer.zip \
    && ./install -agreeToLicense yes -mode silent -destinationFolder /opt/mcr \
    && rm -rf /opt/mcr_download

#---------------------
# Install MSM Binaries
#---------------------
RUN mkdir /opt/msm
RUN curl -ksSL --retry 5 https://www.doc.ic.ac.uk/~ecr05/MSM_HOCR_v2/MSM_HOCR_v2-download.tgz | tar zx -C /opt
RUN mv /opt/homes/ecr05/MSM_HOCR_v2/* /opt/msm/
RUN rm -rf /opt/homes /opt/msm/MacOSX /opt/msm/Centos
ENV MSMBINDIR=/opt/msm/Ubuntu

#----------------------------
# Make perl version 5.20.3
#----------------------------
RUN curl -sSL --retry 5 http://www.cpan.org/src/5.0/perl-5.20.3.tar.gz | tar zx -C /opt
WORKDIR /opt/perl-5.20.3
RUN ./Configure -des -Dprefix=/usr/local
RUN make && make install
RUN rm -f /usr/bin/perl && ln -s /usr/local/bin/perl /usr/bin/perl
WORKDIR /
RUN rm -rf /opt/perl-5.20.3/

#------------------
# Make libnetcdf
#------------------
RUN curl -sSL --retry 5 https://github.com/Unidata/netcdf-c/archive/v4.6.1.tar.gz | tar zx -C /opt
WORKDIR /opt/netcdf-c-4.6.1/
RUN LDFLAGS=-L/usr/local/lib && CPPFLAGS=-I/usr/local/include && ./configure --disable-netcdf-4 --disable-dap --enable-shared --prefix=/usr/local
RUN make && make install
WORKDIR /usr/local/lib
RUN ln -s libnetcdf.so.13.1.1 libnetcdf.so.6
RUN rm -rf /opt/netcdf-c-4.6.1/
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

#------------------------------------------
# Set Connectome Workbench Binary Directory
#------------------------------------------
RUN ln -s /opt/workbench/bin_linux64/wb_command /opt/workbench/wb_command
RUN mkdir /root/.config /.config
COPY ["brainvis.wustl.edu", "/opt/workbench/brainvis.wustl.edu"]
COPY ["brainvis.wustl.edu", "/root/.config/brainvis.wustl.edu"]
COPY ["brainvis.wustl.edu", "/.config/brainvis.wustl.edu"]
RUN chmod -R 775 /root/.config /.config
ENV WORKBENCHDIR=/opt/workbench \
    CARET7DIR=/opt/workbench/bin_linux64 \
    CARET7CONFDIR=/opt/workbench/brainvis.wustl.edu

# Fix libz error
RUN ln -s -f /lib/x86_64-linux-gnu/libz.so.1.2.11 /opt/workbench/libs_linux64/libz.so.1

# Fix libstdc++6 error
RUN ln -sf /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.25 /opt/mcr/v92/sys/os/glnxa64/libstdc++.so.6

#NOTE: The code above is built in the external-software image.
#So, it is possible to build all of the code below by starting with:
#FROM dcanlabs/external-software:<tag>

RUN pip install setuptools wheel
RUN pip install pyyaml numpy pillow pandas
RUN apt-get update && apt-get install -yq --no-install-recommends python3-pip
RUN pip3 install setuptools wheel

RUN mkdir /opt/dcan-tools
WORKDIR /opt/dcan-tools

# dcan bold processing
ADD https://github.com/DCAN-Labs/dcan_bold_processing.git version.json
RUN git clone -b v4.0.7 --single-branch --depth 1 https://github.com/DCAN-Labs/dcan_bold_processing.git dcan_bold_proc

# dcan executive summary
RUN git clone -b v2.2.10 --single-branch --depth 1 https://github.com/DCAN-Labs/ExecutiveSummary.git executivesummary
RUN gunzip /opt/dcan-tools/executivesummary/templates/parasagittal_Tx_169_template.scene.gz

# dcan custom clean
RUN git clone -b v0.0.0 --single-branch --depth 1 https://github.com/DCAN-Labs/CustomClean.git customclean

# dcan file mapper
RUN git clone -b v1.3.0 --single-branch --depth 1 https://github.com/DCAN-Labs/file-mapper.git filemapper

#NOTE: The code above is built in the internal-tools image.
#So, it is possible to build all of the code below by starting with:
#FROM dcanlabs/internal-tools:<tag>

COPY ["app", "/app"]
RUN python3 -m pip install -r "/app/requirements.txt"

# insert pipeline code
ADD https://github.com/DCAN-Labs/dcan-infant-pipeline.git version.json
RUN git clone -b 'v0.0.13' --single-branch --depth 1 https://github.com/DCAN-Labs/dcan-infant-pipeline.git /opt/pipeline


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



