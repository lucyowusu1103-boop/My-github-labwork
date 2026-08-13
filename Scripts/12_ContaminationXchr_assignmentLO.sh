#!/bin/bash -l

##OVERVIEW for WEEK 12 ASSIGNMENT - Whole Genome Contamination:
#We have already looked at the mtDNA for signs of contamination.
#For this assignment, we will be looking for signs of contamination in the nuclear data.
#Specifically, we will use a method that looks at the X chromosome


#######################
########PART 0########
######################
#housekeeping before we start the assignment!!! Keep a clean house!!!

#copy this script into your own USER directory. Type the following into the terminal:
USER="Lucy" #replace Lucy with your actual foldername
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/ASSIGNMENTS/WEEK12-ContaminationXchr/12_ContaminationXchr_assignment.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/
#then modify the script in your own folder


######################
########PART 1########
######################

#ANGSD method for X-chromosome contamination

#Read about this method here: https://www.popgen.dk/angsd/index.php/Contamination

#QUESTION 1: Should we use the data for every individual? Why or why not?
# No, This method requires a list of polymorphic sites along with their frequency and we also recommend to discard regions with low mappability. Works with chromosomes with only one genecopy such as the chX for males.

#Now, run the contamination check 
#Run in an interactive session
srun --pty bash -l

conda activate angsd

#Set up our directories & paths:
USER="Lucy" #replace Lucy with your actual foldername
SAMPLE="CAL05" #replace CAL05 with your sample name
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/12_ContaminationXchr/ANGSD
PATH_REF=/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/HapMap
PATH_BAM=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Christina/Data/10_BamRefine/1000Genomes
#We'll just use the 1000Genomes refined data this time
PATH_RES=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/12_ContaminationXchr/ANGSD

cd $PATH_RES

angsd -i $PATH_BAM/$SAMPLE.hg19.aln.merged.sort.rmdup.uniq.refined.bam -r chrX: -doCounts 1 -iCounts 1 -minMapQ 30 -minQ 20 -out $PATH_RES/$SAMPLE.output

contamination -a $PATH_RES/$SAMPLE.output.icnts.gz -h $PATH_REF/HapMapChrX.gz 2> $PATH_RES/$SAMPLE.contamination

#QUESTION 2: Which file contains the contamination estimates?
#CALO5.contamination

#QUESTION 3: What are the X-chromosome contamination estimates for your sample? (hint: there are four; you may have to google this method and look at other websites' info)
#Method1: old_llh Version: MoM:0.005118 SE(MoM):5.842387e-03 ML:0.006493 SE(ML):1.409171e-15 
#Method1: new_llh Version: MoM:0.005091 SE(MoM):5.871305e-03 ML:0.006452 SE(ML):1.724657e-15 5.9%
#Method2: old_llh Version: MoM:0.014360 SE(MoM):1.103500e-02 ML:0.016445 SE(ML):1.177815e-15 
#Method2: new_llh Version: MoM:0.014287 SE(MoM):1.109326e-02 ML:0.016337 SE(ML):8.412962e-17 1.1%
# under 5% contamination is ideal but under 10% is okay. FYI: report both both MoM and ML

#QUESTION 4: Our first line of code (that starts with "angsd") differs from the example code given in the documentation.
#What is that difference? (Hint: It relates to one of the issues with the original Mittnick Rx script that we examined in the last lesson.)
#angsd -i my.bam -r X:5000000-154900000 -doCounts 1  -iCounts 1 -minMapQ 30 -minQ 20


#ASSIGNMENT: Say you have mulitple samples with XY genotypes that you want to check contamination levels.
#Create a job script that has the correct headers (giving 12 cores and 10 hours of run time),
#And that loops through multiple hypothetical samples in your ../10_BamRefine/1000Genomes file.
#Ensure that only XY individuals will be run through the for-loop. Example data XY individuals: IndA, IndB, IndC, IndD, IndE, IndF; IndA, IndC, IndF are XY
#If you need help with for-loops, see /dartfs-hpc/rc/home/5/f008715/FleskesR/BioinfoWG/RAW_Scripts/for_loop_examples.sh

#Put your script in the space below.

#!/bin/bash -l

#SBATCH --account=fleskesr
#SBATCH --partition=preemptable

# Name of the job
#SBATCH --job-name=DamagePlots

