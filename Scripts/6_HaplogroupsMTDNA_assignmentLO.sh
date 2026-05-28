#!/bin/bash -l

#In this assignment, you will work through the mtDNA variant calling pipeline,
#which is a critical step in ancient DNA analysis. This workflow takes mapped BAM files 
#and produces:
#1. Variant calls (VCF files)
#2. Consensus mitochondrial genomes for later use in mtDNA contamination estimation
#3. Haplogroup assignments using HaploGrep


#######################
########PART 0########
######################
#housekeeping before we start the assignment!

#copy this script into your own USER directory. You can do this using the cp command.
#tip: do this by copying the script from the terminal using the full path, and then pasting it into your own directory using the full path.
6_HaplogroupsMTDNA_assignment.sh 


#then modify the script in your own folder


######################
########PART 1########
######################
#We start an interactive session as before:
srun --pty bash -l
#Then activate the conda environment for mapping
conda activate ContaMixEnv

##Step 1: set up folders and variables
USER="Lucy" #replace YOURNAME with your actual foldername
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/6_MtDNA/Variants

#set you base path variable to your USER folder
BASE_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data

#set your reference path variable to the location of the mtDNA reference genome
REF_PATH="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/MtDNA"

#set your path to the scripts folder 
#PATH_scripts=/dartfs/rc/lab/F/FleskesR/BioinfoWG/RAW_Scripts

#set variable to call the name of the haplogrep folder 
HAPLOGREP=~/haplogrep

#QUESTION: What does the ~ symbol mean in the path? 
#The ~ symbol is the home directory to locate the haplogrep folder. 

