#!/bin/bash -l

##OVERVIEW for WEEK 9 ASSIGNMENT - Damage plots:
#For this assignment, we will be using MapDamage2 and PMDTools to examine damage patterns,
#and then masking damaged bases of our reads.

#We will be looking just at the merged reads that were mapped to the human reference genome hg19


#######################
########PART 0########
######################
#housekeeping before we start the assignment!!! Keep a clean house!!!

#copy this script into your own USER directory. Type the following into the terminal:
USER="Lucy" #replace Lucy with your actual foldername
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/ASSIGNMENTS/WEEK9-DamagePlots/9_DamagePlots_assignment.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/
#then modify the script in your own folder


######################
########PART 1########
######################

##Background Information Assignment:

#Before beginning, we need to understand why we look at damage plots and what the plots themselves are telling us
#Read the following documentation and answer the questions below (the papers will be posted online; feel free to read more than assigned)

#Willerslev & Cooper 2005, "Ancient DNA," Fig. 1 https://doi.org/10.1098/rspb.2004.2813
#Orlando et al 2021, "Ancient DNA analysis," pp. 6-7 and Fig. 3 https://doi.org/10.1038/s43586-020-00011-0
#MapDamage2 info: https://ginolhac.github.io/mapDamage/
#PMDTools info: Skoglund et al 2014, "Separating endogenous ancient DNA from modern day contamination in a Siberian Neandertal," pp. 1-2 (Intro & first paragraph of Methods) https://doi.org/10.1073/pnas.1318934111
#OPTIONAL but useful: "The Little Book of Smiley Plots": https://www.spaam-community.org/little-book-of-smiley-plots/


#QUESTION 1: What are two types of aDNA damage? Describe in your own words.
#DNA FRAGMENTATION: this occurs by chemical processes that break the DNA backbone into miilions of small fragments than their orignal length.
#Deamination: this occurs when cytosine (C) bases are converted to uracil (U) bases, which are then read as thymine (T) bases during sequencing. This results in C to T substitutions in the DNA sequence, particularly at the ends of the DNA fragments.
#This is where a partial UDG treatment is needed tp preserve the authentic ends of the DNA.

#QUESTION 2: What type of aDNA damage does MapDamage and PMDTools identify?
#MapDamage and PMDTools identify fragmentation due to depurination and cytosine deamination, which generates the typical pattern of C->T and G->A variation at the 5’- and 3’-end of the DNA molecules.

#QUESTION 3: In a few sentences, describe how to read a damage plot (aka smiley plot).
#Damage plots, also known as smiley plots, display the frequency of nucleotide misincorporations at the ends of DNA fragments. The x-axis represents the position along the DNA fragment, while the y-axis shows the frequency of specific nucleotide changes (e.g., C to T or G to A). Peaks in the plot indicate higher rates of damage at those positions, typically at the 5' and 3' ends of the fragments, which is characteristic of ancient DNA damage patterns.

#QUESTION 4: What is the purpose of identifying damage patterns in our aDNA sequences?
#Identifying damage patterns in ancient DNA sequences is crucial for distinguishing authentic ancient DNA from modern contamination. By understanding the characteristic damage patterns, researchers can assess the quality and authenticity of the DNA, correct for errors in sequencing, and make informed decisions about which sequences to include in downstream analyses. This helps ensure that conclusions drawn from the data are based on genuine ancient genetic material rather than artifacts or contamination.

######################
########PART 2########
######################

#Now, we will run DamageProfiler2 & PMDTools
#Since our merged mapping file is large, we will run both programs as a job

##ASSIGNMENT: Create a new job script, and paste the code in between the two "##############"

#NOTE: Make sure to update the name of the job, give it 24 tasks per node, and make the job run at least 5 days.

cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/
code 9_DamagePlotsLO.sh 


##############

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
#. signals the current directory, so the bam files will be copied into the current directory(PATH_DMG)

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

##############

#IMPORTANT: Before submitting, check your script against this one here: /dartfs/rc/lab/F/FleskesR/BioinfoWG/RAW_Scripts/9_DamagePlots.sh


#Now run 9_DamagePlots.sh (make sure you're in your Scripts directory!)
sbatch 9_DamagePlotsLO.sh

