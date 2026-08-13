# Rx_identifier
# Based on the ratio of X chromosome-derived shotgun sequencing data to the autosomal coverage to establish the probability of an XX or XY karyotype for ancient samples.
# Author: Chuan-Chao Wang
# Contact: wang@shh.mpg.de, chuan-chao_wang@hms.harvard.edu; Department of Genetics, Harvard Medical School; Department of Archaeogenetics, Max Planck Institute for the Science of Human History.
# Date: 30 Jan, 2016
# example:samtools view -q 30 -b Ajv52.hs37d5.fa.merged.bam > Ajv52_q30.bam
        # samtools index Ajv52_q30.bam
        # samtools idxstats Ajv52_q30.bam > Ajv52.idxstats
        # Rscript Rx_identifier.r Ajv52 > Ajv52.Rx
		
##Note: edited to match the hg19 reference, which has chrX at line 8 and chrY at line 21 in the idxstats file
#Christina Balentine, April 2024

args=(commandArgs(TRUE))
PREFIX=as.character(args[1])

idxstats<-read.table(paste(PREFIX,'.idxstats',sep=''),header=F,nrows=93,row.names=1)
c1 <- c(as.numeric(idxstats[,1]))
c2 <- c(as.numeric(idxstats[,2]))
total_ref <- sum(c1)
total_map <- sum(c2)
  
LM <- lm(c1~c2)
summary(LM)  
  
Rt1 <- (idxstats[1,2]/total_map)/(idxstats[1,1]/total_ref)
Rt2 <- (idxstats[2,2]/total_map)/(idxstats[2,1]/total_ref)
Rt3 <- (idxstats[3,2]/total_map)/(idxstats[3,1]/total_ref)
Rt4 <- (idxstats[4,2]/total_map)/(idxstats[4,1]/total_ref)
Rt5 <- (idxstats[5,2]/total_map)/(idxstats[5,1]/total_ref)
Rt6 <- (idxstats[6,2]/total_map)/(idxstats[6,1]/total_ref)
Rt7 <- (idxstats[7,2]/total_map)/(idxstats[7,1]/total_ref)
Rt8 <- (idxstats[8,2]/total_map)/(idxstats[8,1]/total_ref)
Rt9 <- (idxstats[9,2]/total_map)/(idxstats[9,1]/total_ref)
Rt10 <- (idxstats[10,2]/total_map)/(idxstats[10,1]/total_ref)
Rt11 <- (idxstats[11,2]/total_map)/(idxstats[11,1]/total_ref)
Rt12 <- (idxstats[12,2]/total_map)/(idxstats[12,1]/total_ref)
Rt13 <- (idxstats[13,2]/total_map)/(idxstats[13,1]/total_ref)
Rt14 <- (idxstats[14,2]/total_map)/(idxstats[14,1]/total_ref)
Rt15 <- (idxstats[15,2]/total_map)/(idxstats[15,1]/total_ref)
Rt16 <- (idxstats[16,2]/total_map)/(idxstats[16,1]/total_ref)
Rt17 <- (idxstats[17,2]/total_map)/(idxstats[17,1]/total_ref)
Rt18 <- (idxstats[18,2]/total_map)/(idxstats[18,1]/total_ref)
Rt19 <- (idxstats[19,2]/total_map)/(idxstats[19,1]/total_ref)
Rt20 <- (idxstats[20,2]/total_map)/(idxstats[20,1]/total_ref)
Rt21 <- (idxstats[21,2]/total_map)/(idxstats[21,1]/total_ref)
Rt22 <- (idxstats[22,2]/total_map)/(idxstats[22,1]/total_ref)
Rt23 <- (idxstats[23,2]/total_map)/(idxstats[23,1]/total_ref)
Rt24 <- (idxstats[24,2]/total_map)/(idxstats[24,1]/total_ref)

#NOTE: for hg19 mapping, the .idxstats file isn't in the expected chr order:
#ChrX is on line 8, so the numerators were changed to Rt8. 
#ChrY is on line 21, so the calculation with Rt21 in the demoninator was removed. 
#And the whole calculation extended to Rt23 and Rt24 to ensure all autosomes are included.
tot <- c(Rt8/Rt1,Rt8/Rt2,Rt8/Rt3,Rt8/Rt4,Rt8/Rt5,Rt8/Rt6,Rt8/Rt7,Rt8/Rt9,Rt8/Rt10,Rt8/Rt11,Rt8/Rt12,Rt8/Rt13,Rt8/Rt14,Rt8/Rt15,Rt8/Rt16,Rt8/Rt17,Rt8/Rt18,Rt8/Rt19,Rt8/Rt20,Rt8/Rt22,Rt8/Rt23,Rt8/Rt24)
Rx <- mean(tot)
cat("Rx :",Rx,"\n")
confinterval <- 1.96*(sd(tot)/sqrt(22))
CI1 <- Rx-confinterval
CI2 <- Rx+confinterval
cat("95% CI :",CI1, CI2,"\n")

if (CI1 > 0.8) {print ("Sex assignment:The sample should be assigned as Female")
} else if (CI2 < 0.6) {print ("Sex assignment:The sample should be assigned as Male")
} else if (CI1 > 0.6 & CI2 > 0.8) {print ("Sex assignment:The sample is consistent with XX but not XY")
} else if (CI1 < 0.6 & CI2 < 0.8) {print ("Sex assignment:The sample is consistent with XY but not XX")
} else print ("Sex assignment:The sample could not be assigned")

print ("***It is important to realize that the assignment is invalid, if there is no correlation between the number of reference reads and that of the mapped reads***")

