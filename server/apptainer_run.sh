#!/bin/bash -l

#SBATCH -J "nnIntSrv"
#SBATCH -C memfs
## exclusive recommended with memfs, but increases the queuing time
##SBATCH --exclusive 
## needed to for memfs and container storage 
#SBATCH --mem-per-cpu=32GB
#SBATCH --time=8:00:00
#SBATCH -A plgfmri4-gpu-a100
#SBATCH --gres=gpu:1
#SBATCH --partition=plgrid-gpu-a100
#SBATCH --output="logs/nninteractive_server.out"


IMAGE_DIR=$SCRATCH/nninteractive_server
IMAGE_FILEPATH="$IMAGE_DIR/image.sif"
TMP_DIR=$MEMFS
# if cuda not found error `nvidia-smi` should return a device (athena NVIDIA A100-SXM4-40GB)

# disable cache to not exceed $HOME storage limit
export APPTAINER_DISABLE_CACHE=true APPTAINER_TMPDIR=$TMP_DIR/
apptainer pull --disable-cache $IMAGE_FILEPATH docker://docker.io/coendevente/nninteractive-slicer-server:latest  

apptainer run --nv $IMAGE_FILEPATH /opt/conda/envs/nnInteractive/bin/python3.12 /opt/server/main.py # --nv equivalent to docker --gpus all