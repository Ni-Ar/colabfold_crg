# FAQ

What is this?

 - My installation notes and script for running ColabFold on the [CRG](https://www.crg.eu/) GPU clusters.

What is ColabFold?
 - Read the [paper](https://www.nature.com/articles/s41592-022-01488-1) and check the [GitHub repository](https://github.com/sokrypton/ColabFold).

I don't want to deal with installation and scripts, where can I find pre-computed structures?
- If your *canonical* protein has a [UniProt](https://www.uniprot.org/) ID just search it in the [EBI Alphafold database](https://alphafold.ebi.ac.uk/).

My protein sequence is not in UniProt how can I quickly run ColabFold?
- Use one of the offical [google colab notebooks](https://github.com/sokrypton/ColabFold#making-protein-folding-accessible-to-all-via-google-colab).

I'm looking for something a bit more streamlined to implement in existing workflows. Running code from a web browser tab is not always ideal, e.g. lots of sequences to model and integrate with other tools.
- Then you've come to right place and this repo could be useful for you!

What is this repo actually containing?
- Basically the [LocalColabFold](https://github.com/YoshitakaMo/localcolabfold) installation steps and a script for submitting to the CRG graphics cards.

What are the advantages of using this *local* ColabFold?

- You don't have the 12 hours time limitations as for Google Colabs Notebooks. (CRG max time is 168 hours on `gpu_long`). 
- Access to the GPU is more reliable as you'll use your local graphics card.
- No need to re-install everything each time as for the Colab notebooks.
- Differently from AlphaFold2 you don't have to download the massive databases as everything is done on the ColabFold servers (that also cache queries!). 
- Structure prediction and `amber` relaxion are done on the GPUs, i.e. faster prediction.
- More control on advanced parameters.

What's the *longest* protein structure I can predict?

- In my experience I predicted a 4 proteins complex with a combined sequence length of 2328 aminoacids. (I believe the biggest limiting factor is the MSA size)

Is this script limited to the CRG users? 

- No, I believe, with minimal tweaking, an experienced user can get it to work on other job schedulers for HPC clusters with Nvidia graphics cards.

# Quick start

From a CRG cluster ant-login node:

```sh
conda activate colabfold
qsub ./CRG_conda_run_colabfold.sh
```

where inside `CRG_conda_run_colabfold.sh` you specify the input fasta file and the `colabfold_batch` parameters and this will submit a job using the CRG graphics cards.

# Installation

These following steps are adapted from [this script of localColabFold](https://github.com/YoshitakaMo/localcolabfold/blob/main/install_colabbatch_linux.sh) repository. The installation fits my current folder structure and already existing conda.

## Make a `conda` environment
If you don't have `miniconda` please first [install it](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html). If you have `conda` already installed please pay attention where it is installed with `which conda`. In my case, it returns `~/software/miniconda/condabin/conda`, however for most people it usually returns `~/miniconda3/condabin/conda`. This is important because later there is one source code editing hack to the colabfold python scripts installed by `conda`. 

Create a `software/colabfold` directory where some important files will be stored (e.g. Alphafold2 parameters and `matplotlib`).

```sh
mkdir -p ~/software/colabfold ; cd ~/software/colabfold
```
Now create a new `conda` environment with:
```sh
conda create --name colabfold python==3.8 -y
conda activate colabfold
```
*Optionally*, start by first updating `conda` with:

```sh
conda update -n base conda -y
```
This was tested with `conda` version 4.14.0.

**Note**: once `conda` is successfully installed please check that in your `.bashrc` you have something that looks like this:

```sh
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/users/<group>/<users>/software/miniconda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/users/<group>/<users>/software/miniconda/etc/profile.d/conda.sh" ]; then
        . "/users/<group>/<users>/software/miniconda/etc/profile.d/conda.sh"
    else
        export PATH="/users/<group>/<users>/software/miniconda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
```

where your `<group>` is your CRG group name and `<user>` is your login username.

Also check that your `.bash_profile` has a line like this:

```sh
export PATH=$PATH:$HOME/software/miniconda3/bin
```

To export miniconda.

## Linux Requirment

1. For CRG users you need to [open a ticket to IT](https://request.crg.es/) to request access to the GPU cluster.

To check if you can access the CRG gpu queue try the following from the ant-login node:
```sh
qrsh -q gpu
```
and wait until the login access request is processed. However if the cards are in use you won't be able to access them. You can check the available graphics card details with: `nvidia-smi`

2. Make sure your Cuda compiler driver is **11.1 or later** (if you don't plan to use a GPU, you can skip this section):

Install `nvcc` in the colabfold env that you already created beforehand.
```sh
conda install -c nvidia cuda-nvcc -y
```
Now check the version with:
```sh
nvcc --version
```
Which should return:
```reStructuredText
Cuda compilation tools, release 12.0, V12.0.140
Build cuda_12.0.r12.0/compiler.32267302_0
```
3. Make sure your GNU compiler version is **4.9 or later** because `GLIBCXX_3.4.20` is required:
```sh
gcc --version
```
which on the CRG cluster returns:
```text
gcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-4)
```
If the version is `4.8.5` or older (e.g. CentOS 7) which is what the CRG cluster has install a new one with this:
```sh
conda install -c conda-forge gcc -y
```
then check again:
```sh
gcc --version
```
and you'll see that now the requirment is satisfied:
```reStructuredText
gcc (conda-forge gcc 12.2.0-19) 12.2.0
```

## Install `python` packages 
Start with:

```sh
conda install -c conda-forge python=3.8 cudnn==8.2.1.32 cudatoolkit==11.1.1 openmm==7.5.1 pdbfixer -y
```
Install alignment tools:

```sh
conda install -c conda-forge -c bioconda kalign2=2.04 hhsuite=3.3.0 mmseqs2=14.7e284 -y
```

Install ColabFold using the `pip`:

```shell
python3.8 -m pip install -q --no-warn-conflicts "colabfold[alphafold-minus-jax] @ git+https://github.com/sokrypton/ColabFold"
```

Install Jax wheels that are only available on linux.

```shell
python3.8 -m pip install https://storage.googleapis.com/jax-releases/cuda11/jaxlib-0.3.25+cuda11.cudnn82-cp38-cp38-manylinux2014_x86_64.whl
```

You should be able to read something like this:

```text
Successfully installed jaxlib-0.3.25+cuda11.cudnn82
```

Install `jax` (it was probably installed in the previous step, but better run it anyway)

```python
python3.8 -m pip install jax==0.3.25 biopython==1.79
```

You should see something like this:

```text
Successfully installed jax-0.3.25
```

If you have doubts on the version you installed you can check the installations with:

```shell
conda list <package_name>
cudatoolkit               11.1.1
cudnn                     8.2.1.32
jaxlib                    0.3.25+cuda11.cudnn82 
```

### Manual changes to the installed software

Change directory for another change:

```sh
cd ~/software/miniconda/envs/colabfold/lib/python3.8/site-packages/colabfold
```
#### `matplotlib`

Check how the python module `matplotlib` is imported:

```shell
grep -A2 -B2 "from matplotlib import pyplot as plt" plot.py 
```

```python
import numpy as np
from matplotlib import pyplot as plt
```

Make a change in how `matplotlib` is imported: use 'Agg' for non-GUI backend

```sh
sed -i -e "s#from matplotlib import pyplot as plt#import matplotlib\nmatplotlib.use('Agg')\nimport matplotlib.pyplot as plt#g" plot.py
```
Now you can see the change again with teh same `grep` command:

```shell
grep -A2 -B2 "matplotlib" plot.py 
```

```python
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
```

#### Default location of params

Check details in the `download.py` script about where the Alphafold2 params are downloaded.

```shell
grep -A1 -B3 "appdirs.user_cache_dir(__package__ or" download.py
```

```python
# The data dir location logic switches between a version with and one without "params" because alphafold
# always internally joins "params". (We should probably patch alphafold)
default_data_dir = Path(appdirs.user_cache_dir(__package__ or "colabfold"))
```

Create a variable `COLABFOLDDIR` with your default `path/to/folder`. In my case it looks like this:

```shell
COLABFOLDDIR="/users/<group>/<user>/software/colabfold"
```

Where your `<group>` is your CRG group name and `<user>` is your login username.

Modify the default params directory with:

```shell
sed -i -e "s#appdirs.user_cache_dir(__package__ or \"colabfold\")#\"${COLABFOLDDIR}/colabfold\"#g" download.py
```

Check the change with:

```shell
grep -A1 -B3 "default_data_dir = Path(" download.py
```

```python
# The data dir location logic switches between a version with and one without "params" because alphafold
# always internally joins "params". (We should probably patch alphafold)
default_data_dir = Path("/users/<group>/<user>/software/colabfold/colabfold")
```

#### Remove cache directory

```shell
rm -rf __pycache__
```

***Done!***

Go back to the software directory:

```sh
cd ~/software/colabfold/
```
Now the script should be ready to be run (if the `colabfold` `conda` environment is still active) with:
```sh
colabfold_batch --help
```
Which shows the usage.

### Download Alphafold2 params

Simply run:

```shell
python3.8 -m colabfold.download
```

which shows the progress bar

```shell
Downloading alphafold2 weights to /users/mirimia/narecco/software/colabfold/colabfold
```

the whole `params` folder is 6.3Gb as shown with ` du -h colabfold/params`.

You'll find 2 empty files informing you that the params have been successfully downloaded

```shell
ls colabfold/params/*_finished.txt
```

If you want you can remove them.

## Test installation

If everything went well you should be able to run colabfold. I made a small script that test some installations and job submission to the `gpu` queue. 

```sh
cd ~/software/colabfold
conda activate colabfold
qsub ./submission_test.sh 
```

and then check the log with:

```sh
cat test_log_out.txt
```

This test script will try to load the libraries `tensorflow`, `jax`, and `jaxlib` and will print their version.

# Run a monomer prediction

Specify the the SGE job options, input, output, and prediction parameter in the script called `CRG_conda_run_colabfold.sh`. By default I set these `colabfold_batch` parameters:

```sh
colabfold_batch --amber --templates --num-recycle 20 --recycle-early-stop-tolerance 0.5 \
								--use-gpu-relax --num-models 5 --model-order 1,2,3,4,5 \
								--random-seed 16 --model-type auto <INPUT> <OUTPUT>
```
If you need an example sequence as input try `example/short_seq.fasta`.

You can submit jobs always making sure the `conda colabfold` environment is activated and that the script as execution rights (i.e. `chmod +x CRG_conda_run_colabfold.sh`) with:

```sh
qsub ./CRG_conda_run_colabfold.sh
```
This can be used to launch a job on the `gpu` or `gpu_long`queues.
# Run a multimer prediction

If you want to try a multimer prediction, the file `example/Nucleosome.fasta` contains two copies of the 4 histone proteins sequences formatted like this:

```fasta
>Nucleosome_H3.1_H4_H2A-2a_H2B-1b_Human
MARTK --- H3  --- RIRGERA:
MSGRG --- H4  --- TLYGFGG:
MSGRG --- H2A --- HHKAKGK:
MPEPS --- H2B --- VTKYTSSK:
MARTK --- H3  --- RIRGERA:
MSGRG --- H4  --- TLYGFGG:
MSGRG --- H2A --- HHKAKGK:
MPEPS --- H2B --- VTKYTSSK
```
where the colon `:` is used to concatenate two or more sequences. For this kind of multimer input the command to run is the same as before as `colabfold_batch` understands the input is a multimer and use the appropriate `model-type`. 

Submit the prediction as before (after setting the input and output) with:

```sh
qsub ./CRG_conda_run_colabfold.sh
```

