#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=AdapterRemoval

# Number of compute nodes
#SBATCH --nodes=1

# Number of cores, in this case one
#SBATCH --ntasks-per-node=16

# Walltime (job duration)
#SBATCH --time=1-00:00:00

# Email notifications
#SBATCH --mail-type=BEGIN,END,FAIL

source ~/.bashrc

conda activate Sequencing

#specify variables
yourname="Lucy"
SAMPLE="CAL03"
#change CAL## to your assigned sample

#specify paths
BASE_PATH="/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy"

#make new directory for Adapter Removal output
mkdir -p ${BASE_PATH}/Data/2_AdapterRemoval

#specify paths
PATH_READS="${BASE_PATH}/Data/0_RAWDATA/CAL03"
PATH_OUTPUT="${BASE_PATH}/Data/2_AdapterRemoval"

#move to the right folder
cd ${PATH_READS}

for i in *fastq.gz
do
    echo "Running Adapter Removal on sample "${i}"..."
    AdapterRemoval --file1 ${i} --basename ${i%.*} --threads 32 --trimns --trimqualities --minlength 30 --gzip
    mv *settings* ${PATH_OUTPUT}
    mv *discarded* ${PATH_OUTPUT}
    mv *truncated* ${PATH_OUTPUT}
done