# Number of compute nodes
#SBATCH --nodes=1

# Number of cores, in this case one
#SBATCH --ntasks-per-node=12

# Walltime (job duration)
#SBATCH --time=2-10:00:00

# Email notifications
#SBATCH --mail-type=BEGIN,END,FAIL


#source ~/.bashrc


#STEP 1. Setup folders and Variables
#USER="Lucy" #replace Lucy with your actual foldername

#SAMPLE="CAL05" #replace CAL05 with your sample name
#mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/12_ContaminationXchr/ANGSD
#PATH_REF=/dartfs/rc/lab/F/FleskesR/ReferenceSeqs/HapMap
#PATH_BAM=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/10_BamRefine/1000Genomes
#We'll just use the 1000Genomes refined data this time
#PATH_RES=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/12_ContaminationXchr/ANGSD

#cd $PATH_RES

#conda activate Sequencing

#first run for 1000Genomes 
cd 1000Genomes

#example for specific samples only:
for SAMPLE in IndA IndC IndF ; do  
    #Run angsd
    angsd -i $PATH_BAM/$SAMPLE.hg19.aln.merged.sort.rmdup.uniq.refined.bam -r chrX: -doCounts 1 -iCounts 1 -minMapQ 30 -minQ 20 -out $PATH_RES/$SAMPLE.output

    #Run contmaination 
    contamination -a $PATH_RES/$SAMPLE.output.icnts.gz -h $PATH_REF/HapMapChrX.gz 2> $PATH_RES/$SAMPLE.contamination

done 
#Not sure if I need a clean up 


# #Example for all bams:
# for i in *bam ; do  
#     SAMPLE=`echo $i | cut -f1 -d "." 
#     #Run angsd
#     angsd -i $PATH_BAM/$SAMPLE.hg19.aln.merged.sort.rmdup.uniq.refined.bam -r chrX: -doCounts 1 -iCounts 1 -minMapQ 30 -minQ 20 -out $PATH_RES/$SAMPLE.output

#     #Run contmaination 
#     contamination -a $PATH_RES/$SAMPLE.output.icnts.gz -h $PATH_REF/HapMapChrX.gz 2> $PATH_RES/$SAMPLE.contamination

# done 


#conda deactivate

# TEST
for SAMPLE in *.bam ; do \
    echo $SAMPLE
done 

#TEST 2
for i in *bam ; do  
    SAMPLE=`echo $i | cut -f1 -d "."`
    echo $SAMPLE
done 



######################
########PART 2########
######################

#ASSIGNMENT: Research HapCon and one other method for determining genomic contamination (not just mtDNA).


##Questions for HapCon:

#QUESTION 5: What is the publication associated with HapCon?
#hapCon:estimating contamination of ancient genomes from reference haplotypes Huang and Rangbauer, 2022. https://academic.oup.com/bioinformatics/article/38/15/3768/6607584

#QUESTION 6: Where can the documentation be found?
#Oxford Academy. Bioinformatics 
#https://pypi.org/project/hapROH
#https://haproh.readthedocs.io/en/latest/index.html

#QUESTION 7: What is the input data for this method?
#BAM file or from samtools mpileup or BamTable

#QUESTION 8: In your own words, describe how this method works.
#It estimates contamination of human aDNA data using a haplotype of male X chromosomes. Works better if ancientDNA data is closer to modern human.


#QUESTION 9: Paste the example output data below (if you can find it; otherwise just describe the output data). What does it mean?
#Number of target sites covered by at least one read: 3999
#Method1: Fixing genotyping error rate
#       Estimated genotyping error via flanking region: 0.001502
#       MLE for contamination using BFGS: 0.102113 (0.076802 - 0.127424)



##Questions for your method of choice:

#QUESTION 10: What is the name of and publication associated with this method?
#ContamLD: Estimation of Ancient Nuclear DNA contamination Using Breakdown of Linkage Disequilibrium. Nakatsuka et. al, 2020. https://link.springer.com/article/10.1186/s13059-020-02111-2


#QUESTION 11: What is the input data for this method?
#BAM files

#QUESTION 12: In your own words, describe how this method works.
#

#QUESTION 13: Paste the example output data below (if you can find it; otherwise just describe the output data). What does it mean?


#QUESTION 14: Do you think this method is better to run than ANGSD Contamination or HapCon? Why or why not?

