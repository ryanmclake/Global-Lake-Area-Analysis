# Global-Lake-Area-Analysis
-----

:busts_in_silhouette: Ryan McClure, Alli Cramer, Steve Katz

:busts_in_silhouette: Special thanks to: Michael Meyer, Stephanie Hampton, Xiao Yang, Salvatore Virdis, Matthew Brousil

Questions?  :email: rmcclure@carnegiescience.edu

## Motivation

Thank you for checking out the GLCP analysis workflow. Lakes globally are both increasing and decreasing in size as a result of changing climate and human pressure. However, both the magnitude and spatial variation of how waterbody area is changing has been restricted to regional assesments and has not yet been quantified for lakes globally.

We developed a workflow that analyzes the magnitude and direction of lake area change for 1.4+ million lakes globally. We then isolated lakes that were increasing and decreasing in area across four WWF ecoregions and then quantified the importance of drivers. This is a first globally-scaled attempt to partition how lake area is chaning globally and to isolate the most important predictors of that change.

## WORKFLOW ON THE CalTech HPC
1. Login to the CalTech HPC on Terminal and WinSCP
    a. Open terminal
    b. Type ssh “yourname”@login.hpc.caltech.edu
    c. Type your password when asked
    d. When prompted, I select “1”, which sends prompt to DUO
    e. Open DUO on Phone and hit the GREEN checkmark. **This same method is used for WinSCP or Fetch**

2. Getting the newest GLCP data product from Kamiak to CalTech
**NOTE - skip this whole step if you have the newest data product**
Because MFM is still modifying the GLCP on Kamiak, we need to transfer the newest data over to the CalTech Cluster

a. When you have logged into terminal run the following command:

<i>rsync -av --progress “firstname.lastname”@kamiak.wsu.edu:/path/to/data/on/kamiak /central/groups/carnegie_poc/”yourname”/location/you/want/data/to/go</i>

Basically, you’re using rsync to pull data from kamiak to CalTech. You will need your Kamiak and Caltech login credentials ready 
Let this run until completion. I prefer not to do anything else in the terminal until it has finished transferring. This can take upwards of an hour for the whole GLCP_extended.csv depending on your connection. 

Getting the needed packages to process GLCP in R on CalTech HPC
Open terminal
Type: module load gcc/9.2.0
Type: module load R/4.2.2
Type: R
R will now open in terminal
Type: install.packages(“dplyr”,”tidyr”,”vroom”,”readr”,”feather”)
R will ask you where you want to download from, I chose 71.
When finished, type q()
Then type n and hit enter. 
These packages are now installed on your domain in the Caltech Cluster
You will need these for step 5.

Subsetting the GLCP database to include ONLY the columns we are interested in. 
The GLCP_extended is huge and we don’t need all of the columns. As a result, we can use cut command in shell to reduce the file to include only the columns we want.
In Terminal, navigate to your working directory that has the original GLCP_extended.csv data product that you want to use for the analysis.
In that directory, type the following command:

cut -d "," -f1,3,4,5,7,8,11,12,13,15,18,19,31 glcp_extended.csv > glcp_extended_thin.csv

These columns are 1=year, 3=hylak_id, 4=centr_lat, 5=centr_lon, 7=country, 8=bsn_lvl, 11=total_precip_mm, 12=mean_annual_temp_k, 13=pop_sum, 15=permanent_km2, 18=lake_type, 19=lake_area, 31=sub_area
Let this command run through completion without touching anything in the terminal. It will take maybe 15 minutes maximum. 
When this command is completed the GLCP should go from ~200+ GB in size to somewhere in the ballpark of 30-50 GB. 


Extracting the yearly values from the glcp_extended_thin.csv (Finally running SLURM!)
Place this R CODE and SHELL SCRIPT in the directory in the CalTech Cluster that you wish to condense the GLCP_extended_thin.csv from yearly to monthly. 
NOTE - I open WinSCP or Fetch and manually upload these two files onto the Cluster. 
MAKE SURE YOU PROPERLY UPDATE YOUR DIRECTORIES in these two files. Nine times out of ten errors are directory issues. 
Open Terminal again and login to the CalTech Cluster
Navigate to the path where the R CODE and SHELL SCRIPT are located in Terminal
When there, run: sbatch glcp_data_wrangle.sh
Then use squeue -u your.name to get updates on the progress. It will also email you
Depending on how quickly you get your job to start (seconds to days) the run itself should be no more than 2 hours (my latest run was 52 minutes)
When finished, you will get an email that it is completed and there will be an output file named D1_glcp_yearly_slice.csv
Download this file onto your local computer. It should be no more than 4 GB. 


<a href="url"><img src = "GLCP_Workflow.jpeg" align="center" height="400" width="600" ></a>