#step 2: copy the merged bam files into the Variants folder and move to that directory
#cp ${BASE_PATH}/4_Merge/MtDNA/filtered/*uniq.bam ${BASE_PATH}/6_MtDNA/Variants
cp ${BASE_PATH}/5_MappingMTDNA/mapped/*uniq.bam ${BASE_PATH}/6_MtDNA/Variants
rm -f ${BASE_PATH}/6_MtDNA/Variants/*.q30.sort.rmdup.uniq.bam
#/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy/Data/5_MappingMTDNA/mapped
#now move into the ${BASE_PATH}/6_MtDNA/Variants folder 
#use the ls command to check that the bam files are there
cd ${BASE_PATH}/6_MtDNA/Variants
ls ${BASE_PATH}/6_MtDNA/Variants


#QUESTION: Why are we working with the uniq merged files?
#These are files that have been filtered to have only unique reads that map to the mtDNA reference genome. This is important for accurate variant calling, as it reduces the chances of including reads that may be contaminants or that may map to multiple locations in the genome, which can lead to false variant calls.

#last, set your name variable
#NAME="CAL03_FGC2096_s_1.mtDNA.mem.merged.sort.rmdup.uniq" #change to your file name before .bam
NAME="CAL03" #change to your file name before .bam

######################
########PART 2########
######################

#variant calling!


##STEP 1: sort and index the uniq bam files. Sorting makes sure that the data are aligned in the correct order, and indexing allows us to quickly access the data in the bam file.
#both are necessary for the next steps of variant calling.
samtools sort ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.bam -o ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.bam
#samtools sort ${NAME}.bam -o ${NAME}.sort2.bam
samtools index ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.bam
#samtools index ${NAME}.sort2.bam

#STEP 2: Next we need to align all the reads in order to call genotype likihoods
#The pileup command generates a summary of the base calls at each position in the reference genome, 
bcftools mpileup -q 30 -Q 30 -f ${REF_PATH}/rCRS.fasta ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.bam > ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.bcf 
ls ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.bcf
#QUESTION: look up the manual for bcftools mpileup and explain what the following flags do:
# -q 30 : the -q is the minimum mapping quality set to 30, which means that only reads with a mapping quality of 30 or higher will be included in the pileup. This helps to ensure that only high-quality reads are used for variant calling.
# -Q 30 : the -Q is the minimum base quality set to 30, which means that only bases with a quality score of 30 or higher will be included in the pileup. This helps to ensure that only high-quality base calls are used for variant calling.
# -d 5 : the -d options sets the maximum depth of coverage to 5, which means that if there are more than 5 reads covering a particular position, only the first 5 will be included in the pileup. This can help to reduce the computational burden and prevent issues with very high coverage regions.
# -f : the -f sets the reference sequence file, in this case, the mtDNA reference genome (NC_012920.1.fasta). This is necessary for the pileup to know which reference sequence to align the reads against and to determine the positions of variants.
#https://samtools.github.io/bcftools/bcftools.html
#what is the file ending for the output file? what does this file do?
# The output file is a .bcf file, which is a binary version of a VCF file. It contains the pileup data that will be used for variant calling in the next step. The .bcf format is more efficient for storing and processing large amounts of variant data compared to the text-based VCF format.

#STEP 3: Then we use bcftools call to call variants based on the pileup data.
bcftools call -v -c --ploidy 1 -O z ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.bcf > ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.variants.vcf.gz
ls ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.variants.vcf.gz
#QUESTION - now look up the manual for the call command and explain what the following flags do:
# -v : -v outputs variant sites only, which means that only positions in the genome where a variant is detected will be included in the output VCF file. This helps to reduce the size of the output file and focus on the relevant variant information.
# -c : -c is the original samtools/bcftools consensus calling method, which uses a simple model to call variants based on the pileup data. In this case, we are using it to call variants in mtDNA, which is haploid and may not require the more complex models used for diploid genomes.
# --ploidy 1 : --ploidy 1 means that we are treating the genome as haploid, which is appropriate for mtDNA since it is inherited maternally and does not have pairs of chromosomes like nuclear DNA. This flag tells bcftools to call variants assuming that there is only one copy of each position in the genome.
# -O z : -O z means output in compressed VCF (z) format (VCF.gz), which is a more efficient way to store and handle large variant files.
#https://samtools.github.io/bcftools/bcftools.html
#what is the file ending for the output file? what does this file do?
# Output file is a .vcf.gz file, which is a compressed VCF file containing the called variants. This file will be used for downstream analysis, including filtering the variants and ultimately calling haplogroups.

#STEP 4: Now we need to filter the variants. We do this using bcftools view.
bcftools view -i 'DP>5' ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.variants.vcf.gz -o ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants.vcf.gz
ls ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants.vcf.gz
#QUESTION: what does the flag -i do? -i includes only sites that satisfy the given expression, in this case 'DP>5', which means that only variants with a depth of coverage greater than 5 will be included in the output file. This helps to ensure that we are only considering variants that have sufficient evidence from the sequencing data, which can improve the accuracy of our variant calls and downstream analyses.
#What does the 'DP>5' argument do? 'DP>5' is a filtering expression that specifies that only variants with a depth of coverage (DP) greater than 5 will be included in the output file. This means that for a variant to be retained in the filtered VCF file, there must be more than 5 reads covering that position in the genome.

bcftools view -i 'QUAL>30' ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants.vcf.gz -o ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants2.vcf.gz
ls ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants2.vcf.gz
#QUESTION: what does the 'QUAL>30' argument do?'QUAL>30' means quality score of the variant call must be greater than 30.

bcftools view -i 'TYPE="snp"' ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants2.vcf.gz -o ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.vcf
ls ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.vcf
#QUESTION: what does the 'TYPE="snp"' argument do? 'TYPE="snp"' excludes variants that are not single nucleotide polymorphisms (SNPs), such as insertions or deletions (indels).

#bcftools view -i 'DP>5 && QUAL>30 && TYPE="snp"' ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.vcf -o output.vcf
#ls output.vcf

#now check to make sure that the files were done correctly"
cat ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.vcf | egrep -v '##' | head -20
#QUESTION: what does the egrep -v '##' command do? means to exclude lines that start with ##, which are header lines in the VCF file. 

#now we have created our final filtered file ending in filteredvariants3.vcf!
#lets check out what the VCF file looks like. This contains the list of variants that will be used to call mtDNA haplogroups.
#delete code ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.vcf

#QUESTION: what are some of the variants identified here? Hint: These are the lines that do not start with ## 
##ADD MORE QUESTIONS HERE WHEN EDITING############



#STEP 5: clean up! We do not need all of the intermediary files we just created.
rm -f ${BASE_PATH}/6_MtDNA/Variants/*.bam
rm -f ${BASE_PATH}/6_MtDNA/Variants/*filteredvariants2.vcf.gz
rm -f ${BASE_PATH}/6_MtDNA/Variants/*filteredvariants.vcf.gz
rm -f ${BASE_PATH}/6_MtDNA/Variants/*variants.vcf.gz
rm -f ${BASE_PATH}/6_MtDNA/Variants/*.bai
rm -f ${BASE_PATH}/6_MtDNA/Variants/*.bcf



######################
########PART 3########
######################

#now we need to make our MITOGENOME consensus sequences! As consensus sequence is the sample's fasta file that incorporates the 
#mutations we called in the previous variant caling step. We will use these for contaminaiton estimation later on. 
#you can also use these to create phylogenetic trees.

#STEP 1: make a new folder for the consensus sequences and move into that folder
mkdir -p ${BASE_PATH}/6_MtDNA/Consensus
cd ${BASE_PATH}/6_MtDNA/Consensus

#copy the contents of the Variants folder into this folder. We will use these files to create our consensus sequences
cp ${BASE_PATH}/6_MtDNA/Variants/* .

#STEP 2: first we need to normalize variants - which means that we need to get rid of indels (insertions or delections)
#since they can create problems for consensus sequences. We do this using bcftools norm and then follow by keeping only SNPS
bcftools norm -f ${REF_PATH}/rCRS.fasta ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.vcf -Ob -o ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.norm.bcf
bcftools view --types snps ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.norm.bcf -Oz -o ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.norm.filter.vcf.gz
#QUESTION: how does bcftools view filter for only snps?
#bcftools view --types snps filters the variants by specifying that only those of type "snp" (single nucleotide polymorphisms) should be included in the output. 
#This means that any variants that are not classified as SNPs, such as insertions, deletions, or other types of variants, will be excluded from the resulting VCF file. The --types option allows you to specify which types of variants you want to retain in your analysis, and in this case, we are choosing to keep only SNPs for the consensus sequence generation.

#STEP 3: now we need to fix any issues that arise using bcftools gzip. This program doesnt gzip in the correct way, so we need to
#first unzip it (zcat), then zip it correctly bgzip, then index it (tabix). We are doign this using the pipe (|) command, 
#which places the output directly into the next step. 
zcat ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.norm.filter.vcf.gz | bgzip -c > ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.norm.filter.fix.vcf.gz && tabix ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.norm.filter.fix.vcf.gz
#QUESTION: what does the && do in this script? Does it kill the tabix command or the zipping commands?
#The && operator is used to chain commands together, and it ensures that the second command (tabix) will only execute if the first command (zcat and bgzip) completes successfully without any errors.
#If the zcat and bgzip command fails for any reason, the tabix command will not be executed. So, it does not kill either command, but rather it controls the flow of execution based on the success of the first command.


#STEP 4: Now we can Convert vcf calls file into fasta file form. We do this using the bcftools consensus program.
#note that .fa is a shorthand notation for fasta
cat ${REF_PATH}/rCRS.fasta | bcftools consensus ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.norm.filter.fix.vcf.gz > ${NAME}.mtDNAconsensus.fa
#QUESTION: what is the pipe doing here?
#The pipe (|) is taking the output of the cat command, which is the contents of the reference fasta file, and feeding it directly into the bcftools consensus command. 
#This allows us to use the reference sequence as the basis for generating the consensus sequence, which incorporates the variants called in the VCF file. The resulting consensus sequence is then saved to a new fasta file named ${NAME}.mtDNAconsensus.fa.


#STEP 5: Now lets check that this worked by printing out the legnth of the sequence. 
#QUESTION: If this is the mtDNA reference sequence, what should the expected number of bases be? The expected number of bases in the mtDNA reference sequence (rCRS) is 16,569 bases.
infoseq -only -name -length ${NAME}.mtDNAconsensus.fa


#STEP 6: clean up!
#remove the *.filteredvariants3.vcf file using the rm command




######################
########PART 4########
######################

#now we get to do the fun part, call our mtDNA haplogroups!
#we are going to do this using the program haplogrep. This is also avalible online at https://haplogrep.i-med.ac.at/ 
#but we are going to run the command line version because we are awesome coders now!

#Redefine your base path and reference path variables if needed
BASE_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data
REF_PATH="/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/MtDNA"

#STEP 1: make our folders and variables
HG_DATA_FOLDER=${BASE_PATH}/6_MtDNA/Haplogrep
mkdir -p $HG_DATA_FOLDER
#QUESTION: how is this a different way of creating a new folder?
#Using the $HG_DATA_FOLDER variable allows us to reference the folder path throughout the script without having to type out the full path each time. 
#It also makes it easier to change the folder location in the future if needed, as we would only need to update the variable rather than every instance of the folder path in the script. Additionally, using variables can help improve readability and organization of the code.

#move into to your HG_DATA_FOLDER (use the cd command!)
cd $HG_DATA_FOLDER

#copy the filteredvariants3.vcf into HG_DATA_FOLDER
cp ${BASE_PATH}/6_MtDNA/Variants/*filteredvariants3.vcf .

#move into the HG_DATA_FOLDER
cd $HG_DATA_FOLDER


#STEP 2: Change our conda environment. We have been running in ContaMixEnv, but now we need to switch our environments.
#do you remember how to deactivate you conda environment? (hint the program is in the previous sentence)
conda deactivate

#now activate java enviroment. This is the environment that contains the java program needed to run haplogrep.
conda activate java

#rename our variables
HAPLOGREP=/dartfs-hpc/rc/home/5/f008715/FleskesR/BioinfoWG/Programs
NAME="CAL03"

#STEP 3: now run haplogrep. we use the ./ before the program name because it is not installed on the system, but rather in our program directory
$HAPLOGREP/haplogrep3 classify --in ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.vcf --out ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.haplogrepconsensus.txt --extend-report --hits 3 --tree "phylotree-rcrs@17.0"

#QUESTION: Using the manual, answer the following quesitons: 
#what does the --extend-report flag do? 
#The --extend-report flag in HaploGrep3 is used to generate an extended report that includes additional information about the haplogroup assignment. This extended report typically contains details such as the specific variants that were used for the haplogroup classification, the quality of the assignment, and any relevant notes or comments about the haplogroup. It provides a more comprehensive overview of the results compared to a standard report.

#QUESTION: What about the --hits 3 flag? 
#The --hits 3 flag in HaploGrep3 specifies that the program should report the top 3 haplogroup hits for each sample. This means that instead of only providing the single best haplogroup assignment, HaploGrep will return the three most likely haplogroups based on the variant data, along with their respective quality scores. This can be useful for understanding the uncertainty in the haplogroup assignment and for exploring alternative classifications that may be relevant to the sample being analyzed.

#QUESTION: What about the --tree flag?
#The --tree flag in HaploGrep3 is used to specify the phylogenetic tree that the program should use for haplogroup classification. In this case, "phylotree-rcrs@17.0" indicates that HaploGrep should use the PhyloTree build 17.0, which is a widely used reference for human mitochondrial DNA haplogroups. This tree contains the hierarchical structure of haplogroups and their defining mutations, allowing HaploGrep to accurately classify samples based on their variant profiles in relation to the known haplogroup definitions in the specified tree.


# to stop the interactive session type:
exit


#STEP 5: Now check out your haplogrep results using the less!
less ${NAME}.mtDNA.mem.merged.sort.rmdup.uniq.sort2.filteredvariants3.haplogrepconsensus.txt

#QUESTION: What are the 3 lines of data?
#Sample name (CALO3), haplogroup assigned (K1a4d), and the quality score of the haplogroup (0.967)

#QUESTION: What is your sample's haplogroup?
#K1a4d or K1a4

#QUESTION: Where is that haplogroup most common?
#Germany, U.S, and England



######################
########PART 5########
######################
#Now, we will run all of our samples using a slurm job script

#Step 1: Copy the slurm script to your directory
USER="Lucy" #replace YOURNAME with your actual foldername
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/ASSIGNMENTS/WEEK6-HaplogroupsMTDNA/6_MtDNAVariants.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/

cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/

#Edit variables and paths as needed in ../Scripts/6_MtDNAVariants.sh

#run 6_MtDNAVariants.sh
sbatch 6_MtDNAVariants.sh

#check status
squeue -u userid

#Once the job is completed,check the folders to make sure all steps worked!

#QUESTION: what are the haplogroups for your sample(s)? Do they make sense based on the archaeological context of the samples?
