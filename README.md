# HERVx

![badge](https://action-badges.now.sh/CCBR/HERVx?action=ci)  [![GitHub issues](https://img.shields.io/github/issues/CCBR/HERVx)](https://github.com/CCBR/HERVx/issues)  [![GitHub license](https://img.shields.io/github/license/CCBR/HERVx)](https://github.com/CCBR/HERVx/blob/master/LICENSE)  

### Table of Contents
1. [Introduction](#1-Introduction)  
2. [Build Resources](#2-Build-Resources)  
    2.1 [Bowtie2 Indices](#21-Bowtie2-indices)  
    2.2 [Image from Dockerfile](#22-Image-from-Dockerfile)   
3. [Run HERVx pipeline](#3-Run-HERVx-pipeline)  
    3.1 [Using Singularity](#31-Using-Singularity)  
    3.2 [Using Docker](#32-Using-Docker)  
    3.3 [Using WDL and Cromwell](#33-Using-WDL-and-Cromwell)
4. [TLDR](#4-TLDR)
5. [References](#5-References)



### 1. Introduction  
**H**uman **E**ndogenous **R**etro**v**irus e**x**pression pipeline, as known as `HERVx`, is a containerized pipeline to characterize retrotranscriptome. Quantifying HERV expression is difficult due to their repetitive nature and the high degree of sequence similarity shared among subfamilies— leading to an inherit level of uncertainty during fragment assignment.

HERVx calculates Human Endogenous Retrovirus (HERV) expression in paired-end
RNA-sequencing data. The pipeline runs cutadapt<sup>1</sup> to remove adapter sequences and to perform quality-trimming, bowtie2<sup>2</sup> to align reads against the Human reference genome (hg38), SAMtools<sup>3</sup> to convert from SAM to BAM format  and to sort reads by name, and Telescope<sup>4</sup> to characterize Human Endogenous Retrovirus (HERV) expression.

[Telescope](https://github.com/mlbendall/telescope) is a computational method that provides accurate estimation of transposable element expression. It directly addresses uncertainty in fragment assignment by reassigning ambiguously mapped fragments to the most probable source transcript as determined within a Bayesian statistical model.

The Dockerfile will build cutadapt, bowtie2, SAMtools & HTSlib, and Telescope from scratch along with a few other tools. Small reference files are located in `/opt2/refs/` in the container's filesystem.

### 2. Build Resources
Reference files, resources, and indices are bundled within the container's filesystem.

Currently, the following files are located in `/opt2/refs/`:
 - trimmonatic_TruSeqv3_adapters.fa
 - HERV_rmsk.hg38.v2.genes.gtf
 - HERV_rmsk.hg38.v2.transcripts.gtf
 - L1Base.hg38.v1.transcripts.gtf
 - retro.hg38.v1.transcripts.gtf


Bowtie2 indices for `hg38` are bundled in the container's filesystem in `/opt2/bowtie2/`. Other indices can be provided by mounting the host filesystem to this PATH (overrides current hg38 indices).

#### 2.1 Bowtie2 indices
```bash
# Get UCSC hg38 genome
wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
zcat hg38.fa.gz > hg38.fa

# Build the indices
module load singularity
SINGULARITY_CACHEDIR=$PWD singularity pull -F docker://nciccbr/ccbr_telescope
singularity exec -B $PWD:$PWD ccbr_telescope_latest.sif bowtie2-build hg38.fa hg38
```

#### 2.2 Image from Dockerfile
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

### 3. Run HERVx pipeline
#### 3.1 Using Singularity
```bash
module load singularity
# Pull from DockerHub
SINGULARITY_CACHEDIR=$PWD singularity pull -F docker://nciccbr/ccbr_telescope
# Display usage and help information
singularity exec -B $PWD:$PWD ccbr_telescope_latest.sif HERVx -h
# Run HERVx pipeline
singularity exec -B $PWD:$PWD ccbr_telescope_latest.sif HERVx -r1 tests/small_S25_1.fastq -r2 tests/small_S25_2.fastq -o ERV_hg38
```

#### 3.2 Using Docker
```bash
# Assumes docker in $PATH
docker run -v $PWD:/data2 nciccbr/ccbr_telescope:latest HERVx -r1 tests/small_S25.R1.fastq.gz -r2 tests/small_S25.R2.fastq.gz -o ERV_hg38
```

#### 3.3 Using WDL and Cromwell
```bash
# hervx is configured to use different cromwell execution backends: local or slurm
# view the help page for more information
./hervx --help

# @local: uses local singularity cromwell backend
# The local EXECUTOR will run serially on compute
# instance. This is useful for testing, debugging,
# or when a users does not have access to a high
# performance computing environment.
./hervx local -r1 tests/small_S25.R1.fastq.gz -r2 tests/small_S25.R2.fastq.gz --outdir /scratch/$USER/hervx_ouput

# @slurm: uses slurm and singularity cromwell backend
# The slurm EXECUTOR will submit jobs to the cluster.
# It is recommended running hervx in this mode.
./hervx slurm -r1 tests/small_S25.R1.fastq.gz -r2 tests/small_S25.R2.fastq.gz --outdir /scratch/$USER/hervx_ouput
```

### 4. TLDR
 **Reference files** are located in `/opt2/` of the container filesystem.  
**Dockerfile** to build this image is located in `/opt2/Dockerfile`\.  
**Pull** latest image from [DockerHub](https://hub.docker.com/repository/docker/nciccbr/ccbr_telescope)  
**Usage**  
&emsp;`singularity exec docker://nciccbr/ccbr_telescope HERVx -h`  
&emsp;`docker run nciccbr/ccbr_telescope:latest HERVx -h`

### 5. References  
<sup>**1.**	Martin, M. (2011). "Cutadapt removes adapter sequences from high-throughput sequencing reads." EMBnet 17(1): 10-12.</sup>  
<sup>**2.** Langmead, B. and S. L. Salzberg (2012). "Fast gapped-read alignment with Bowtie 2." Nat Methods 9(4): 357-359.</sup>  
<sup>**3.** Li, H., et al. (2009). "The Sequence Alignment/Map format and SAMtools." Bioinformatics 25(16): 2078-2079.</sup>  
<sup>**4.** Bendall, M. L., et al. (2019). "Telescope: Characterization of the retrotranscriptome by accurate estimation of transposable element expression." PLOS Computational Biology 15(9): e1006453.</sup>


<hr>
<p align="center">
	<a href="#HERVx">Back to Top</a>
</p>
