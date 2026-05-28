#!/bin/bash -l

#In this assignment, you will work through the mtDNA contamination checks,
#to confirm the authenticity of your ancient DNA data. 
#We will use two programs (though there are others): 
#1. ContamMix
#2. Schmutzi


#######################
########PART 0########
######################
#housekeeping before we start the assignment!

#copy this script into your own USER directory. You can do this using the cp command.
#tip: do this by copying the script from the terminal using the full path, and then pasting it into your own directory using the full path.
7_ContaminationMTDNA_assignment.sh 
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/ASSIGNMENTS/WEEK7-ContaminationMTDNA/7_ContaminationMTDNA_assignment.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/7_ContaminationMTDNA_assignment.sh

#then modify the script in your own folder


######################
########PART 1########
######################

##Set up folders and variables
USER="Lucy" #replace Lucy with your actual foldername
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/7_ContamMTDNA/{ContamMix,Schmutzi}
#rm /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/7_ContamMTDNA/ContamMix/* #remove any files that may be in the ContamMix folder

#set you base path variable to your USER folder
BASE_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data

#set your reference path variable to the location of the mtDNA reference genome
REF_PATH="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/MtDNA"

#set the path to your scripts
SCRIPTS_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts

#last, set your name variable
NAME="CALO3" #change to your file name before mtDNA.mem.merged.sort.rmdup.uniq.bam



######################
########PART 2########
######################
##Run ContamMix

