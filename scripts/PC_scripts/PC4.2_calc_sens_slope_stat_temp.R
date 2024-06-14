rm(list=ls())
gc()

# script calculates sens slope and p value for lake change, based on the GLCP_glim_kendall_cutoff_reservoir_filtered dataset
# glcp slim Kendall cutoff reservoir filtered is the GLCP 2.0 with only the columns of interest, and the spurious lakes based on kendall tau, size, and reservoir status removed
# script: 
# loads data set
# selects lake id and total km surface area columns
# calculates sens slope and p values
# joins with original data set 
# exports

# =======================================================================
#------------------------------------------------------------------------

#### initial time for script start #### 
s = Sys.time()

#### Load libraries ####
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, trend, feather, broom)

#### Bringing in the data set ####
# Load in the data set that has all of the spurious lakes and reservoirs removed
d <- read_feather("./outputs/PC4_filter_Ktau_cutoff_lakes.feather")

#### Calculating Senes slope and p value ####
# Quantify the sen's slope (non-parametric)
# Only selecting the hylak_id and total_km2
k <- d %>% 
  dplyr::select(hylak_id, mean_annual_temp_k) %>%
  # Grouping by hylak_id
  dplyr::group_by(hylak_id) %>%
  # Z-score lake area
  mutate(mean_annual_temp_k = scale(mean_annual_temp_k)) %>%
  # Summarizing and calculating the sens slope from the trend package
  summarise(across(c(1),  ~list(sens.slope(ts(.))))) %>%
  dplyr::group_by(hylak_id) %>%
  mutate(sens.slope = unlist(purrr::map(mean_annual_temp_k, "estimates")),
         p.value = unlist(purrr::map(mean_annual_temp_k, "p.value"))) %>%
  select(-mean_annual_temp_k) %>%
  select(hylak_id, p.value, sens.slope)

#### Joining and exporting ####
# Join with the original DF and make a new column that specifies what sens slopes
# are significant. These significant slopes will be filtered in the next script
left_join(d, k, by = "hylak_id") %>%
  mutate(sig_sens_slope = ifelse(p.value < 0.0500000, "S", "NS")) %>%
  write_feather(., path = paste0("./outputs/PC5.2_add_sens_slope_stat_temp.feather"))

#### Time check ####
e <- Sys.time()
t=e-s
print(t)