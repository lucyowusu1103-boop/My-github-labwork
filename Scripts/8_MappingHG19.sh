#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=Map_HG19

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

#specify variables
USER="Lucy"
SAMPLE="CAL03"
#change CAL## to your assigned sample

#specify your paths
#specify paths
BASE_PATH="/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}"


#Make new directories for mapping and qualimap outputs
#mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/8_MappingHG19/{mapped,qualimap}

#specify paths
PATH_TRIMMED="${BASE_PATH}/Data/2_AdapterRemoval/FINISHED"
PATH_MAP="${BASE_PATH}/Data/8_MappingHG19/mapped"
PATH_QUALI="${BASE_PATH}/Data/8_MappingHG19/qualimap"
PATH_REF=/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/hg19

#move to the right folder
cd $PATH_TRIMMED

#Step 1: map sequences and filter using samtools

echo -e "MAKE MAPPING FILE"
echo -e "Sample \t Mapped Reads \t  % Mapped \t Q30 Mapped Reads \t Removed Duplicates \t Duplicate Rate (Duplicates per Q30 Mapped reads) \t \
#Mapped Unique Reads \t % endogenous (Mapped Unique/Total Reads) \t Mapped Reads average length \t \
#Cluster Factor (Total mapped reads / Unique reads)" > $PATH_MAP/MappingFilteringStats_${SAMPLE}_hg19.txt

echo -e "BEGIN MAPPING"

for j in *.gz
do   
    NAME=${j%.gz}  #Change ".fastq.truncated.gz" to correct file suffix if you had to run other trimming programs
    echo "Running..."${NAME}""

    echo "Aligning ${NAME}.hg19"
    bwa aln -t 16 -l 1000 -n 0.01 -o 2 $PATH_REF/hg19.fa $PATH_TRIMMED/${j} > $PATH_MAP/${NAME}.hg19.aln.sai &&
    bwa samse $PATH_REF/hg19.fa $PATH_MAP/${NAME}.hg19.aln.sai ${j} > $PATH_MAP/${NAME}.hg19.aln.sam &&

    echo "SAM to BAM conversion to begin filtering"
    samtools view -bSh -@ 4 $PATH_MAP/${NAME}.hg19.aln.sam > $PATH_MAP/${NAME}.hg19.aln.bam &&
  
    echo "Filtering out mapped reads (F4 flag)"
    samtools view -bh -F 4 -@ 4 $PATH_MAP/${NAME}.hg19.aln.bam > $PATH_MAP/${NAME}.hg19.aln.mapped.bam

    echo "Filtering out unmapped reads (f4 flag)"
    samtools view -bh -f 4 -@ 4 $PATH_MAP/${NAME}.hg19.aln.bam > $PATH_MAP/${NAME}.hg19.aln.unmapped.bam

    echo "Filtering by Q30 quality"
    samtools view -bh -q 30 $PATH_MAP/${NAME}.hg19.aln.mapped.bam > $PATH_MAP/${NAME}.hg19.aln.mapped.q30.bam &&
    
    echo "Sorting alignment by leftmost coordinate"
    samtools sort -T $PATH_MAP/${NAME}.hg19.aln.mapped.q30.sort -o $PATH_MAP/${NAME}.hg19.aln.mapped.q30.sort.bam $PATH_MAP/${NAME}.hg19.aln.mapped.q30.bam
        
    echo "Removing duplicates"
    samtools rmdup -s $PATH_MAP/${NAME}.hg19.aln.mapped.q30.sort.bam $PATH_MAP/${NAME}.hg19.aln.mapped.q30.sort.rmdup.bam &&
    
    echo "Removing reads with multiple mappings"
    samtools view -bh -F 0x900 $PATH_MAP/${NAME}.hg19.aln.mapped.q30.sort.rmdup.bam > $PATH_MAP/${NAME}.hg19.aln.mapped.q30.sort.rmdup.uniq.bam
    
    echo "Printing statistics per sample into Statsfile"
    mapped=`samtools view -c $PATH_MAP/${NAME}.hg19.aln.mapped.bam`
    q30=`samtools view -c $PATH_MAP/${NAME}.hg19.aln.mapped.q30.bam`
    rmdup=`samtools view -c $PATH_MAP/${NAME}.hg19.aln.mapped.q30.sort.rmdup.bam`
    uniq=`samtools view -c $PATH_MAP/${NAME}.hg19.aln.mapped.q30.sort.rmdup.uniq.bam`
    length=`samtools view $PATH_MAP/${NAME}.hg19.aln.mapped.q30.sort.rmdup.uniq.bam | awk '{SUM+=length($10);DIV++}END{print SUM/DIV}'`
    echo -e "${NAME} \t $mapped \t `echo "calculate % filtered and mapped here"` \t $q30 \t $rmdup \t `echo "scale=4;($q30-$rmdup)/$rmdup" | \
    bc` \t $uniq \t `echo "calculate endogenous or unique reads here"` \t $length \t `echo "scale=4;$uniq/$q30" | bc` " >> $PATH_MAP/MappingFilteringStats_${SAMPLE}_hg19.txt

done


