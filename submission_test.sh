#!/bin/bash

#$ -q gpu
#$ -pe smp 3
#$ -cwd
#$ -V
#$ -terse
#$ -l gpu=2
#$ -l virtual_free=12G
#$ -l h_vmem=12G
#$ -l h_rt=00:16:00
#$ -N gpu_test
#$ -o test_log_out.txt
#$ -e test_log_err.txt
#$ -b y

echo -e "\nBeginning a simple configuration test!\n"

# Set the working directory where the colabfold params are saved.
CF_DIR="${HOME}/software/colabfold"
cd $CF_DIR

## TensorFlow control
# export TF_FORCE_UNIFIED_MEMORY="1" 
# export XLA_PYTHON_CLIENT_MEM_FRACTION="4.0"
# export XLA_FLAGS="--xla_gpu_force_compilation_parallelism=1" 
# export COLABFOLDDIR="${HOME}/software/colabfold"
# export XDG_CACHE_HOME="${HOME}/software/colabfold"

python python_configuration_test.py  

echo -e "\nChecking GPUs\n"

nvcc --version

nvidia-smi

echo -e "\nChecking GNU compiler version\n"

gcc --version

echo -e "\nEnd of the test, check the log files.\n"
