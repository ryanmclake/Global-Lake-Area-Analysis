rm(list=ls())
gc()

# script removes lakes based on their kendall tau, area cutoff, and reservoir tag from the GCLP slim kendall cutoff reservoir data set
  # glcp slim kendall cutoff reservoir is the GLCP 2.0 with only the columns of interest, plus the column of kendal tau of permanent water, cutoff, and reservoir tag
  #script:
     # imports data
     # selects lakes with Kendall Tau's of less than 1 
     # selects lakes above the lake area/basin area cutoff
     # exports

# =======================================================================
#------------------------------------------------------------------------

#### initial time for script start #### 
s = Sys.time()

# Elegant way to quickly install packages fast
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, tidyr, feather)

#### Bringing in and filtering data ####
#import
read_feather("./outputs/PC3_calc_cutoff_ratio_stat.feather") %>%
#select lakes with kendall tau < 1
  filter(kendall_tau < 1) %>%
#select lakes above area cutoff
  filter(area_cutoff == "KEEP") %>%
#select lakes tagged as LAKE
  filter(lake_type == 1) %>%
  write_feather(., path = paste0("./outputs/PC4_filter_Ktau_cutoff_lakes.feather"))

#### Time check ####
e <- Sys.time()
t=e-s
print(t)
