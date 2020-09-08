# HERVx

A containerized pipeline to characterize **H**uman **E**ndogenous **R**etro**v**irus e**x**pression (`HERVx`) within the human transcriptome.


HERVx calculates Human Endogenous Retrovirus (HERV) expression in paired-end
RNA-sequencing data. Quantifying HERV expression is difficult due to their repetitive nature and the high degree of sequence similarity shared among subfamilies-- leading to an inherit level of uncertainty during fragment assignment.

The HERVx pipeline runs cutadapt to remove adapter sequences and to perform
quality-trimming, bowtie2 to align reads against the Human reference genome (hg38), SAMtools to convert from SAM to BAM format  and to sort reads by name, and Telescope to characterize Human Endogenous Retrovirus (HERV) expression.

[Telescope](https://github.com/mlbendall/telescope) is a computational method that provides accurate estimation of transposable element expression (retrotranscriptome) resolved to specific genomic locations. Telescope directly addresses uncertainty in fragment assignment by reassigning ambiguously mapped fragments to the most probable source transcript as determined within a Bayesian statistical model.


The Dockerfile will build Cutadapt, bowtie2, SAMtools, HTSlib, and Telescope from scratch along with a few other tools. Small reference files are located in `/opt2/refs/` in the container's filesystem.

### Resources
Reference files, resources, and indices are bundled within the container's filesystem.

Currently, the following files are located in `/opt2/refs/`:
 - trimmonatic_TruSeqv3_adapters.fa
 - HERV_rmsk.hg38.v2.genes.gtf
 - HERV_rmsk.hg38.v2.transcripts.gtf
 - L1Base.hg38.v1.transcripts.gtf
 - retro.hg38.v1.transcripts.gtf


Bowtie2 indices for `hg38` are bundled in the container's filesystem in `/opt2/bowtie2/`. Other indices can be provided by mounting the host filesystem to this PATH (overrides current hg38 indices).

#### Build bowtie2 indices
```bash
# Get UCSC hg38 genome
wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
zcat hg38.fa.gz > hg38.fa

# Build the indices
module load singularity
SINGULARITY_CACHEDIR=$PWD singularity pull -F docker://nciccbr/ccbr_telescope
singularity exec -B $PWD:$PWD ccbr_telescope_latest.sif bowtie2-build hg38.fa hg38
```

#### Build Image from Dockerfile

In the example below, change `skchronicles` with your DockerHub username.

```bash
# See listing of images on computer
docker image ls

# Build
docker build --tag=ccbr_telescope:v0.0.1 .

# Updating tag(s) before pushing to DockerHub
docker tag ccbr_telescope:v0.0.1 skchronicles/ccbr_telescope:v0.0.1
docker tag ccbr_telescope:v0.0.1 skchronicles/ccbr_telescope        # latest
docker tag ccbr_telescope:v0.0.1 nciccbr/ccbr_telescope:v0.0.1
docker tag ccbr_telescope:v0.0.1 nciccbr/ccbr_telescope             # latest

# Check out new tag(s)
docker image ls

# Peak around the container: verify things run correctly
docker run -ti ccbr_telescope:v0.0.1 /bin/bash

# Push new tagged image to DockerHub
docker push skchronicles/ccbr_telescope:v0.0.1
docker push skchronicles/ccbr_telescope:latest
docker push nciccbr/ccbr_telescope:v0.0.1
docker push nciccbr/ccbr_telescope:latest
```

### Run using Singularity
```bash
module load singularity
# Pull from DockerHub
SINGULARITY_CACHEDIR=$PWD singularity pull -F docker://nciccbr/ccbr_telescope
# Display usage and help information
singularity exec -B $PWD:$PWD ccbr_telescope_latest.sif HERVx -h
# Run HERVx pipeline
singularity exec -B $PWD:$PWD ccbr_telescope_latest.sif HERVx -r1 small_S25_1.fastq -r2 small_S25_2.fastq -o ERV_hg38
```


### Notes
 - Reference files are located in /opt2/ of the container filesystem.
 - Dockerfile to build this image is located in `/opt2/Dockerfile`.
 - Pull latest image from [DockerHub](https://hub.docker.com/repository/docker/nciccbr/ccbr_telescope)
