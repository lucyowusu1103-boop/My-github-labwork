#!/bin/bash -l

##OVERVIEW for WEEK 11 ASSIGNMENT - Y-chromosome Inferences:
#For this assignment, we will be using using two methods to determine if our individuals possessed Y-chomosomes,
#which allows us to infer the genetic sex of the individuals
#At the end of this lesson, we will read and discuss about human sex chromosome diversity.


#######################
########PART 0########
######################
#housekeeping before we start the assignment!!! Keep a clean house!!!

#copy this script into your own USER directory. Type the following into the terminal:
USER="Lucy" #replace Lucy with your actual foldername
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/ASSIGNMENTS/WEEK11-YchrInference/11_YchrInference_assignment.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/
#then modify the script in your own folder

#Also copy the folder containing the Ychr Inference scripts into your Scripts folder, found here: /dartfs/rc/lab/F/FleskesR/BioinfoWG/RAW_Scripts/11_Ychr_Inference_Scripts
#HINT: Make sure you copy the folder itself, not just what is in it! What code do you use for copying folders rather than just files?
#paste your code below:
cp -r /dartfs/rc/lab/F/FleskesR/BioinfoWG/RAW_Scripts/11_Ychr_Inference_Scripts /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/

#Finally, make a directory for results:
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/11_YchrInference/{Ry,Rx}

######################
########PART 1########
######################

##Background Information Assignment:

#Now that we have inferred the presence of Y-chromomes (or not) in our data, we need to understand the nuances of genetic sex in human populations.
#This will allow us to think critically about how we infer genetic sex in archaeological Ancestors.

#Read the following papers and answer the questions below (the papers will be posted online; feel free to read more than assigned)

#Bensberg et al 2026, "Human Sex Chromosome Biology in the Genomic Era," https://doi.org/10.1146/annurev-genom-020525-014813 
#Richardson et al 2012, "Sexing the X: How the X Became the “Female Chromosome”," https://doi.org/10.1086/664477
#Fox Keller 1995, "Gender and Science: Origin, History, and Politics," http://www.jstor.org/stable/301911
#Fausto-Sterling 2018, "Why Sex Is Not Binary," https://joelvelasco.net/teaching/3334/fausto-Why_sex_Is_Not_Binary.pdf
#Astorino 2019, "Beyond Dimorphism: Sexual Polymorphism and Research Bias in Biological Anthropology," pp.489-490 https://doi.org/10.1111/aman.13224


######################
########PART 2########
######################

#Method 1: Ry from Skogland et al 2013

#Use code ry_compute.py in the RAW_Scripts/11_Ychr_Inference_Scripts
#from: https://doi.org/10.1016/j.jas.2013.07.004 supplemental file
#Found here: https://github.com/pontussk/ry_compute

#ASSIGNMENT: Read the paper and GitHub page linked above, and answer the questions below.

#QUESTION 1: What will be the input data for these analyses? In which sub-directory within you Data folder contains the input files? Why?
#data from shotgun sequencing. /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy/Data/10_BamRefine/1000Genomes. These are files that are ready for further analyses.


#QUESTION 2: Describe how the Ry method is used to infer genetic sex using your own words.
# Ry = ny/(nx + ny). The nx + ny is the total number of alignments to both sex chromosomes. ny is the number of alignemnts to the Y chromosomes. All together make up Ry.


#QUESTION 3: The GitHub page tells you how to use their code. Paste their example below.
samtools view <MYBAM.bam> | python ry_compute.py [options]
#Options: -h, --help show this help message and exit --chrXname=CHRXNAME Identifier for the X chromosome in the SAM input (use if different than chrX, X etc) --chrYname=CHRYNAME Identifier for the Y chromosome in the SAM input (use if different than chrY, Y etc) --malelimit=MALELIMIT Upper R_y limit for assignment as XY/male --femalelimit=FEMALELIMIT Lower R_y limit for assignment as XX/female --digits=DIGITS Number of decimal digits in R_y output --noheader Do not print header describing the columns in the output --idxstats Input is from samtools idxstats


