rm(list=ls())
gc()

# script calculates kendall tau on GLCP sliced data set 
  # glcp sliced is the GLCP 2.0 with only the columns of interest
  #script:
     # selects columns 
     # calculates kendall tau
     # joins to original data set
     # exports

# =======================================================================
#------------------------------------------------------------------------
#### initial time for script start #### 

s = Sys.time()

# Elegant way to quickly install packages without having to incrementally run install.packages()
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, tidyr, Kendall, readr, broom, feather)

#### Bringing in 'glcp slim' data set ####
<<<<<<< HEAD
d <- read.csv("/Users/ryanmcclure/Documents/Global-Lake-Area-Analysis/D1_glcp_yearly_slice.csv", sep = " ")
=======
d <- read_csv("./outputs/D1_glcp_yearly_mean.csv")
>>>>>>> 26b0469682a6f3bdb94335d5bba390861bde1bdc

#### Calculating Kendall tau for each lake ####

k <- d %>% 
#selecting columns
  select(Hylak_id, permanent_km2) %>%
  group_by(Hylak_id) %>%
  summarise(across(c(1),  ~list(MannKendall(.) %>%
                                  tidy %>%
                                  select(p.value, statistic)))) %>%
#unnest so p.value and kendall tau statistic are separate columns
  ungroup(.) %>%
  unnest(c(2), names_repair = "minimal") %>%
#rename 'statistic' to 'kendall_tau'
  rename(kendall_tau = statistic) %>%
#remove 'p.value' column
  select(-p.value)

#### Joining and exporting ####
#join
left_join(d, k, by = "Hylak_id") %>%
#export
  write_feather(., path = paste0("/Users/ryanmcclure/Documents/Global-Lake-Area-Analysis/outputs/PC2_calc_kendall_tau_stat.feather"))

#### Time check ####
e <- Sys.time()
t=e-s
print(t)
