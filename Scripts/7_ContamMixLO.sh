#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=contammix

# Number of compute nodes
#SBATCH --nodes=1

# Number of cores, in this case one
#SBATCH --ntasks-per-node=16

# Walltime (job duration)
#SBATCH --time=1-01:00:00

# Email notifications
#SBATCH --mail-type=BEGIN,END,FAIL


#######################
conda activate ContaMixEnv

REF_PATH="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/MtDNA"

for k in *.uniq.bam
do
    echo "STEP ONE: Creating MIA consensus for ${k%.*}"
    bedtools bamtofastq -i ${k} -fq ${k%.*}.fastq
    mia -r $REF_PATH/rCRS.fasta -f ${k%.*}.fastq -c -C -U -i -F -k 14 -m ${k%.*}.fastq.maln
    ma -M ${k%.*}.fastq.maln.? -f 5 -I ${k} > ${k%.*}.mia.consensus.fasta

    echo "STEP TWO: Aligning consensus with contaminating seqs for ${k%.*}"
    cat ${k%.*}.mia.consensus.fasta $REF_PATH/mt311.fa > ${k%.*}.mt311.fasta
    mafft --auto ${k%.*}.mt311.fasta > ${k%.*}.mt311.MAFFT.fasta

    echo "STEP THREE: Remapping the Consensus for Sample ${k%.*}"
    bwa index ${k%.*}.mia.consensus.fasta
    bwa aln -l 1000 -n 0.01 ${k%.*}.mia.consensus.fasta ${k%.*}.fastq > ${k%.*}.remapped.sai
    bwa samse ${k%.*}.mia.consensus.fasta ${k%.*}.remapped.sai ${k%.*}.fastq  > ${k%.*}.remapped.sam
    samtools faidx ${k%.*}.mia.consensus.fasta
    samtools view -bSh ${k%.*}.remapped.sam > ${k%.*}.remapped.bam
done

#PART TWO: RUNNING CONTAMMIX SCRIPT

echo -e "Reads Used \t MAP authentic \t 95% quantiles \t Pr reads matched other genome better than consensus (crude cont upper bound) \t error rate" > tempcmix
echo -e "Sample" > samplelist
for i in *.remapped.bam ; do f=`echo $i | cut -f1 -d "."` ; \
  echo -e "$f" >> samplelist
done

for k in *.uniq.bam
do
    echo "Running ContamMix for ${k%.*}"
    contammix --samFn ${k%.*}.remapped.bam --malnFn ${k%.*}.mt311.MAFFT.fasta --consId ${k} --figure ${k%.*}.contamMix_fig | tee ${k%.*}.contamMixout.txt

    readsused=`grep "consist of" ${k%.*}.contamMixout.txt | awk '{print $3}'`
    map=`grep "MAP authentic" ${k%.*}.contamMixout.txt | cut -d":" -f2`
    quantiles=`awk 'NR==9 {print $0}' ${k%.*}.contamMixout.txt`
    pr=`awk 'NR==4 {print $0}' ${k%.*}.contamMixout.txt | cut -d"(" -f2 | cut -d")" -f1`
    err=`grep "error rate" ${k%.*}.contamMixout.txt | awk '{print $9}' | sed 's/).//g'`
    echo -e "$readsused \t $map \t $quantiles \t $pr \t $err" >> tempcmix
done


ls *.remapped.bam  > bamlist
cat bamlist | while read line
    do
    NAME=`echo $line | cut -d"." -f1`
    mkdir ContamMix.${NAME}
    mv $NAME* ./ContamMix.${NAME}
done

paste samplelist tempcmix > ContamMixStats.txt
rm bamlist samplelist tempcmix

#######################
