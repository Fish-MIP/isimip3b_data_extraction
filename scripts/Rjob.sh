#!/bin/bash

#PBS -P vf71
#PBS -q normalbw
#PBS -l ncpus=28
#PBS -l mem=252GB
#PBS -l walltime=02:00:00
#PBS -l storage=gdata/vf71
#PBS -M lilian.fierroarcos@utas.edu.au
#PBS -m abe
#PBS -l wd

module load R/4.3.1
module load cdo/2.6.0
module load hdf5/1.10.5

# Set number of OMP threads
export OMP_NUM_THREADS=$PBS_NCPUS

R --vanilla < calculating_yearly_values.R