#Run in an interactive session
srun --pty bash -l
#This script requires Python version 2.7 since it is older. So we will activate the conda environment that has Python 2.7 installed
conda activate py27
module load samtools/1.9
##Step 1: set up folders and variables
USER="Lucy" #replace Lucy with your actual foldername

#Make variables for paths
Masked_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/10_BamRefine
Code_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/11_Ychr_Inference_Scripts/ry_compute-master
Results_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/11_YchrInference/Ry

cd $Masked_PATH

#First, run for 1000Genomes
cd 1000Genomes
for i in *.refined.bam ; do f=`echo $i | cut -f1 -d "."` ; \
  samtools view -q 30 ${f}.hg19.aln.merged.sort.rmdup.uniq.refined.bam | python ${Code_PATH}/ry_compute.py > ${Results_PATH}/${f}.1000G.Ry.results.txt
done

#QUESTION 4: How does this code differ from the one provided as an example? Why did we add what we did?
#We include the input uniq.refined.bam file from /Data/10_BamRefine/1000Genomes at a quality of 30

#Now we're going to re-run using the Human Origins panel.
#Copy the code above and edit it. #HINT: There are 2 places in the script that need changing.

cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/10_BamRefine/HumanOrigins
for i in *.refined.bam ; do f=`echo $i | cut -f1 -d "."` ; \
  samtools view -q 30 ${f}.hg19.aln.merged.sort.rmdup.uniq.refined.bam | python ${Code_PATH}/ry_compute.py > ${Results_PATH}/${f}.HO.Ry.results.txt
done

#Now check the results! cd into the $Results folder and paste the outputs below
#For 1000Genomes:
#Nseqs	  NchrY+NchrX	NchrY	R_y	SE	95% CI	Assignment
#36287298 	1911143 	8753 	0.0046 	0.0 	0.0045-0.0047 	XX

#For HumanOrigins:
#Nseqs	 NchrY+NchrX	NchrY	R_y	SE	95% CI	Assignment
#36287298 	1911143 	8753 	0.0046 	0.0 	0.0045-0.0047 	XX

#QUESTION 5: What is the inferred genetic sex of the individual whose data we are analyzing?
#Female

#before moving on, we have to switch conda environments, because Method 2 doesn't require python 2.7
conda deactivate

######################
########PART 3########
######################

#Method 2: Rx from Mittnik et al 2016
#from: https://doi.org/10.1371/journal.pone.0163019 supplemental

#QUESTION 6: Read the Results section of the Mittnick et al 2016 paper. How does this method of genetic sex inference differ from the Ry method we just used?
#Rx is used when there are not enough reads mapped to the Y chromosome.

#QUESTION 7: What coding language is this script written in? Which language was the Ry script written in?
#R and python


#QUESTION 8: Paste the example input from the Mittnick script below. 





##Make sure you're in an interactive session! If not, restart one.
srun --pty bash -l

#Make variables for paths
USER="Lucy" #replace Lucy with your actual foldername
Masked_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/10_BamRefine
Code_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/11_Ychr_Inference_Scripts
Results_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/11_YchrInference/Rx

cd $Masked_PATH

conda activate Sequencing

#first run for 1000Genomes (note: our data has already been filtered to MAPQ 30, so we're not running those lines of the code; just index and get idxstats)
cd 1000Genomes
for i in *.refined.bam ; do f=`echo $i | cut -f1 -d "."` ; \
  samtools index ${f}.hg19.aln.merged.sort.rmdup.uniq.refined.bam
  samtools idxstats ${f}.hg19.aln.merged.sort.rmdup.uniq.refined.bam > ${f}.idxstats
  Rscript ${Code_PATH}/Mittnik2016_Rx_script_edited_hg19.R ${f} > $Results_PATH/${f}.1000G.Rx.txt
done

