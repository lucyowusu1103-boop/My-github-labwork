#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=schmutzi

# Number of compute nodes
#SBATCH --nodes=1

# Number of cores, in this case one
#SBATCH --ntasks-per-node=16

# Walltime (job duration)
#SBATCH --time=2-01:00:00

# Email notifications
#SBATCH --mail-type=BEGIN,END,FAIL#SBATCH 

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