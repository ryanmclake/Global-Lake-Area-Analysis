rm(list=ls())
gc()

# script selects lakes which are changing (swelling or shrinking) from the GLCP filtered add sense slope data
  # GLCP filtered add sense slope is the analysis data set with sense slope and p value calculated
  # script: 
     # loads dataset
     # selects lakes which have significant slopes based on P value (sis_sens_slope column is categorical column identifying significant slopes) 
     # exports

# =======================================================================
#------------------------------------------------------------------------

#### initial time for script start #### 
s = Sys.time()

#### Load libraries ####
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, trend, feather, broom)


# Filter only the significant sen's slopes to link with the WWF global Ecoregions

# Pull in DF using feather (its faster)
read_feather("./outputs/PC5_add_sens_slope_stat.feather") %>% 
  dplyr::filter(sens.slope > 0) %>%
  # Filter only the significant sen's slopes (identified in the previous script)
  dplyr::filter(sig_sens_slope == "S") %>%
  # Write it to a new table
write_csv(., path = paste0("./outputs/PC6_filtered_swelling_lakes.csv"))

# Pull in DF using feather (its faster)
read_feather("./outputs/PC5_add_sens_slope_stat.feather") %>% 
  dplyr::filter(sens.slope < 0) %>%
  # Filter only the significant sen's slopes (identified in the previous script)
  dplyr::filter(sig_sens_slope == "S") %>%
  # Write it to a new table
  write_csv(., path = paste0("./outputs/PC6_filtered_shrinking_lakes.csv"))


#### Time check ####
e <- Sys.time()
t=e-s
print(t)
