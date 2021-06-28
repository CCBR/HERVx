## Copyright (c) CCR Collabortive Bioinformatics Resource (NCI), 2020
##
## DESCRIPTION:
## This WDL workflow runs the Human Endogenous Retrovirus expression pipeline (HERVx)
## on a single sample to characterize expression of the retrotranscriptome.
##
## The HERVx pipeline runs cutadapt to remove adapter sequences and to perform
## quality-trimming, bowtie2 to align reads against the Human reference genome (hg38),
## SAMtools to convert from SAM to BAM format  and to sort reads by name, and Telescope
## to characterize Human Endogenous Retrovirus (HERV) expression.
##
## Requirements/Assumptions:
## - Assumes singularity and/or Docker are installed on the target system
## - Default number of threads for multi-threaded applciations: 2
##
## Inputs:
## - Set of paired-end RNA-seq FASTQ files for a given sample
##     (i.e. SRR12345_1.fastq, SRR12345_2.fastq)
## - Path to output directory (i.e. tmp/)
##
## Outputs:
## - One TSV file, "telescope-telescope_report.tsv", containing calculated expression
##     values for individual transposable element locations
##
## Cromwell version support
## - Successfully tested on v29
## - Does not work on versions < v23 due to output syntax
##
## IMPORTANT NOTE: Reference files are located in /opt2/ in the container's filesystem.
##
## LICENSING:
## This script is released under the WDL source code license (BSD-3) (see LICENSE in
## https://github.com/broadinstitute/wdl). Note however that the programs it calls may
## be subject to different licenses. Users are responsible for checking that they are
## authorized to run all programs before running this script.
##
## Github:
## - https://github.com/CCBR/HERVx
## DockerHub:
## - https://hub.docker.com/repository/docker/nciccbr/ccbr_telescope
##
## WDL Specification:
## - https://github.com/openwdl/wdl/blob/main/versions/development/SPEC.md

# WDL specification version, cromwell does not support 1.1 yet
version 1.0

## Workflow Definition
######################

workflow hervx {

    # Global Workflow Inputs
    input {

        # Required Inputs
        File read1
        File read2
        String prefix

        # Optional Inputs
        # Default values are defined in the task definition
        String? docker
        String? outdir
        String? gtf 
        Int? prior 
        Int? max_iter
        Int? threads
        Int? mem
    }

    # Run telescope in parallel for each sample
    call telescope {
        input:
            read1 = read1,
            read2 = read2,
            prefix = prefix,
            hervx_outdir = outdir,
            hervx_gtf = gtf,
            hervx_prior = prior,
            hervx_max_iter = max_iter,
            hervx_threads = threads,
            hervx_docker = docker,
            hervx_mem = mem
    }

    # Main workflow outputs
    output {
        # HERV calculated expression: "/path/to/telescope-telescope_report.tsv"
        File output_telescope = telescope.telescope_output
    }

    # Workflow metadata
    parameter_meta {
        read1: {
            description: "Read 1 (R1) FastQ file(s) to be run through HERVx.",
            category: "required"
        }
        read2: {
            description: "Read 2 (R2) FastQ file(s) to be run through HERVx.",
            category: "required"
        }
        prefix: {
            description: "Base name of sample. This is the name of the sample without the PATH and the file extension",
            category: "required"
        }
        hervx_outdir:  {
            description: "Working directory to which the outputs will be written. [Default: output/]",
            category: "common"
        }
        gtf:  {
            description: "Input annotation file for Telescope in GTF format. [Default: HERV_rmsk.hg38.v2.transcripts.gtf]",
            category: "common"
        }
        prior:  {
            description: "Prior on theta for Telescope. [Default: 200000]",
            category: "common"
        }
        max_iter:  {
            description: "Maximum number of iterations to test convergence of the EM algorithm. [Default: 200]",
            category: "common"
        }
        threads:  {
            description: "Number of threads for multi-threaded applications. [Default: 2]",
            category: "common"
        }
        mem:  {
            description: "Amount of allocated memory (in GB) for computation. [Default: 8]",
            category: "common"
        }
        
        hervx_docker: {
            description: "Docker images needed for workflow execution. [Default: nciccbr/ccbr_telescope:latest]",
            category: "advanced"
        }
    }

    meta {author: "Skyler Kuhn" email: "kuhnsa@nih.gov"}
}


## Task Definition(s)
#####################

## 1. This task will run the HERVx pipeline starting with paired-end FastQ files
task telescope {

    input {
        # Required Inputs
        File read1
        File read2
        String prefix

        # Optional Inputs and Default Values
        String? hervx_docker
        String docker = select_first([hervx_docker, "nciccbr/ccbr_telescope:latest"])
        
        String? hervx_outdir
        String outdir = select_first([hervx_outdir, "output"])

        String? hervx_gtf
        String gtf = select_first([hervx_gtf, "HERV_rmsk.hg38.v2.transcripts.gtf"])

        Int? hervx_prior 
        Int prior = select_first([hervx_prior, 200000])

        Int? hervx_max_iter
        Int max_iter = select_first([hervx_max_iter, 200])

        Int? hervx_threads
        Int threads = select_first([hervx_threads, 2])

        Int? hervx_mem
        Int mem = select_first([hervx_mem, 8])
    }

    # Run HERVx
    command <<<
        HERVx -r1 ~{read1} -r2 ~{read2} -b ~{prefix} -o ~{outdir} \
                  -t ~{threads} -p ~{prior} -m ~{max_iter} -g ~{gtf}
    >>>

    output {
        File telescope_output = "~{outdir}/hervx/~{prefix}/telescope-telescope_report.tsv"
    }

    runtime {
        docker: docker
        cpu: threads
        memory: "~{mem} GB"
    }
}
