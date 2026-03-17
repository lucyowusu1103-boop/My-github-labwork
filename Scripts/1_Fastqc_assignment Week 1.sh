#!/bin/bash -l

######################
########PART 1########
######################

#for this assigmentment, you will run FastQC on the raw data files provided in your USER directory "0_RAWDATA".
#these files should have been copied from the shared BioinfoWG directory in WEEK0-SetUp assignment.
#If you have not done so, please go back to WEEK0-SetUp and complete that assignment first.

#first, activate the conda environment for FastQC
conda activate fastqc

#next, create a new directory called "1_FASTQC" in your USER directory to store the FastQC output files
#here, we are going to use a variable $USER to automatically get your username
#to set your variable, use the following command:
USER="YOURNAME"  #replace YOURNAME with your actual foldername
mkdir -p /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/$USER/1_FASTQC

#We are going to test run the FASTQC program on one of your files to makes sure that it works
#to do that, we need to set up an interactive session, which allows us to run programs without submitting a slurm script
#to start an interactive session, use the following command:
srun --pty bash -l

#this will take a few moments to start up, once you see a new prompt, you are in an interactive session - it should look something like this:
#(fastqc) [f0073h8@slurm-fe01-prd FleskesR]$ srun --pty /bin/bash
#(fastqc) [f0073h8@s43 FleskesR]$ 


#now, run FastQC on all the following data file in your "0_RAWDATA" folder using a file variable
#copy the following directing into the terminal

#you may need to activate the conda environment for FastQC in the interactive session too
#if it says (base) before your NetID rather than (fastqc)
conda activate fastqc

USER="YOURNAME"  #replace YOURNAME with your actual foldername
MYFILE="/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/$USER/Data/0_RAWDATA/CAL05" #change CAL## to your assigned sample

fastqc -t 32 -q ${MYFILE}/CAL05_FGC2096_s_1.R1.fastq.gz -o /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/$USER/1_FASTQC/ #change CAL01_FGC2096_s_1.R1.fastq.gz to the name of one of the files in your 0_RAWDATA directory

# to stop the interactive session type the following:
exit


#look up the fastqc manual to understand what the -t and -q options do!
#https://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/
#-o specifies the output directory
#-t specifies the number of threads to use
#-q runs FastQC in quiet mode, suppressing all output except for errors
#make sure to check your 1_FASTQC folder for the output files once the command has finished running!

#click on the .html files to view the FastQC reports in your web browser.
#you can do that by right clicking on the file in the file explorer and selecting either download or open with default application

#Congratulations! You have successfully run FastQC on your first sample!

######################
########PART 2########
######################
#NOW you try it on the rest of the files in your 0_RAWDATA folder by using a SLURM script with a loop!
#this script will also run summary stats for your FastQC results using a python script.
#This will allow you to run FastQC on all the files in your 0_RAWDATA, rather than one at a time.


#copy the 1_Fastqc.sh and 1a_fastqc_summary.py scripts from the WEEK1-Fastqc assignment folder into your Scripts folder in your USER directory
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/ASSIGNMENTS/WEEK1-Fastqc/1_Fastqc.sh /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/$USER/Scripts/
cp /dartfs/rc/lab/F/FleskesR/BioinfoWG/ASSIGNMENTS/WEEK1-Fastqc/1a_fastqc_summary.py /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/$USER/Scripts/

#modify the 1_Fastqc.sh script for your own use:
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/$USER/Scripts/
code 1_Fastqc.sh

#Edit the Name of the job - you can change WG_FAST to your own name if you like:
#SBATCH --job-name=WG_FAST

#the rest of the SLURM parameters can stay the same for this assignment

#Edit the BASE_PATH variables in the 1_Fastqc.sh to point to your own USER directory
#you can check your path using the pwd command in the terminal if this helps
pwd
#it should look something like the following line (replace $USER with your actual foldername):
BASE_PATH=/dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/$USER

#once you have modified the script, save and close the file


#cd into your Scripts folder if you are not already there
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/$USER/Scripts/

#now, submit the script to SLURM using the sbatch command
sbatch 1_Fastqc.sh   

#you can check the status of your job using the squeue command
USER="YourNetIDHere"
squeue -u $USER


#once the job has finished running, check your 1_FASTQC folder for the output files!
#click on the .html files to view the FastQC reports in your web browser
#the .txt gives a summary for all samples
#in the folder you ran your script, you'll also see a slurm-<job number>.out file - this gives you output data from the process, good for debugging 
#Congratulations! You have successfully run FastQC on all your samples!


