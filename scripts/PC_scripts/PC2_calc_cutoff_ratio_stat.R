rm(list=ls())
gc()

# script calculates area ratio cut off on GLCP slim kendall data set 
  # glcp slim kendall is the GLCP 2.0 with only the columns of interest, plus the column of kendal tau of permanent water 
  #script:
     # selects columns 
     # calculates area ratio
       #area ratio is the log of the lake area (the original polygon shapefile area) to the basin area (the hydrosheds basin the lake was assigned to)
     # identifies ratios that are below cutoff
        # the 'cutoff' is the lower 0.05 quantile for each basin level. 
     # if ratio is below or equal to cutoff lake is labeled 'REMOVE', if above cutoff it is labeled 'KEEP'
     # joins to original data set
     # exports

# =======================================================================
#------------------------------------------------------------------------

#### initial time for script start #### 
s = Sys.time()

# Elegant way to quickly install packages fast
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, tidyr, Kendall, feather, broom)

#### Bringing in the data set ####

d <- read_feather("./outputs/PC2_calc_kendall_tau_stat.feather")

#### Calculating and labeling area cutoff #####

k <- d %>% 
#selecting columns
  select(hylak_id, bsn_lvl, lake_area, sub_area) %>%
#grouping by columns for calculation
  group_by(hylak_id, bsn_lvl) %>%
#calculating ratio
  mutate(log_ratio = log(lake_area/sub_area)) %>%
#ungrouping for new calculation
  ungroup(.) %>%
#grouping to calculate quantiles
  group_by(bsn_lvl) %>%
#calculating quantiles of the ratio for each basin level
  mutate(q05 = quantile(log_ratio, 0.05, na.rm = T)) %>%
#creating the cutoff column, labelling lakes as 'KEEP' or 'REMOVE'
  mutate(area_cutoff = ifelse(log_ratio > q05, "KEEP", "REMOVE")) %>%
#ungrouping for new calculations
  ungroup(.) %>%
#selecting columns of interest
  select(hylak_id, area_cutoff) %>% 
#removing duplicate values 
  unique()

#### Joining and exporting ####
#join
left_join(d, k, by = "hylak_id") %>%
#export
  write_feather(., path = paste0("./outputs/PC3_calc_cutoff_ratio_stat.feather"))

#### Time check ####
e <- Sys.time()
t=e-s
print(t)
