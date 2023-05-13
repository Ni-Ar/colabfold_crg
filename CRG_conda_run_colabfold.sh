#!/bin/bash

# Submitting ColabFold jobs to the CRG gpu queues with conda env
# Author: Niccolo' Arecco
# Last modifications 13/May/2023

# -- SGE JOB SUBMISSION SETTINGS
# -- Change the <paths> for the logs and other <options>:
#$ -q gpu_long
#$ -pe smp 6
#$ -V
#$ -l virtual_free=64G
#$ -l h_vmem=64G 
#$ -l h_rt=166:50:50
#$ -l s_rt=166:50:50
#$ -terse
#$ -l gpu=1
#$ -m bea
#$ -M <name>.<surname>@crg.eu
#$ -N cf_<SOMETHING>
#$ -wd /users/<group>/<user>/software/colabfold
#$ -o /users/<group>/<user>/software/colabfold/cf_stdout.log
#$ -e /users/<group>/<user>/software/colabfold/cf_stderr.log
#$ -b y

# -- Change path to your input
INPUT="${HOME}/<path>/<to>/<your>/<input>/<fasta>"

# Get input basename:
FASTA_SUFFIX_REGEX="fasta$"
if [[ $INPUT =~ $FASTA_SUFFIX_REGEX ]]; then
    # in case the input is a file file that ends with ".fasta" file format
    INPUT_NAME=$( basename $INPUT .fasta )
else 
    # in case the input is a folder
    INPUT_NAME=$( basename $INPUT )
fi 

# -- Specify path for your output
OUTPUT="${HOME}/<path>/<to>/<your>/<output>/pdb/CF/${INPUT_NAME}"

# Load NVIDIA driver's CUDA version 12+. 
# Note: The gpu configuration still fails to find this drivers but the predictions still run
module load CUDA/12.0.0

# -- Change your parameters here:
# Parameters Details:
# --amber: Use 'Amber' force field relation to refine the structure and --use-gpu-relax to run this process on GPU instead of CPU.
# --templates: Use templates from pdb. PDB structures from the database enter the MSA module but are less important compared to the MSA itself. 
# --num-recycle N: AF parameter to perform N recyling step on the predicted model i.e. from the xyz PDB go back to the MSA module and perform the structure model again
colabfold_batch --amber --templates --num-recycle 20 --recycle-early-stop-tolerance 0.5 \
                --use-gpu-relax --num-models 5 --model-order 1,2,3,4,5 \
                --random-seed 16 --model-type auto ${INPUT} ${OUTPUT}
