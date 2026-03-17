#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=Lucy_Fast

# Number of compute nodes
#SBATCH --nodes=1

# Number of cores, in this case one
#SBATCH --ntasks-per-node=32

# Walltime (job duration)
#SBATCH --time=3-00:00:00

# Email notifications
#SBATCH --mail-type=BEGIN,END,FAIL

source ~/.bashrc
#activate conda env
conda activate fastqc 
#specify paths
BASE_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy
PATH_Reads="${BASE_PATH}/Data/0_RAWDATA/CAL03"
PATH_FASTQC="${BASE_PATH}/1_FASTQC/CAL03/FASTQC"
PATH_Scripts="${BASE_PATH}/Scripts"

# make fastqc path
mkdir -p $PATH_FASTQC

# go to raw data folder
cd ${PATH_Reads}

# loop through raw files
for j in *fastq.gz
do
    # Extract the filename without the extension
    filename_without_extension=$(basename "$j" | cut -d. -f1)
    # print out file being analyzed
    echo "FASTQC of ${j%_*}" 
    # Run fastqc
    fastqc -t 32 -q ${j} -o ${PATH_FASTQC}
done


#generate summary file 
conda activate Sequencing
cd $PATH_Scripts
python 1a_fastqc_summary.py "${PATH_FASTQC}"
