#!/bin/bash

#$ -q gpu
#$ -pe smp 6
#$ -cwd
#$ -V
#$ -terse
#$ -l gpu=3
#$ -l virtual_free=64G
#$ -l h_vmem=64G
#$ -l h_rt=00:46:59
#$ -N gpu_test
#$ -m ea
#$ -M [niccolo.arecco@crg.eu](mailto:niccolo.arecco@crg.eu)
#$ -o test_log_out.txt
#$ -e test_log_err.txt
#$ -b y

echo -e "\nBeginning a simple installation test!\n"

# Set the working directory where the colabfold params are saved.
CF_DIR="${HOME}/software/colabfold"
cd $CF_DIR

## TensorFlow control
export TF_FORCE_UNIFIED_MEMORY="1" 
export XLA_PYTHON_CLIENT_MEM_FRACTION="4.0"
export XLA_FLAGS="--xla_gpu_force_compilation_parallelism=1" 
export COLABFOLDDIR="${HOME}/software/colabfold"
export XDG_CACHE_HOME="${HOME}/software/colabfold"

python /users/mirimia/narecco/software/colabfold/python_configuration_test.py  

echo -e "\nChecking GPUs\n"

nvcc --version

!nvidia-smi

echo -e "\nChecking GNU compiler version\n"

gcc --version

echo -e "\nEnd of the test, check the log files.\n"