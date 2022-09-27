#!/bin/sh

# ColabFold script with a conda env.
# Author: Niccolo' Arecco
# Last modifications 23/Sept/2022

usage() {
        echo ""
        echo "Please make sure all required parameters are given"
        echo "Usage: $0 <OPTIONS>"
        echo "Required Parameters:"
        echo "-i <DIR|FASTA>          Path to directory with input fasta/a3m files or a csv/tsv file or a fasta file or an a3m file."
        echo "-q <'gpu'|'gpu_long'>   Name of the CRG gpu queue to use. This script selects the right hard resource to use for the prediction based on the queue."
        echo "Additional Parameters:"
        echo "-o <OUTPUT/PATH/DIR>    Path to a directory that will store the results."
        echo "-m <'multi'>            Run CF with AF2 multimer mode. Deafult is <'auto'>"
        echo ""
        exit 1
}

while getopts ":i:o:q:m:" i; do
        case "${i}" in
        i)
                INPUT=$OPTARG
        ;;
        o)
                OUTPUT_DIR=$OPTARG
        ;;
        q)
                QUEUE_NAME=$OPTARG
        ;;
        m)      MODEL_TYPE=$OPTARG
        ;;
        esac
done

# REQUIRED PARAMS
# Parse params and set defaults
if [[ "$INPUT" == "" ]] ; then
    echo -e "\nSpecify the input directory!\n"
    echo "-i <DIR|FASTA> Path to directory with input fasta/a3m files or a csv/tsv file or a fasta file or an a3m file."
    exit
fi

if [[ "$QUEUE_NAME" == "" ]] ; then
    echo -e "\nSpecify the CRG queue name.\n\tInput provided: '$QUEUE_NAME'. Select one of:\n\tgpu: 6 hours max, unlimited GPUs (max 10)\n\tgpu_long: 7 days max, max 2 GPUs.\n"
    echo "-q <gpu|gpu_long> Name of the CRG gpu queue to use. This script selects the right hard resource to use for the prediction based on the queue."
    exit
fi

# print info about the fasta file:
FASTA_SUFFIX_REGEX="fasta$"
if [[ $INPUT =~ $FASTA_SUFFIX_REGEX ]]; then
    # in case the input is a file file that ends with ".fasta" file format
    INPUT_NAME=$( basename $INPUT .fasta )
else 
    # in case the input is a folder
    INPUT_NAME=$( basename $INPUT )
fi 
echo -e "Input name: $INPUT_NAME"

# ADDITIONAL PARAMS
## OUTPUT
if [[ "$OUTPUT_DIR" == "" ]] ; then

    # If output is not specified create one based on the user.
    if [[ $USER =~ "narecco" ]] ; then
        OUTPUT_DIR="${HOME}/projects/12_Predicted_Structures/data/pdb/CF/${INPUT_NAME}"
    else
	    OUTPUT_DIR="${HOME}/pdb/CF/${INPUT_NAME}" 
    fi

    # if output location doesn't exist create one
    if [ -d ${OUTPUT_DIR} ]  ; then
        echo -e "Automatic output directory already exists!\n${OUTPUT_DIR}\nStopping to avoid re-computing or overwriting!" 
        exit
    else
        mkdir -p ${OUTPUT_DIR}
        echo -e "Saving output to default location. If you want use -o <PATH> to specify where to save the results."
    fi
else 
    echo -e "Output directory: $OUTPUT_DIR"     
fi

## MULTIMER MODEL 
if [[ "$MODEL_TYPE" == "multi" ]] ; then
    MODEL_CMD=$( echo "--model-type AlphaFold2-multimer-2" )
elif [[ "$MODEL_TYPE" == "" ]] ; then
    MODEL_CMD=$( echo "--model-type auto" )
fi

# Time ref
DATE=`date +%Y_%m_%d`

# How many resources to use?
Num_Ram=64      # In GigaBytes for the CPUs
Num_Processes=6 # For the CPUs

# Based on CRG max allowed resources
if [[ "$QUEUE_NAME" == "gpu" ]] ; then
   Num_Hours=01
   Num_GPUs=1
elif [ "$QUEUE_NAME" == "gpu_long" ] ; then
   Num_Hours=167
   Num_GPUs=1
else 
   echo -e "QUEUE_NAME must be either 'gpu' or 'gpu_long', not ${$QUEUE_NAME}\nAborted\n"
   exit 
fi 

# Set the working directory where the colabfold params are saved.
CF_DIR="${HOME}/software/colabfold"
cd $CF_DIR