#Like the previous method, re-run this using the HumanOrigins panel. Paste your edited code below
# cd ../HumanOrigins
# for i in *.refined.bam ; do f=`echo $i | cut -f1 -d "."` ; \
#   samtools index ${f}.hg19.aln.merged.sort.rmdup.uniq.refined.bam
#   samtools idxstats ${f}.hg19.aln.merged.sort.rmdup.uniq.refined.bam > ${f}.idxstats
#   Rscript ${Code_PATH}/Mittnik2016_Rx_script_edited_hg19.R ${f} > $Results_PATH/${f}.HO.Rx.txt
# done

cd ../HumanOrigins
for i in *.refined.bam ; do f=`echo $i | cut -f1 -d "."` ; \
  samtools index ${f}.hg19.aln.merged.sort.rmdup.uniq.refined.bam
  samtools idxstats ${f}.hg19.aln.merged.sort.rmdup.uniq.refined.bam > ${f}.idxstats
  Rscript ${Code_PATH}/Mittnik2016_Rx_script_edited_hg19.R ${f} > $Results_PATH/${f}.HO.Rx.txt
done


#Clean up - move the idxstats to results 
cd $Masked_PATH/1000Genomes
mv *.idxstats $Results_PATH
cd ../HumanOrigins
mv *.idxstats $Results_PATH

conda deactivate 

#QUESTION 9: Does the results of this method agree with the Ry method above?
#Yes. Both showed Female XX


#QUESTION 10: What is the benefit of the Rx method compared to Ry?
#Rx works when there is not enough mapped on the Y chromosome.

#QUESTION 11: Why do you think we use 2 methods to infer the presence of Y chromosomes?
#To cross/double check if both programs infer the same results

######################
########PART 4########
######################

#ADVENTURES IN DEBUGGING CODE
#This last part is optional, but gives you experience with figuring out how to edit code to work for your data

#When I first used the Mittnick Rx script, it didn't work for my samples, even the ones with high coverage.
#Together, we will work through the troubleshooting I did to determine why the code wasn't working, and what I did to fix it.

#Step 1: Look at the 2 scripts in /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}Scripts/11_Ychr_Inference_Scripts for the Mittnick Rx method

#QUESTION 12: How do they differ? (Besides that they are named differently.)
#HINT: Open them in side-by-side view within VSCode.

#QUESTION 13: Which script did we use?
# Rx_script_edited_hg19.R

#QUESTION 14: What is the input data for the Rx method's script?
#idxstats

#Step 2: Look at the input data, i.e. the *.idxstats file in /Data/11_YchrInference/Rx
#The original script assumes that row 23 is the X-chromosome and row 24 is the Y-chromosome

#QUESTION 15: What row is the X-chromosome on in our *.idxstats file? What about the Y-chromosome?
#row 8 for X Chromosome and row 21 for Y chromosome

#The reference sequence that Mittnick used to write their script listed the 22 autosomes, then the X and Y chromosomes.
#But the hg19 reference sequence we used to map our reads lists the chromosomes in order of lenghth, thus the X and Y chromosomes are on different rows.

#Since this method calculates the ratio of X chromosome reads to the ratio of autosomal reads, 2 changes needed to be made to the script.

#QUESTION 16: What is the change that needed to be made in relation to the X-chromosome? HINT: Look at the calculation for "tot"
#Rt8 is the X chromosme
#Rt8/Rt23 was added to tot to match the chromosome to the actual X chromosome we looking for

#QUESTION 17: And for the Y-chromosome?
#Rt8/Rt24 will match if the sex is male.

#HINT: The answers to most, if not all, of these questions is in the Mittnick2016_Rx_script_edited_hg19.R code.
#QUESTION 18: Why do you think I did that?
#To document edits or changes.



#Next, we will move onto future analysis (i.e., X-chromosome contamination checks for XY individuals; Y-haplogroup identification for XY individuals; and
#calling pseudohaploid SNPs for all individuals for READ relative identification, PCA, Admixture, etc.)
