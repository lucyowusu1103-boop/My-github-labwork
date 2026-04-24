#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=MAP_MTDNA

# Number of compute nodes
#SBATCH --nodes=1

# Number of cores, in this case one
#SBATCH --ntasks-per-node=4

# Walltime (job duration)
#SBATCH --time=2-01:00:00

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

#make new directory for bwa mapping and samtools filtering output plus one for qualimap (Note: un-comment this if you have not yet made these directories)
# mkdir -p ${BASE_PATH}/Data/5_MappingMTDNA{mapped,qualimap}

#specify paths (Note: you may need to change PATH_TRIMMED if you needed to run additional trimming to remove all adapters)
PATH_TRIMMED="${BASE_PATH}/Data/2_AdapterRemoval/FINISHED"
PATH_MAP="${BASE_PATH}/Data/5_MappingMTDNA/mapped"
PATH_QUALI="${BASE_PATH}/Data/5_MappingMTDNA/qualimap"
PATH_REF=/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/MtDNA

#move to the right folder
cd $PATH_TRIMMED

#Step 1: map sequences and filter using samtools

echo -e "MAKE MAPPING FILE"
echo -e "Sample \t Mapped Reads \t  % Mapped \t Q30 Mapped Reads \t Removed Duplicates \t Duplicate Rate (Duplicates per Q30 Mapped reads) \t \
#Mapped Unique Reads \t % endogenous (Mapped Unique/Total Reads) \t Mapped Reads average length \t \
#Cluster Factor (Total mapped reads / Unique reads)" > $PATH_MAP/MappingFilteringStats_${SAMPLE}_mtDNA.txt

echo -e "BEGIN MAPPING"

for j in *truncated.gz *.trimmed.fastq.gz *.trimmed2.fastq.gz *.trimmed3.fastq.gz  #Change file suffixes if you had to run other trimming programs
do   
    [ -f "$j" ] || continue  #skip if no files with this suffix
    NAME=${j%%.*}  #Change ".fastq.truncated.gz" to correct file suffix if you had to run other trimming programs
    echo "Running..."${NAME}""

    echo "Aligning ${NAME}.mtDNA"
    bwa mem -t 4 $PATH_REF/rCRS.fasta $PATH_TRIMMED/${j} > $PATH_MAP/${NAME}.mtDNA.mem.sam
    
    echo "SAM to BAM conversion to begin filtering"
    samtools view -bSh -@ 4 $PATH_MAP/${NAME}.mtDNA.mem.sam > $PATH_MAP/${NAME}.mtDNA.mem.bam &&
  
    echo "Filtering out mapped reads (F4 flag)"
    samtools view -bh -F 4 -@ 4 $PATH_MAP/${NAME}.mtDNA.mem.bam > $PATH_MAP/${NAME}.mtDNA.mem.mapped.bam

    echo "Filtering by Q30 quality"
    samtools view -bh -q 30 $PATH_MAP/${NAME}.mtDNA.mem.mapped.bam > $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.bam &&
    
    echo "Sorting alignment by leftmost coordinate"
    samtools sort -T $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.sort -o $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.sort.bam $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.bam
        
    echo "Removing duplicates"
    samtools rmdup -s $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.sort.bam $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.sort.rmdup.bam &&
    
    echo "Removing reads with multiple mappings"
    samtools view -bh -F 0x900 $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.sort.rmdup.bam > $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.sort.rmdup.uniq.bam
    
    echo "Printing statistics per sample into Statsfile"
    mapped=`samtools view -c $PATH_MAP/${NAME}.mtDNA.mem.mapped.bam`
    q30=`samtools view -c $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.bam`
    rmdup=`samtools view -c $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.sort.rmdup.bam`
    uniq=`samtools view -c $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.sort.rmdup.uniq.bam`
    length=`samtools view $PATH_MAP/${NAME}.mtDNA.mem.mapped.q30.sort.rmdup.uniq.bam | awk '{SUM+=length($10);DIV++}END{print SUM/DIV}'`
    echo -e "${NAME} \t $mapped \t `echo "calculate % filtered and mapped here"` \t $q30 \t $rmdup \t `echo "scale=4;($q30-$rmdup)/$rmdup" | \
    bc` \t $uniq \t `echo "calculate endogenous or unique reads here"` \t $length \t `echo "scale=4;$uniq/$q30" | bc` " >> $PATH_MAP/MappingFilteringStats_${SAMPLE}_mtDNA.txt

done


