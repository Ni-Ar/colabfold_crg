#!/bin/bash

# ColabFold script with a conda env.
# Author: Niccolo' Arecco
# Last modifications 27/Feb/2023

# -- SGE JOB SUBMISSION SETTINGS
#$ -q gpu,gpu_long
#$ -pe smp 6
#$ -V
#$ -l virtual_free=64G
#$ -l h_vmem=64G 
#$ -l h_rt=85:30:50
#$ -l s_rt=85:30:50
#$ -terse
#$ -l gpu=1
#$ -N colabfold
#$ -wd /users/mirimia/narecco/software/colabfold
#$ -o /users/mirimia/narecco/software/colabfold/cf_stdout.log
#$ -e /users/mirimia/narecco/software/colabfold/cf_stderr.log
#$ -b y
# -- the commands to be executed (programs to be run) :

# TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
# echo -e "\n$TIMESTAMP start test\n"
# python python_configuration_test.py  
# TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
# echo -e "\n$TIMESTAMP end test\n"

# Run Colabfold with required parameters using qsub
# parameters details:
# --amber: Use 'Amber' force field relation to refine the structure and --use-gpu-relax to run this process on GPU instead of CPU.
# --templates: Use templates from pdb. PDB structures from the database enter the MSA module but are less important compared to the MSA itself. 
# --num-recycle N: AF parameter to perform N recyling step on the predicted model i.e. from the xyz PDB go back to the MSA module and perform the structure model again

PROJ_NAME="12_Predicted_Structures"
IN_FASTA_NAME="PRC2_SUZ12_ex4_inclu_cb-format.fasta"
INPUT="/users/mirimia/narecco/projects/${PROJ_NAME}/data/fasta/${IN_FASTA_NAME}"
OUTPUT="/users/mirimia/narecco/projects/${PROJ_NAME}/data/pdb/CF/PRC2_ex4_exclu"

# load NVIDIA driver's CUDA version 12+
module load CUDA/12.0.0
colabfold_batch --amber --templates --num-recycle 20 --recycle-early-stop-tolerance 0.5 \
                --use-gpu-relax --num-models 5 --model-order 1,2,3,4,5 \
                --random-seed 16 --model-type auto ${INPUT} ${OUTPUT}

# no vaya a ser que == por si (que)
# Coge el paraguas, por si llueve # indicativo
# Coge el paraguas, no vaya a ser que llueva # subjuntivo

# He cogido el paraguas, no sea que llueva
# He cogido el paraguas, no fuera que lloviese
