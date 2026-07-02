#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=Merge_HG19

# Number of compute nodes
#SBATCH --nodes=1

# Number of cores, in this case one
#SBATCH --ntasks-per-node=16

# Walltime (job duration)
#SBATCH --time=21-01:00:00

# Email notifications
#SBATCH --mail-type=BEGIN,END,FAIL

source ~/.bashrc

conda activate Sequencing

##Step 1: set up folders and variables
USER="Lucy" #replace Lucy with your actual foldername
SAMPLE="CAL03"
#change CAL## to your assigned sample

#Make variable for mapped pathss
PATH_MAP=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/8_MappingHG19/mapped

cd $PATH_MAP

##Step 2: Merge files using samtools
#You will need to change the individual file names after the first line to match your file names. (Leave the first line as it is.)
#Use ls *.uniq.bam to get list of your file names.
#You will also need to add a backslash \ at the end of each line except for the last, 
#and each line after the first needs to be indented by one tab.

samtools merge -@ 16 ${SAMPLE}.hg19.aln.merged.bam \
    CAL03_FGC2096_s_1.R1.trimmed3.fastq.hg19.aln.mapped.q30.sort.rmdup.uniq.bam \
    CAL03_FGC2096_s_1.R2.trimmed2.fastq.hg19.aln.mapped.q30.sort.rmdup.uniq.bam \
    CAL03_FGC2098_s_1_CGGCTATG-CCTATCCT.fastq.truncated.hg19.aln.mapped.q30.sort.rmdup.uniq.bam \
    CAL03_FGC2098_s_2_CGGCTATG-CCTATCCT.fastq.truncated.hg19.aln.mapped.q30.sort.rmdup.uniq.bam \
    CAL03_FGC2098_s_3_CGGCTATG-CCTATCCT.fastq.truncated.hg19.aln.mapped.q30.sort.rmdup.uniq.bam \
    CAL03_FGC2098_s_4_CGGCTATG-CCTATCCT.fastq.truncated.hg19.aln.mapped.q30.sort.rmdup.uniq.bam \
    CAL03_FGC2099_s_1_CGGCTATG-CCTATCCT.fastq.truncated.hg19.aln.mapped.q30.sort.rmdup.uniq.bam \
    CAL03_FGC2099_s_2_CGGCTATG-CCTATCCT.trimmed.fastq.hg19.aln.mapped.q30.sort.rmdup.uniq.bam \

##Step 3: Now we remove duplicates and reads that have multiple mappings. First, we sort the reads by leftmost coordinate, then remove duplicates.
#Sorting alignment by leftmost coordinate
samtools sort -T ${SAMPLE}.hg19.aln.merged.sort -o ${SAMPLE}.hg19.aln.merged.sort.bam ${SAMPLE}.hg19.aln.merged.bam
#Removing duplicates
samtools rmdup -s ${SAMPLE}.hg19.aln.merged.sort.bam ${SAMPLE}.hg19.aln.merged.sort.rmdup.bam
#Removing reads with multiple mappings
samtools view -bh -F 0x900 ${SAMPLE}.hg19.aln.merged.sort.rmdup.bam > ${SAMPLE}.hg19.aln.merged.sort.rmdup.uniq.bam

#Finally, we create a new MergingStats file to keep this data:
echo -e "MAKE MERGING FILE"
echo -e "Sample \t Total Merged Reads \t Unique Merged Reads" > $PATH_MAP/MergingFilteringStats_${SAMPLE}_hg19.txt

merged=`samtools view -c $PATH_MAP/${SAMPLE}.hg19.aln.merged.bam`
uniq=`samtools view -c $PATH_MAP/${SAMPLE}.hg19.aln.merged.sort.rmdup.uniq.bam`

echo -e "${SAMPLE} \t $merged \t $uniq " >> $PATH_MAP/MergingFilteringStats_${SAMPLE}_hg19.txt

