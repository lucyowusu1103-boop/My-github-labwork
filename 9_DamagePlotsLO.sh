#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=DamagePlots

# Number of compute nodes
#SBATCH --nodes=1

# Number of cores, in this case one
#SBATCH --ntasks-per-node=24

# Walltime (job duration)
#SBATCH --time=21-05:00:00

# Email notifications
#SBATCH --mail-type=BEGIN,END,FAIL

source ~/.bashrc


#Step 1: Set up folders and variables:
USER="Lucy" #replace Lucy with your actual foldername
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/9_DamagePlots/{MapDamage2,PMDTools}

BASE_PATH="/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}"

PATH_MAP="${BASE_PATH}/Data/8_MappingHG19/mapped"
PATH_DMG="${BASE_PATH}/Data/9_DamagePlots"
PATH_REF=/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/hg19

##Step 2: Copy the merged unique mapped reads into your DamagePlots folder 
cd ${PATH_DMG}

cp ${PATH_MAP}/*merged.sort.rmdup.uniq.bam .


#Step 3: Run MapDamage:
conda activate mapdamage

cd ${PATH_DMG}/MapDamage2

for k in ../*uniq.bam
do
   mapDamage -i ${k} -r ${PATH_REF}/hg19.fa --no-stats -d .
done

conda deactivate 

#Step 4: Run PMDTools
cd ${PATH_DMG}/PMDTools

conda activate Sequencing

for a in ../*uniq.bam
do
    ID=$(basename $a)
    NAME=$(echo $ID |cut -d "." -f1)
    
    echo "1. Add MD Tags and output to bam"
    samtools calmd -u ../"${NAME}".hg19.aln.merged.sort.rmdup.uniq.bam ${PATH_REF}/hg19.fa > "${NAME}".uniq.md.bam
      
    echo "2. Produce CpG Damage rate"
    samtools view -h "${NAME}".uniq.md.bam | python2 /dartfs/rc/lab/F/FleskesR/ReferenceSeqs/software/PMDtools/PMDtools-master/pmdtools.0.60.py --first --requirebaseq 30 --CpG -n 100000 > "${NAME}".CpG.scores.txt

    echo "3. Produce Graphs"
    samtools view -h "${NAME}".uniq.md.bam | python2 /dartfs/rc/lab/F/FleskesR/ReferenceSeqs/software/PMDtools/PMDtools-master/pmdtools.0.60.py --platypus --requirebaseq 30 -n 100000 > PMD_temp.txt
    R CMD BATCH /dartfs/rc/lab/F/FleskesR/ReferenceSeqs/software/PMDtools/PMDtools-master/plotPMD.v2.R

    echo "Cleanup and organize all files"
    cp PMD_plot.frag.pdf PMD.plot."${NAME}".pdf
    rm PMD_plot.frag.pdf
    rm plotPMD.v2.Rout
    rm PMD_temp.txt

done