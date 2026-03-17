#!/bin/bash -l

#######################
########PART 0########
#######################

# copy this script into your own USER directory. Type the following into the terminal:
USER="Lucy"
cp /dartfs-hpc/rc/home/5/f008715/FleskesR/BioinfoWG/ASSIGNMENTS/WEEK4-Trimmomatic/4_Trimmomatic_assignment.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy/Scripts/

# then modify the script in your own folder


######################
########PART 1########
######################

# for this assignment, you will use your FASTQC results to identify samples that did NOT pass because they still had low levels of adapters present.
# those are the only files you should trim with Trimmomatic.

# first, start an interactive session:
srun --pty bash -l

# activate the sequencing environment
conda activate Sequencing

# set your USER variable
USER="Lucy"  

# you are going to work within the 2_AdapterRemoval folder for this assignment
# inside this directory, make two new folders:
# FINISHED = trimmed files that are done
# NOT_FINISHED = files that still need trimming
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/NOT_FINISHED

# now look at your previous FASTQC results and identify which raw data files still had adapter contamination
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FASTQC
ls

# open the html reports and identify the samples that still show adapter content
# once you identify those samples, copy those files into the NOT_FINISHED folder
# example:
mv /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/AdapterROutput/CAL03_FGC2099_s_2_CGGCTATG-CCTATCCT* /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/NOT_FINISHED/.

# repeat for all raw files that still need trimming


# now go into the NOT_FINISHED folder and test run Trimmomatic on one file
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/NOT_FINISHED
ls

cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED
ls

# run Trimmomatic on one of the files

AdaptRem_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval
Adapters_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/Programs/Trimmomatic_Adapters/

trimmomatic SE -threads 16 $AdaptRem_PATH/CAL03_FGC2096_s_1.R1.trimmed2.fastq.gz $AdaptRem_PATH/CAL03_FGC2099_s_2_CGGCTATG-CCTATCCT.trimmed.fastq.gz ILLUMINACLIP:$Adapters_PATH/TruSeq2-SE.fa:2:30:10 SLIDINGWINDOW:4:20 MINLEN:30

#Running command for PE R1 file
trimmomatic SE -threads 16 $AdaptRem_PATH/FINISHED/CAL03_FGC2096_s_1.R1.trimmed2.fastq.gz $AdaptRem_PATH/FINISHED/CAL03_FGC2096_s_1.R1.trimmed3.fastq.gz ILLUMINACLIP:$Adapters_PATH/TruSeq3-SE.fa:2:30:10 SLIDINGWINDOW:4:20 MINLEN:30


#use the manual for Trimmomatic to understand the parameters you used in the command above. You can access the manual by typing:
trimmomatic -h

#what is the input file?
#CAL03_FGC2096_s_1.R1.trimmed2.fastq.gz

#what is the output file? 
#CAL03_FGC2096_s_1.R1.trimmed3.fastq.gz
#what does ILLUMINACLIP do?
#The ILLUMINACLIP parameter is used to specify the adapter sequences that should be removed from the reads. It takes three arguments:
# the path to the adapter file, the seed mismatches, and the palindrome clip threshold.
# The adapter file contains the sequences of the adapters that were used during library preparation.
# The seed mismatches parameter specifies how many mismatches are allowed in the seed sequence when matching the adapter. 
#The palindrome clip threshold is used to determine when to clip a read based on the presence of a palindrome sequence that matches the adapter.

#what does SLIDINGWINDOW do?
#The SLIDINGWINDOW parameter is used to perform quality trimming on the reads. It takes two arguments: the window size and the required quality.
# The window size specifies how many bases to include in the sliding window, and 
# the required quality specifies the minimum average quality score that must be met within the window for the read to be retained. 
# If the average quality score within the window falls below the specified threshold, the read will be trimmed at that point and any subsequent bases will be removed.

#what does MINLEN do?
# The MINLEN parameter is used to specify the minimum length that a read must have after trimming to be retained. Reads that are shorter than this length will be discarded.

# based on this command, is this single-end or paired-end trimming?
# write your answer here: single-end trimming, because we are using the SE option in the command, which stands for single-end. 
# If we were doing paired-end trimming, we would use the PE option and provide both the forward and reverse read files as input.

# what is the purpose of adapter trimming in sequence data?
# write your answer here: The purpose of adapter trimming in sequence data is to remove adapter sequences that may be present in the reads. 
# Adapter sequences are short DNA sequences that are ligated to the ends of DNA fragments during library preparation for sequencing.
# If these adapter sequences are not removed from the reads, they can interfere with downstream analyses such as read mapping and variant calling, leading to inaccurate results. 
# Trimming adapters helps to improve the quality of the data and ensures that only high-quality, biologically relevant sequences are retained for analysis.




# check that your trimmed file has been created in the FINISHED folder
mv /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/NOT_FINISHED/CAL03_FGC2096_s_1.R2.trimmed2.fastq.gz /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED/.
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED
ls

# Check that the trimmed file has been created in the FINISHED folder
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED
ls

#now repeat this for the remaining files in the NOT_FINISHED folder. You can copy and modify the code above. 
#There are two ways to do this
#spagetti code: copy and modify the command for each file, which is not very efficient but is straightforward
#loop code: write a loop that will run the command for each file in the NOT_FINISHED folder, which is more efficient but requires more coding skills.




# to stop the interactive session type:
exit



######################
########PART 2########
######################
# now we need to check whether trimming fixed the adapter problem by running FASTQC again

# go to the raw scripts folder
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy/Scripts

# make a new copy of the FASTQC script and rename it for this assignment
USER="Lucy"  
cp 1_LucyFastqc.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy/Scripts/3_Fastqc_Trimmomatic.sh

# make a folder to store the new FASTQC results
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FASTQC_Trimmomatic

# now go into your Scripts folder
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy/Scripts/

# edit 3_Fastqc_Trimmomatic.sh

# things you will need to edit in the script:
# name of job

# BASE_PATH
# PATH_READS="${BASE_PATH}/Data/2_Trimmomatic/FINISHED"
# PATH_FASTQC="${BASE_PATH}/Data/2_Trimmomatic/FASTQC"

# loop input:
# for j in *.trimmed.fastq.gz

#remove the python statistics portion

# save and close the file, then submit it
sbatch 3_Fastqc_Trimmomatic.sh

# check if it is running
squeue -u userid

# once the job has finished, check your FASTQC folder
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FASTQC_Trimmomatic
ls

# open the html files and inspect the adapter content section
# the trimmed files should now show reduced or removed adapter contamination

#if it does not, then we will need to explore other trimming parameters or tools, but for now, we will move on to the next step of the workflow.
mv /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED/CAL03_FGC2096_s_1.R1.trimmed2.fastq.gz /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/NOT_FINISHED
mv /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/AdapterROutput/CAL03* /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED

mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED/{settings,discarded}
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy/Data/2_AdapterRemoval/FINISHED/*.settings /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED/settings
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/Lucy/Data/2_AdapterRemoval/FINISHED/*.discarded.gz /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED/discarded

#Go back to the FINISHED folder 
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FINISHED
rm *.settings
rm *.discarded.gz