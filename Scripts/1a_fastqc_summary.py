
# Script to generate fastqc summary table for all fastq files
# using conda environment Sequencing 
import io
import zipfile
import os
import pandas as pd 
import argparse

parser = argparse.ArgumentParser(description='Script to generate fastqc summary table for all fastq files')
# path to fastqc: directory_path = "/dartfs/rc/lab/F/FleskesR/FLESKES/PROJECTS/PipeStudy/1_FASTQ/FASTQC"
parser.add_argument('directory', help='directory where fastqc files are located and where output is sent')
args = parser.parse_args()
directory_path = args.directory


#initialize dataframe rows
df_rows = []
# Iterate through the files in the directory
for filename in os.listdir(directory_path):  
    #look at zip files
    if filename.endswith(".zip"):
        with zipfile.ZipFile(os.path.join(directory_path,filename)) as zf:
            #read fastqc_data.txt within zip files
            with io.TextIOWrapper(zf.open(".".join(filename.split(".")[:-1]) +"/fastqc_data.txt"), encoding="utf-8") as f:
                lines =f.readlines()
                #extract relevant lines
                if len(lines)>=10:
                    extract = lines[3:10]
                    #turn these lines into a row for this sample
                    row = {}
                    for line in extract:
                        row[line.split("\t")[0]] = line.split("\t")[1].rstrip()
                    df_rows.append(row)

# Create a dataframe, with some informative supplementary columns
df = pd.DataFrame(df_rows)
##print(df)
df["Sample Name"] = df["Filename"].apply(lambda x: x.split("-")[0].replace("_","."))
df["Sample ID"] = df["Filename"].apply(lambda x: "-".join(x.split("-")[1:4]).split("_")[0])
##df["R"] =  df["Filename"].apply(lambda x: x.split(".")[0].split("_")[-2][1])
df["Total Sequences"] = df["Total Sequences"].astype(int)
sub_df = df[["Sample Name", "Sample ID", "Total Sequences", "Sequences flagged as poor quality", "Sequence length", "Filename"]].sort_values(by="Total Sequences", ascending=False)
print(sub_df)                
sub_df.to_csv(directory_path +"/full_fastqc_summary.txt", sep="\t", index=False)
