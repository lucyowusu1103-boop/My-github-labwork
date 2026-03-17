#!/bin/bash -l

#######################
########PART 0########
######################
#housekeeping before we start the assignment!!! Keep a clean house!!!

#copy this script into your own USER directory. Type the following into the terminal:
USER="YOURNAME" #replace YOURNAME with your actual foldername
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/ASSIGNMENTS/WEEK3-AdapterRemoval/3_AdapterRemoval_assignment.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/

#then modify the script in your own folder


# we also need to move our 1_FASTQC folder into the Data folder to keep things organized
#our previous scripts had 1_FASTQC in the USERS/${USER} folder, but we want to move it into the Data folder to keep things organized
mv /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/1_FASTQC /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/1_FASTQC



######################
########PART 1########
######################

#for this assigmentment, you will run adapter removal on the raw data files provided in your USER directory "0_RAWDATA".
#these files should have been copied from the shared BioinfoWG directory in WEEK0-SetUp assignment.
#If you have not done so, please go back to WEEK0-SetUp

#we want to first test run the Adapter Removal program on one of your files to makes sure that it works
#to do that, we need to set up an interactive session, which allows us to run programs without submitting a slurm script
#to start an interactive session, use the following command:
srun --pty bash -l

#Then activate the conda environment for Adapter Removal
conda activate Sequencing

#next, create a new directory called "2_FASTQC" in your USER directory to store the output files
#to set your variable, use the following command:
USER="YOURNAME"  #replace YOURNAME with your actual foldername
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval

#now we need to set up a path variable to your raw files
MYFILE="/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/0_RAWDATA/CAL02" #change CAL## to your assigned sample

#it is helpful to cd into that folder so you can see the file names and make sure your path is correct
cd ${MYFILE}
ls #this should show you the files in your raw data folder

#then copy one of the file names and use it to test run Adapter Removal on one of your files using the following command:
AdapterRemoval --file1 ${MYFILE}/CAL02_FGC2096_s_1.R2.fastq.gz --basename CAL02_FGC2096_s_1.R2.fastq --threads 32 --trimns --trimqualities --minlength 30 --gzip

#check to make sure that the output files have been generated in your raw data folder
ls 

#to see them in the explorer tab, put the refresh button in the file explorer window (next to workspace, its a circle arrow)


#now take a look at the settings file to understand what the program did
#either click directly on the file or type code <filename> to open it in the code editor
code CAL02_FGC2096_s_1.R2.fastq.settings


#now for housekeeping, we need to move these files to the 2_AdapterRemoval folder we created earlier
mv *settings* /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval
mv *discarded* /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval
mv *truncated* /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval

#check to make sure the files have been moved
cd  /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval
ls


#Congratulations! You have successfully run Adapter Removal on your first sample!


# to stop the interactive session type the following:
exit

######################
########PART 2########
######################

#now that you have gotten the program to work, you need to understand what each of the options you used in the command line do
#look up the Adapter Removal manual to understand what the --trimns, --trimqualities, --minlength, and --gzip options do!

#open the manual or find the program website (you may need to re-activate your Sequencing conda environment)
AdapterRemoval --help

#find and copy the explanations for each of the options below:

# --file1
#write your answer here: Specifies the path to file to look for adapters in the reads and trim them

# --basename
#write your answer here: Renames output files to avoid mixups

# --threads
#write your answer here: Specifies the number of threads to use for processing the data, which can speed up the analysis by allowing multiple tasks to be performed simultaneously on a multi-core processor.

# --trimns
#write your answer here: Removes any Ns (ambiguous bases) from the ends of the reads, which can improve the quality of the data and downstream analyses.

#--trimqualities
#write your answer here: Trims low-quality bases from the ends of the reads, which can improve the overall quality of the data and downstream analyses.

#--minlength
#write your answer here: Specifies the minimum length of reads to keep after trimming. Reads shorter than this length will be discarded, which can help to remove low-quality or non-informative reads from the dataset.

#--gzip
#write your answer here: Compresses the output files using gzip, which can save storage space and make it easier to transfer the files.


#with this information, do you think that this program is running adapter removal for single end or paired end data?
#hint: paired end data has two files, one for each read, and single end data has one file for each sample. 
#write your answer here: This program is running adapter removal for single end data, as it only specifies one input file with the --file1 option and does not mention a second file for paired end data.

#what are threads? use the internet to find out
#write your answer here: Threads are a way for a program to perform multiple tasks simultaneously by dividing the workload into smaller parts that can be processed in parallel. This can speed up the analysis by allowing multiple tasks to be performed at the same time on a multi-core processor, which can improve the efficiency of the program and reduce the overall processing time.


######################
########PART 3########
######################
#NOW you try it on the rest of the files in your 0_RAWDATA folder by using a SLURM script with a loop!

#copy the 2_AdapterRemoval.sh script from the Raw_Scripts folder into your Scripts folder in your USER directory
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/RAW_Scripts/2_AdapterRemoval.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/

#modify 2_AdapterRemoval.sh script for your own use:
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/  
ls #this should show you the files in your Scripts folder, including the 2_AdapterRemoval.sh script you just copied

#click on the 2_AdapterRemoval.sh script in the explorer window to open it in the code editor and modify the variables and paths for your own use
#Edit the BASE_PATH variables to point to your own USER directory
#once you have modified the script, save and close the file

#cd into your Scripts folder if you are not already there
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/

#now, submit the script to SLURM using the sbatch command
sbatch 2_AdapterRemoval.sh  

#you can check the status of your job using the squeue command (change userid to your ID)
squeue -u userid


#once the job has finished running, check your 2_AdapterRemoval folder for the output files!
#in the folder you ran your script, you'll also see a slurm-<job number>.out file - this gives you output data from the process, good for debugging 


#Congratulations! You have successfully run adapter removal on all your samples!



######################
########PART 4########
######################

#now we need to check that adapter removal did its job by using FASTQC

#to do this, modify your 1_Fastqc.sh script to run FASTQC on the output files from Adapter Removal 
#in your 2_AdapterRemoval folder instead of the raw data files in your 0_RAWDATA folder
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/RAW_Scripts

#make a new copy of the 1_Fastqc.sh script from the raw Scripts folder and modify it to run FASTQC on the output files from Adapter Removal instead of the raw data files in your 0_RAWDATA folder
#this command copies and renames the script in one step
USER="YOURNAME"  #replace YOURNAME with your actual foldername
cp 1_Fastqc.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/2_Fastqc_AdapterRemoval.sh

#make a new directory for your new FASTQC results
USER="YOURNAME"  #replace YOURNAME with your actual foldername
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Data/2_AdapterRemoval/FASTQC

cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/

#things that you will need to edit in the 2_Fastqc_AdapterRemoval.sh script:
# Name of the job (any name)

#specify variables (update with your information)

#specify paths
PATH_READS="${BASE_PATH}/Data/2_AdapterRemoval"
PATH_FASTQC="${BASE_PATH}/Data/2_AdapterRemoval/FASTQC"

#input variable for loop
#for j in *truncated.gz  #this will run fastqc on the truncated files, which are the files that have had adapters removed and are ready for downstream analysis


#when those are edited, save and close the file
#submit the script to SLURM using the sbatch command by first going to the folder

#and then submitting
sbatch 2_Fastqc_AdapterRemoval.sh

#check to see if it is running using the squeue command

#once the job has finished running, check your 2_AdapterRemoval/FASTQC folder for the output files!

#the html file should show the adapters as removed.