#This could take several days. Check on the status:
squeue --me
#Also, check the slurm output file for the job to make sure it is running 
#and not looping back over on samples already run by looking at the "slurm-#######.out" file in your Scripts directory


#While that is running, answer the following questions:

#QUESTION 5: What is the purpose of copying the merged unique reads to the DamagePlots folder 
#instead of just running the program on the original ones? 
#The merged unique reads are used for preventing duplications, fasle damage rates and improve statistical fit.


#QUESTION 6: What do the 4 different flags in the MapDamage code do?
#-d: is for a folder name to store results
#-r: is for reference file in FASTA format
#-i: is to input file
#

#QUESTION 7: What is the purpose of adding MD tags to our sequences for PMDTools?
#To identify files easily or distingusih them from other files

#Once the job is done running and you have confirmed both programs worked, then clean up:
cd ${PATH_DMG}
rm *merged.sort.rmdup.uniq.bam

######################
########PART 3########
######################
#We don't want damaged data in our future analyses, so we need to mask the damaged bases at the ends of the reads
#We use a program called bamRefine, using both the Human Origins Panel and 1000Genomes Panel for references

#ASSIGNMENT: Do some reading about what bamRefine can do: https://github.com/etkayapar/bamRefine
#QUESTION 8: Before bamRefine, we used to "hard clip" the terminal ends of reads, aka remove a certain 
#number of bases from all reads, depending on how many bases were shown to be damaged in the mapDamage plots. 
#What do you think is the value of using bamRefine instead of just "hard clipping"?
#bamRefine avoids bias in genotyping or false positives and data loss

##Step 0: Set up folders
USER="Lucy" #replace Lucy with your actual foldername
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/10_BamRefine/{HumanOrigins,1000Genomes}

cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts

##Step 1: Run bamRefine for Human Origins panel
#Create a new job script called 10_bamRefine-HO.sh, pasting the code below the sets of ##############:
#Hint: Make sure your .sh file has the #!/bin/bash -l on the first line! Otherwise the computer won't know it is a shell (.sh) script.

##############

#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable
#SBATCH --job-name=HO_bamrefine
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --time=2-01:00:00
#SBATCH --mail-type=BEGIN,END,FAIL

################################################################################
### SETTINGS ###################################################################
################################################################################


USER="Lucy" #replace Lucy with your actual foldername

BASE_PATH="/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}"
BAMREFINE_DIR="${BASE_PATH}/Data/10_BamRefine/HumanOrigins"
Eigenstrat_PATH="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/HumanOrigins/Plink-Final/Eigenstrat"
MappedSeqs_PATH="${BASE_PATH}/Data/8_MappingHG19/mapped"

# Number of terminal positions bamRefine will mask
BAMREFINE_L=10

source ~/.bashrc
module load samtools/1.9

conda activate Sequencing

cd "${BAMREFINE_DIR}"

################################################################################
### STEP ONE: Build chr-prefixed HO SNP file for bamRefine #####################
################################################################################

HO_SNP="${Eigenstrat_PATH}/HO.final.filtered.snp"
HO_SNP_CHR="${BAMREFINE_DIR}/HO.final.filtered.chr.snp"

echo "[STEP1] Building chr-prefixed HO SNP file for bamRefine..."
awk 'BEGIN{OFS="\t"} {$2="chr"$2; print}' "${HO_SNP}" > "${HO_SNP_CHR}"
echo "[STEP1] Done: $(wc -l < "${HO_SNP_CHR}") SNPs"

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
        -s "${HO_SNP_CHR}" \
        -l "${BAMREFINE_L}" \
        -S \
        -p 8 \
        -v \
        "${bam}" "${out}"
    samtools index "${out}"
done

echo "[BAMREFINE] Done. Refined BAMs in ${BAMREFINE_DIR}"

##############

#submit your job!
sbatch 10_bamRefine-HO.sh



##Step 2: Run bamRefine for 1000 Genomes panel
#Create a new job script called 10_bamRefine-1000G.sh, pasting the code below the sets of ##############:
#Hint: Make sure your .sh file has the #!/bin/bash -l on the first line! Otherwise the computer won't know it is a shell (.sh) script.

##############

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

#submit your job!
sbatch 10_bamRefine-1000G.sh


#QUESTION 9: Why do we run this program twice? 
#each program has different references

#Question 10: What are the differences between the scripts? 
#different reference paths