#PART ZERO: copy the merged bam file into the ContamMix folder
cp ${BASE_PATH}/5_MappingMTDNA/mapped/*mtDNA.mem.merged.sort.rmdup.uniq.bam ${BASE_PATH}/7_ContamMTDNA/ContamMix

#now move into the ${BASE_PATH}/7_ContamMTDNA/ContamMix folder 
#use the ls command to check that the bam file is there
cd ${BASE_PATH}/7_ContamMTDNA/ContamMix

##ContamMix requires two steps to work,
#First, we need to make a consensus sequence, mapped to the mt311.fasta
#Then we can run ContamMix

#QUESTION: What is the mt311.fa sequence? Look at the sequence file (DO NOT EDIT IT) and use the internet to answer this question.
less ${REF_PATH}/mt311.fa
#The mt311.fasta sequence contains 311 mitochondrial genomes from modern humans that are commonly found as contaminants in ancient DNA samples. 
#These sequences are used as references in ContamMix to help identify and quantify contamination in the ancient DNA data by comparing the sample's consensus sequence to these known contaminant sequences.

#ASSIGNMENT: Create a job script for running ContamMix
#You will need to make a new .sh shell script, 
#include the correct headers, 
#and paste the code between the two "#######################" below after the headers
#Save this file as 7_ContamMix.sh in your Scripts folder
#Hint 1: Make sure you're in the ${BASE_PATH}/7_ContamMTDNA/ContamMix folder when you submit the job script!
#Hint 2: See ../FleskesR/BioinfoWG/RAW_Scripts/7_ContamMix.sh to check your work.

#######################
conda activate ContaMixEnv

REF_PATH="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/MtDNA"

#PART ONE: PREPARATION

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

#use sbatch to submit your job
sbatch $SCRIPTS_PATH/7_ContamMix.sh

#check the status of your job: 
squeue --me

#If you have issues, look at the slurm-******.out file within the ContamMix folder to see what the errors say.

#QUESTION: In a few sentences, describe how contamMix works (high level; don't get lost in the mathematical details).
#HINT: You will have to go to the GitHub page to learn where to find the supporting information for the cooresponding paper.
#
#
#QUESTION: Did your sample show any contamination? What percentage of reads were authentic?
#93% of the reads were authentic, which means that 7% of the reads were contaminated. This indicates that the majority of the DNA sequences in the sample are likely to be from the ancient source, but there is a small proportion of modern contaminant DNA present as well.
#We need contamination to be less than 5% to be confident in the authenticity of our ancient DNA data, so this sample may require further scrutiny or additional contamination checks before we can be confident in the results.



######################
########PART 3########
######################
##Run Schmutzi

#ASSIGNMENT: Create a job script for running Schmutzi
#You will need to make a new .sh shell script, 
#include the correct headers, 
#and paste the code between the two "#######################" below after the headers
#Save this file as 7_Schmutzi.sh in your Scripts folder
#Hint 1: Make sure you're in the ${BASE_PATH}/7_ContamMTDNA/Schmutzi folder when you submit the job script!
#Hint 2: See ../FleskesR/BioinfoWG/RAW_Scripts/7_Schmutzi.sh to check your work.


#######################
source ~/.bashrc
module load samtools/1.9
conda activate schmutzi

# Set up PATHS and variables:
USER="Lucy" #replace Lucy with your actual foldername
BASE_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data

# Working directory containing the *uniq.bam files:
WORKDIR="${BASE_PATH}/5_MappingMTDNA/mapped"

# Reference FASTA used for calmd and schmutzi
REFERENCE="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/MtDNA/rCRS.fasta"

# Directory where all schmutzi-related outputs will be saved
OUTDIR="${BASE_PATH}/7_ContamMTDNA/Schmutzi"

# schmutzi freqs path
FREQPATH="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/software/schmutzi/schmutzi/share/schmutzi/alleleFreqMT/eurasian/freqs"

# 1) Change to the working directory containing the input BAMs
cd "${WORKDIR}" || { echo "Cannot cd to ${WORKDIR}"; exit 1; }

# 2) Loop over all *uniq.bam files
for BAM in *.mtDNA.mem.merged.sort.rmdup.uniq.bam
do
    SAMPLE_PREFIX="${BAM%.mtDNA.mem.merged.sort.rmdup.uniq.bam}"

    echo "==========================================="
    echo "Processing sample: ${SAMPLE_PREFIX}"
    echo "Input BAM: ${BAM}"
    echo "==========================================="

  
    # (A) Samtools calmd -> ensure MD tags; then index
    MD_BAM="${OUTDIR}/${SAMPLE_PREFIX}_md.bam"

    echo "[Step A] Running samtools calmd on ${BAM}..."
    samtools calmd -b "${WORKDIR}/${BAM}" "${REFERENCE}" > "${MD_BAM}"
    samtools index "${MD_BAM}"

  
    # (B) Run contDeam.pl
    #     Output prefix goes to ${OUTDIR}
    DEAM_PREFIX="${OUTDIR}/${SAMPLE_PREFIX}_deam"

    echo "[Step B] Running contDeam.pl..."
    contDeam.pl \
        --out "${DEAM_PREFIX}" \
        --lengthDeam 5 \
        --library double  \
        "${REFERENCE}" \
        "${MD_BAM}" 

    # (C) Run schmutzi.pl (two modes):
    #     i)  WITHOUT predicted contamination  (--notusepredC)
    #     ii) WITH    predicted contamination  (default)
    #     Output prefix goes to ${OUTDIR}
   

    # i) WITHOUT predicted contamination
    SCHM_PREFIX_NOCONTAM="${OUTDIR}/${SAMPLE_PREFIX}_nocontam"

    echo "[Step C.i] Running schmutzi.pl WITHOUT predicted contamination..." 
    schmutzi.pl --notusepredC --uselength --ref "${REFERENCE}" --out "${SCHM_PREFIX_NOCONTAM}"  "${DEAM_PREFIX}" "${FREQPATH}" "${MD_BAM}"

    # ii) WITH predicted contamination
    SCHM_PREFIX_CONTAM="${OUTDIR}/${SAMPLE_PREFIX}_contam"

    echo "[Step C.ii] Running schmutzi.pl WITH predicted contamination..."
    schmutzi.pl \
        --uselength \
        --ref "${REFERENCE}" \
        --out "${SCHM_PREFIX_CONTAM}" \
        "${DEAM_PREFIX}" \
        "${FREQPATH}" \
        "${MD_BAM}"

    # (D) Convert final schmutzi logs to FASTA consensus using log2fasta
    #     Writes files to ${OUTDIR} with various quality cutoffs
  
    echo "[Step D] Converting schmutzi final logs to FASTA consensus..."

    # NOCONTAM
    FINAL_NOCONTAM_LOG="${SCHM_PREFIX_NOCONTAM}_final_endo.log"
    if [[ -f "${FINAL_NOCONTAM_LOG}" ]]; then
        log2fasta -i "${FINAL_NOCONTAM_LOG}" -q 20 \
          > "${OUTDIR}/${SAMPLE_PREFIX}_nocontam_consensus_q20.fasta"
        log2fasta -i "${FINAL_NOCONTAM_LOG}" -q 30 \
          > "${OUTDIR}/${SAMPLE_PREFIX}_nocontam_consensus_q30.fasta"
    else
        echo "WARNING: No file ${FINAL_NOCONTAM_LOG} found!"
    fi

     # CONTAM
    FINAL_CONTAM_LOG="${SCHM_PREFIX_CONTAM}_final_endo.log"
    if [[ -f "${FINAL_CONTAM_LOG}" ]]; then
        log2fasta -i "${FINAL_CONTAM_LOG}" -q 20 \
          > "${OUTDIR}/${SAMPLE_PREFIX}_contam_consensus_q20.fasta"
        log2fasta -i "${FINAL_CONTAM_LOG}" -q 30 \
          > "${OUTDIR}/${SAMPLE_PREFIX}_contam_consensus_q30.fasta"
    else
        echo "WARNING: No file ${FINAL_CONTAM_LOG} found!"
    fi

    echo "Done with sample: ${SAMPLE_PREFIX}"
    echo "---------------------------------------------"
done

echo "All samples processed. Results in: ${OUTDIR}"

#######################

#use sbatch to submit your job (make sure you're in the Schmutzi folder when you submit this!)
sbatch $SCRIPTS_PATH/7_SchmutziLO.sh

#check the status of your job: 
squeue --me

#If you have issues, look at the slurm-******.out file within the Schmutzi folder to see what the errors say.

#QUESTION: Did your sample show any contamination? What percentage of reads were not contaminated?
#HINT: The results are in the files *nocontam_final.cont.est
# The results show 0.08 	0.07	0.09 
#This means that the estimated contamination level is around 8%, with a 95% confidence interval ranging from 7% to 9%. Therefore, approximately 92% of the reads are estimated to be authentic (not contaminated), while around 8% of the reads are estimated to be contaminants. This suggests that there is a significant level of contamination in the sample, and further analysis or additional contamination checks may be necessary to confirm the authenticity of the ancient DNA data.


######################
########PART 4########
######################

#QUESTION: List 2 other aDNA contamination check programs (they can use mtDNA data or other forms of aDNA data).
#1. ANGSD (Analysis of Next Generation Sequencing Data) - This program can estimate contamination in ancient DNA samples by analyzing the allele frequency spectrum and comparing it to reference populations. It uses a Bayesian framework to model contamination and can provide estimates of contamination levels in both mitochondrial and nuclear DNA.
#2. AuthentiCT - This tool is designed to assess the authenticity of ancient DNA sequences by analyzing patterns of DNA damage and fragmentation. It uses a machine learning approach to distinguish between authentic ancient DNA and modern contaminants, providing a contamination score based on the observed damage patterns in the sequencing data.
#3. PMDtools - This program identifies post-mortem damage (PMD) patterns in ancient DNA sequences to help distinguish authentic ancient DNA from modern contamination. It calculates a PMD score for each read, which can be used to filter out likely contaminants based on the characteristic damage patterns observed in ancient DNA.
#4. ContamLD - This tool estimates contamination in ancient DNA samples by analyzing patterns of linkage disequilibrium (LD) in the sequencing data. It compares the observed LD patterns to those expected under different contamination scenarios, allowing for the estimation of contamination levels in both mitochondrial and nuclear DNA.
#5. DamageProfiler - This program profiles DNA damage patterns in ancient DNA sequences to help identify authentic ancient DNA and distinguish it from modern contaminants. It analyzes the frequency and distribution of damage patterns, such as cytosine deamination, to provide insights into the authenticity of the ancient DNA data.

#QUESTION: Write a few sentences describing how one of those programs works (high level).
#ANGSD is a software package for analyzing next-generation sequencing data. It handles different types of input data, including BAM files, and can perform various analyses such as estimating allele frequencies, genotype likelihoods, and contamination levels.
#For contamination estimation, ANGSD uses a Bayesian framework to model the observed allele frequencies in the ancient DNA sample and compares them to reference populations. By analyzing the allele frequency spectrum and patterns of genetic variation, ANGSD can provide estimates of contamination levels in both mitochondrial and nuclear DNA, helping researchers assess the authenticity of their ancient DNA samples.
#https://link.springer.com/article/10.1186/s12859-014-0356-4