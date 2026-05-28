#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=variants

# Number of compute nodes
#SBATCH --nodes=1

# Number of cores, in this case one
#SBATCH --ntasks-per-node=16

# Walltime (job duration)
#SBATCH --time=1-01:00:00

# Email notifications
#SBATCH --mail-type=BEGIN,END,FAIL

#Script for mtDNA Haplogroup Determination


source ~/.bashrc

# Necessary dependencies
USER="Lucy" #replace YOURNAME with your actual foldername
BASE_PATH="/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data"
REF_PATH="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/MtDNA"
HAPLOGREP=/dartfs/rc/lab/F/FleskesR/BioinfoWG/Programs
#PATH_scripts="/dartfs/rc/lab/F/FleskesR/BioinfoWG/RAW_Scripts"

conda activate ContaMixEnv

mkdir -p ${BASE_PATH}/6_MtDNA/Variants
cp ${BASE_PATH}/5_MappingMTDNA/mapped/*mtDNA.mem.merged.sort.rmdup.uniq.bam ${BASE_PATH}/6_MtDNA/Variants
cd ${BASE_PATH}/6_MtDNA/Variants


### 1. Generate pileup, call variants and produce vcf file

for k in *uniq.bam
do
    echo "VARIANT CALLING IN PROCESS..MTDNA"
    echo "sort bam file by coordinate"
    samtools sort ${k} -o ${k%.*}.sort2.bam

    echo "Index Bam Files"
    samtools index ${k%.*}.sort2.bam

    echo "Pile up all the reads, and then call genotype likihoods"
    bcftools mpileup -q 30 -Q 30 -f ${REF_PATH}/rCRS.fasta ${k%.*}.sort2.bam > ${k%.*}.sort2.bcf 
    bcftools call -v -c --ploidy 1 -O z ${k%.*}.sort2.bcf > ${k%.*}.sort2.variants.vcf.gz

    echo "Filter variants with a greater than 30 quality score, greater than 5 depth (change for WG to 1)"
    bcftools view -i 'DP>5' ${k%.*}.sort2.variants.vcf.gz -o ${k%.*}.filteredvariants.vcf.gz
    bcftools view -i 'QUAL>30' ${k%.*}.filteredvariants.vcf.gz -o ${k%.*}.filteredvariants2.vcf.gz
    bcftools view -i 'TYPE="snp"' ${k%.*}.filteredvariants2.vcf.gz -o ${k%.*}.filteredvariants3.vcf
    
    echo "view head files to verify done correctly"
    echo "MtDNA Filtered Variant by q >30 FILE CHECK:"
    cat ${k%.*}.filteredvariants3.vcf | egrep -v '##' | head -20
done

rm -f ${BASE_PATH}/6_MtDNA/Variants/*.bam*
rm -f ${BASE_PATH}/6_MtDNA/Variants/*filteredvariants2*
rm -f ${BASE_PATH}/6_MtDNA/Variants/*variants.vcf*
rm -f ${BASE_PATH}/6_MtDNA/Variants/*.bcf
rm -f ${BASE_PATH}/6_MtDNA/Variants/*uniq.filteredvariants.vcf.gz


### 8. Make MITOGENOME consensus sequences
mkdir -p ${BASE_PATH}/6_MtDNA/Consensus
cd ${BASE_PATH}/6_MtDNA/Consensus
cp ${BASE_PATH}/6_MtDNA/Variants/* .

for i in *filteredvariants3.vcf
do
    echo "normalize indels using the quality filtered VCF file"
    bcftools norm -f ${REF_PATH}/rCRS.fasta ${i} -Ob -o ${i%.*}.norm.bcf

    echo "filter for only SNPS"
    bcftools view --types snps ${i%.*}.norm.bcf -Oz -o ${i%.*}.norm.filter.vcf.gz

    echo "fixissues"
    zcat ${i%.*}.norm.filter.vcf.gz | bgzip -c > ${i%.*}.norm.filter.fix.vcf.gz && tabix ${i%.*}.norm.filter.fix.vcf.gz

    echo "Convert vcf calls file to fasta"
    cat ${REF_PATH}/rCRS.fasta | bcftools consensus ${i%.*}.norm.filter.fix.vcf.gz > ${i%.*}.mtDNAconsensus.fa
    
    echo "Length of Sequence: ${i%.*}"
    infoseq -only -name -length ${i%.*}.mtDNAconsensus.fa
done

rm -f ${BASE_PATH}/6_MtDNA/Consensus/*.filteredvariants3.vcf

echo "*****************************************"


### 9. MITOGENOME CALLER - HAPLOGREP
HG_DATA_FOLDER=${BASE_PATH}/6_MtDNA/Haplogrep
mkdir -p $HG_DATA_FOLDER
cd $HG_DATA_FOLDER
cp ${BASE_PATH}/6_MtDNA/Variants/*filteredvariants3.vcf .

echo "running haplogrep"
cd $HAPLOGREP

for k in $HG_DATA_FOLDER/*filteredvariants3.vcf
do
    echo "CALLING HAPLOGREP"
    ./haplogrep3 classify --in ${k} --out ${k%%.*}.haplogrepconsensus.txt --extend-report --hits 3 --tree "phylotree-rcrs@17.0"
done

