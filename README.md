What is this?
 - My installation notes and script for running ColabFold on the [CRG](https://www.crg.eu/) GPU clusters.

What is ColabFold?
 - Read the [paper](https://www.nature.com/articles/s41592-022-01488-1) and check the [GitHub repository](https://github.com/sokrypton/ColabFold).

I don't want to deal with installation and scripts, where can I find pre-computed structures?
- If your canonical protein has a [UniProt](https://www.uniprot.org/) ID just search it in the [EBI Alphafold database](https://alphafold.ebi.ac.uk/).

My protein sequence is not in UniProt how can I quickly run ColabFold?
- Use one of the offical [google colab notebooks](https://github.com/sokrypton/ColabFold#making-protein-folding-accessible-to-all-via-google-colab).

What is this repo actually containing?
- Basically the [LocalColabFold](https://github.com/YoshitakaMo/localcolabfold) installation steps and a custom script to submit to the CRG graphics cards.

What are the advantages of using this *local* ColabFold?

- You don't have the 12 hours time limitations as for Google Colabs Notebooks. (CRG max time is 168 hours on `gpu_long`). Also, access to the GPU is more reliable as you'll use your local graphics card.
- Differently from AlphaFold2 you don't have to download the massive databases as everything is done on the ColabFold servers (that also cache quries!). 
- Structure prediction and `amber` relaxion are done on the GPUs, i.e. faster prediction.
- More control on advanced parameters.

# Installation

These following steps are adapted from [this script of localColabFold](https://github.com/YoshitakaMo/localcolabfold/blob/main/install_colabbatch_linux.sh) repository. The installation fits my current folder structure and already existing conda.

## Make a `conda` environment
If you don't have `miniconda` please first [install it](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html). If you have `conda` already installed please pay attention where it is installed with `which conda`. In my case returns `~/software/miniconda/condabin/conda`, however most people usually have it in `~/miniconda3/condabin/conda`. This is important cause later there are some editing to the colabfold python scripts installed by `conda`. Create a `software/colabfold` directory where some important files will be stored (e.g. Alphafold2 parameters, `matplotlib`, ~~aminoacid stero chemical properties~~).

```sh
mkdir -p ~/software/colabfold ; cd ~/software/colabfold
```
Now create a new `conda` environment with:
```sh
conda create --name colabfold python==3.7 -y
conda activate colabfold
```
Start by first updating `conda` with:
```sh
conda update -n base conda -y
```
## Linux Requirment

1. For CRG users you need to ask IT access to the GPU cluster.

To check if you can access the CRG gpu queue try the following from the ant-login node:
```sh
qrsh -q gpu
```
and wait until the login access request is processed. However if the cards are in use you won't be able to access them.

2. Make sure your Cuda compiler driver is **11.1 or later** (If you don't plan to use a GPU, you can skip this section):

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
Cuda compilation tools, release 11.7, V11.7.64
Build cuda_11.7.r11.7/compiler.31294372_0
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
conda install -c conda-forge gcc
```
then check again:
```sh
gcc --version
```
and you'll see that now the requirment is satisfied:
```reStructuredText
gcc (conda-forge gcc 12.1.0-16) 12.1.0
```

## Install `python` packages 
Start with:
```sh
conda install -c conda-forge python=3.7 cudnn==8.2.1.32 cudatoolkit==11.1.1 openmm==7.5.1 pdbfixer -y
```
Install alignment tools:

```sh
conda install -c conda-forge -c bioconda kalign3=3.2.2 hhsuite=3.3.0 -y
```

Install ColabFold using the `pip`:

```python
pip install "colabfold[alphafold] @ git+https://github.com/sokrypton/ColabFold"
```

Install Jax wheels that are only available on linux.

```python
pip install https://storage.googleapis.com/jax-releases/cuda11/jaxlib-0.3.10+cuda11.cudnn82-cp37-none-manylinux2014_x86_64.whl
```

You should be able to read something like this:

```reStructuredText
Successfully installed jaxlib-0.1.72+cuda111
```

Install `jax`

```python
pip install jax==0.3.13
```

You should see something like this:

```reStructuredText
Successfully installed jax-0.2.25
```

If you have doubts on the version you installed you can check the installations with:

```sh
conda list <package_name>
cudatoolkit               11.1.1 
jaxlib                    0.1.72+cuda111  
cudnn                     8.2.1.32
```

Change directory for another change:
```sh
cd ~/software/miniconda/envs/colabfold/lib/python3.7/site-packages/colabfold
```
Use 'Agg' for non-GUI backend
```sh
sed -i -e "s#from matplotlib import pyplot as plt#import matplotlib\nmatplotlib.use('Agg')\nimport matplotlib.pyplot as plt#g" plot.py
```
Go back to the software directory:
```sh
cd ~/software/colabfold/
```
Now the script should be ready to be run (if the `colabfold` `conda` environment is still active) with:
```sh
colabfold_batch --help
```
Which shows the usage.

Old fixes not really required anymore.

~~Get the `stereo_chemical_props.txt` file.~~

```sh
wget https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt --no-check-certificate
```

~~Get the `openmm` patch~~

```sh
wget -qnc https://raw.githubusercontent.com/deepmind/alphafold/main/docker/openmm.patch --no-check-certificate
```

~~Apply the patch. (Modify your miniconda path to accordingly)~~

```sh
(cd ~/software/miniconda/envs/colabfold/lib/python3.7/site-packages; patch -s -p0 <  ~/software/colabfold/openmm.patch)
```

~~Remove patch `rm openmm.patch`.~~
~~Hack to share the parameter files in a workstation. Move to where the script `props_path batch.py` was installed with:~~

```sh
cd ~/software/miniconda/envs/colabfold/lib/python3.7/site-packages/colabfold/
```

~~See what we are going to change with `grep -B2 -A1  props_path batch.py `. Change path with:~~

```sh
sed -i -e "s#props_path = \"stereo_chemical_props.txt\"#props_path = \"/users/mirimia/narecco/software/colabfold/stereo_chemical_props.txt\"#" batch.py
```

~~Run again `grep -B2 -A1  props_path batch.py ` to check that the absolute path to the stereo is correct. This "stereo_chemical_props.txt" path might not be needed anymore in future versions I believe.~~

# Custom script for CRG cluster

I made a simple script that packages all the required variables for running colabfold on the CRG gpu cluster queues using the conda enviroment created above. This script is called `CRG_conda_run_colabfold.sh` and it takes easily input and predefined output and running parameters for jobs. 
The wrapper will run `colabfold_batch` as:

```sh
colabfold_batch --amber --templates --num-recycle 5 \
				--use-gpu-relax --num-models 5 --model-order 1,2,3,4,5 \
				--random-seed 16 --model-type auto $INPUT $OUTPUT_DIR
```
You can test this wrapper always making sure the `conda colabfold` environment is activated and that the script as execution rights (i.e. `chmod +x CRG_conda_run_colabfold.sh`) with:
```sh
./CRG_conda_run_colabfold.sh -i example/short_seq.fasta -q 'gpu'
```
This will launch a job on the `gpu` queue and print some info:
```
Input name: short_seq
Output dir: ~/projects/12_Predicted_Structures/data/pdb/CF/short_seq	
Use -o <PATH> to specify where to store the results.

	CRG Queue: gpu
	Max wallclock time allowed per prediction: 01:59 (hh:mm)
	Num Processes: 6
	CPU Ram per process: 64Gb
	Num GPU(s): 1 (NVIDIA RTX 2080 Ti)
	Ouput: /users/mirimia/narecco/projects/12_Predicted_Structures/data/pdb/CF/short_seq
	Log file: /users/mirimia/narecco/qsub_out/2022_08_02/CF/short_seq_std{out|err}.log
```
Please note that the first time `colabfold_batch` is run, it automatically downloads the AlphaFold model parameters as you can see with:
```sh
ls ~/software/colabfold/colabfold/params
params_model_1.npz params_model_2.npz params_model_3.npz params_model_4.npz params_model_5.npz 
params_model_1_ptm.npz params_model_2_ptm.npz params_model_3_ptm.npz params_model_4_ptm.npz params_model_5_ptm.npz
```
This is also shown in the log file:
```sh
Downloading alphafold2 weights to /users/mirimia/narecco/software/colabfold/colabfold:   0% 0/3722752000 [00:00<?, ?it/s]
# ....
Downloading alphafold2 weights to /users/mirimia/narecco/software/colabfold/colabfold: 100% 3.47G/3.47G [01:13<00:00, 50.8MB/s]
```

# Run a multimer prediction
The file `example/Nucleosome.fasta` contains 4 protein sequences formatted like this:
```fasta
>Nucleosome_H3.1_H4_H2A-2a_H2B-1b_Human
MARTKQTARKSTGGKAPRKQLATKAARKSAPATGGVKKPHRYRPGTVALREIRRYQKSTELLIRKLPFQRLVREIAQDFKTDLRFQSSAVMALQEACEAYLVGLFEDTNLCAIHAKRVTIMPKDIQLARRIRGERA:
MSGRGKGGKGLGKGGAKRHRKVLRDNIQGITKPAIRRLARRGGVKRISGLIYEETRGVLKVFLENVIRDAVTYTEHAKRKTVTAMDVVYALKRQGRTLYGFGG:
MSGRGKQGGKARAKAKSRSSRAGLQFPVGRVHRLLRKGNYAERVGAGAPVYMAAVLEYLTAEILELAGNAARDNKKTRIIPRHLQLAIRNDEELNKLLGKVTIAQGGVLPNIQAVLLPKKTESHHKAKGK:
MPEPSKSAPAPKKGSKKAITKAQKKDGKKRKRSRKESYSIYVYKVLKQVHPDTGISSKAMGIMNSFVNDIFERIAGEASRLAHYNKRSTITSREIQTAVRLLLPGELAKHAVSEGTKAVTKYTSSK
```
where the colon `:` is used to concatenate two or more sequences. For this kind of "multimer" input the command to run is the same as before:
```sh
./CRG_conda_run_colabfold.sh -i example/Nucleosome.fasta -q 'gpu' 
```

