##Here are some examples of for-loops
#For-loops repeat a block of code a set number of times or through a list of items.

#The basic structure is:
#for {variable, like i} in {file designation} ; do \
    #code here that you want repeated for the different variables -- make sure this is indented; it is easier to read and helps the computer work properly
#done (make sure you close your for-loop with "done" without being tabbed in)

####EXAMPLES####
##Say we have a directory with files Sample1.txt Sample2.txt and Sample3.txt
USER="Abby" #replace YOURNAME with your actual foldername
mkdir /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/For_Loop_Examples
cd /dartfs/rc/lab/F/FleskesR/BioinfoWG/USERS/${USER}/Scripts/For_Loop_Examples
#Make your text files to test these loops on (notice how we're using a different text file command, instead of "code" or "nano")
touch Sample{1..3}.txt
#What does {1..3} mean?


##Example 1: You want to loop over all files that end in "txt" within this file and list only their names without the "txt"
for i in *.txt ; do 
    f=`echo $i | cut -f1 -d "."`
    echo $f 
done 
#Line 1 sets up the variable i being all of the *.txt files within this directory
#Line 2 creates another variable, f, that is taking the i variable and cutting only the first field with the deliminator "."
#Line 3, "echo" means simply "print the variable f in the terminal"
#Line 4 closes the for-loop


##Example 2: You want to loop over only select files, say just Sample1 and Sample3
for i in Sample1 Sample3 ; do 
    echo $i 
done 
#Line 1: This time, we directly give the sample names that we want to the variable, so $i is now Sample1 then Sample3
#Line 2: Since we're still only wanting to list the sample names for our script, we just print the variable i instead of having to make another variable f
#Line 3: Again, we close the loop

##Example 3: Another way to loop over all .txt files, like Example 1
for j in *.txt
do
    echo ${j%.*}
done
#Line 1 sets up the variable j (notice how you can use any letter for the variable; commonly i, j, f are used)
#Line 2 this time, "do" is on its own line and doesn't need to be indented
#Line 3 prints the sample names to the terminal. The ${j%.*} variable tells the computer to print everything until the first period, 
#so using the "cut" variable in Example 1 isn't needed. The period could be replaced with an underscore if your files were named differently
#Line 4 and we close the loop

#Notice also how the variable is inside curly brackets {} after the $ instead of standing on it's own. 
#This way is a bit cleaner, so if you're having issues with your variables being simply $i, try putting the i within curly brackets.

#Lots of ways to bake a cake!