## Exporting local variables 
# export NVIDIA_VISIBLE_DEVICES='all'

## TensorFlow control
# "1" to enable unified memory
export TF_FORCE_UNIFIED_MEMORY="1" 

## JAX control
# If your JAX process fails with out-of-memory (OOM) errors, the following environment variables can be used to override the default behavior:

# Disables the preallocation behavior, potentially decreasing the overall memory usage. This behavior is more prone to GPU memory fragmentation, meaning a JAX program that uses most of the available GPU memory may OOM with preallocation disabled
# export XLA_PYTHON_CLIENT_PREALLOCATE=false

# If jobs fails try: 4.0, 2.0, 9.0, 0.5
# If preallocation is enabled, this makes JAX preallocate XX% of currently-available GPU memory, instead of the default 90%. Lowering the amount preallocated can fix Out-Of-Memories errors that occur when the JAX program starts
export XLA_PYTHON_CLIENT_MEM_FRACTION="4.0"

## Other stuff
# Usually required otherwise I get UNKNOWN error. This slows down compiling the model. Future CUDA drivers might not need this anymore.
export XLA_FLAGS="--xla_gpu_force_compilation_parallelism=1" 
# export XLA_PYTHON_CLIENT_ALLOCATOR="platform"
# export TF_FORCE_GPU_ALLOW_GROWTH="true"

## ColabFold control
export COLABFOLDDIR="${HOME}/software/colabfold"
export XDG_CACHE_HOME="${HOME}/software/colabfold"

## Set up directories paths
JOBS_OUT_DIR="${HOME}/qsub_out/${DATE}/CF"
mkdir -p ${JOBS_OUT_DIR}

# Print info before running the job
echo -e "\n\tCRG Queue: ${QUEUE_NAME}\n\tMax wallclock time allowed per prediction: ${Num_Hours}:59 (hh:mm)\n\tNum Processes: ${Num_Processes}\n\tCPU Ram per process: ${Num_Ram}Gb\n\tNum GPU(s): ${Num_GPUs} (NVIDIA RTX 2080 Ti)\n\tOuput: ${OUTPUT_DIR}\n\tLog file: ${JOBS_OUT_DIR}/${INPUT_NAME}_std{out|err}.log"

echo -e "\n\tGPU exported variables\n\tVisible GPUs: $NVIDIA_VISIBLE_DEVICES\n\tTensorFlow unified memory: $TF_FORCE_UNIFIED_MEMORY\n\tAllow GPU memory pre-allocation: $XLA_PYTHON_CLIENT_PREALLOCATE\n\tPre-allocated percentage of currently-available GPU memory (if allowed): $XLA_PYTHON_CLIENT_MEM_FRACTION%\n\tMinimal GPU footprint: $XLA_PYTHON_CLIENT_ALLOCATOR\n\tAllow GPU growth: $TF_FORCE_GPU_ALLOW_GROWTH"

sleep 2

# Run Colabfold with required parameters using qsub
# parameters details:
# --amber: Use 'Amber' force field relation to refine the structure and --use-gpu-relax to run this process on GPU instead of CPU.
# --templates: Use templates from pdb. PDB structures from the database enter the MSA module but are less important compared to the MSA itself. 
# --num-recycle N: AF parameter to perform N recyling step on the predicted model i.e. from the xyz PDB go back to the MSA module and perform the structure model again

qsub -q ${QUEUE_NAME} -V -pe smp ${Num_Processes} -l gpu=${Num_GPUs} \
     -l virtual_free=${Num_Ram}G,h_vmem=${Num_Ram}G,h_rt=${Num_Hours}:59:00 \
     -terse -wd ${CF_DIR} -N cf-${INPUT_NAME} \
     -o "${JOBS_OUT_DIR}/${INPUT_NAME}_stdout.log" \
     -e "${JOBS_OUT_DIR}/${INPUT_NAME}_stderr.log" \
     -b y \
     colabfold_batch --amber --templates --num-recycle 4 --use-gpu-relax --num-models 3 --model-order 1,2,3 \
                     --random-seed 16 ${MODEL_CMD} ${INPUT} ${OUTPUT_DIR}

# no vaya a ser que == por si (que)
# Coge el paraguas, por si llueve # indicativo
# Coge el paraguas, no vaya a ser que llueva # subjuntivo

# He cogido el paraguas, no sea que llueva
# He cogido el paraguas, no fuera que lloviese
