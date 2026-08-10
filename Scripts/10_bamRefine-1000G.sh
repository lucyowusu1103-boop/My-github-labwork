#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable
#SBATCH --job-name=1000G_bamrefine
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --time=2-01:00:00
#SBATCH --mail-type=BEGIN,END,FAIL

################################################################################
### SETTINGS ###################################################################
################################################################################


USER="Lucy" #replace Lucy with your actual foldername

BASE_PATH="/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}"
BAMREFINE_DIR="${BASE_PATH}/Data/10_BamRefine/1000Genomes"
Eigenstrat_PATH="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/1000Genomes/Jan7/Eigenstrat"
MappedSeqs_PATH="${BASE_PATH}/Data/8_MappingHG19/mapped"

# Number of terminal positions bamRefine will mask
BAMREFINE_L=10

source ~/.bashrc
module load samtools/1.9

conda activate Sequencing

cd "${BAMREFINE_DIR}"

################################################################################
### STEP ONE: Build chr-prefixed 1000Genomes SNP file for bamRefine #####################
################################################################################

Geno1000_SNP="${Eigenstrat_PATH}/Phase3.final.snp"
Geno1000_SNP_CHR="${BAMREFINE_DIR}/Phase3.final.chr.snp"

echo "[STEP1] Building chr-prefixed 1000Genomes SNP file for bamRefine..."
awk 'BEGIN{OFS="\t"} {$2="chr"$2; print}' "${Geno1000_SNP}" > "${Geno1000_SNP_CHR}"
echo "[STEP1] Done: $(wc -l < "${Geno1000_SNP_CHR}") SNPs"

################################################################################
### STEP ONE-B: bamRefine — mask terminal damage positions in each BAM #########
#
# -s  EIGENSTRAT .snp with chr-prefixed chromosomes
# -l  number of terminal positions to mask
# -S  single-stranded library mode
# -p  threads
################################################################################

BAM_COUNT=$(ls "${MappedSeqs_PATH}/"*merged.sort.rmdup.uniq.bam 2>/dev/null | wc -l)
echo "[BAMREFINE] Masking terminal damage (l=${BAMREFINE_L}) in ${BAM_COUNT} BAMs..."

for bam in "${MappedSeqs_PATH}/"*merged.sort.rmdup.uniq.bam; do
    base=$(basename "${bam}" .bam)
    out="${BAMREFINE_DIR}/${base}.refined.bam"
    echo "[BAMREFINE]   ${base}"
    bamrefine \
        -s "${Geno1000_SNP_CHR}" \
        -l "${BAMREFINE_L}" \
        -S \
        -p 8 \
        -v \
        "${bam}" "${out}"
    samtools index "${out}"
done

echo "[BAMREFINE] Done. Refined BAMs in ${BAMREFINE_DIR}"


##############
