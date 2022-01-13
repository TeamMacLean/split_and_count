#!/bin/bash

#SBATCH -p tsl-medium
#SBATCH --mem=16G
#SBATCH -c 4
#SBATCH -J fastqc.$SLURM_JOBID
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=dan.maclean@tsl.ac.uk
#SBATCH -o fastqc.%j.out
#SBATCH -e fastqc.%j.err

OUTDIR=$1
FR=$2
RR=$3


source fastqc-0.11.5
srun fastqc -o $OUTDIR $FR $RR