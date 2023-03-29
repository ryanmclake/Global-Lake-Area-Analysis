# script selects columns of interest from GLCP 2.0 

# selects columns 
# column numbers correspond with these variables
# 1-year
# 2-hylak_id
# 3-centr_lat
# 4-centr_lon
# 5-country
# 6-bsn_lvl
# 7-total_precip_mm
# 8-mean_annual_temp_k
# 9-pop_sum
# 10-permanent_km2
# 11-lake_area
# 11-lake_type
# 12-sub_area


# calculates yearly median 
# exports

# =======================================================================
#------------------------------------------------------------------------
#### initial time for script start #### 
s = Sys.time()

#### Libraries #### 

library(dplyr, warn.conflicts = FALSE)
library(tidyr, warn.conflicts = FALSE)
library(vroom, warn.conflicts = FALSE)
library(feather, warn.conflicts = FALSE)

  #imports using 'vroom' 
  #BE SURE TO UPDATE YOUR PATH
vroom::vroom("/central/groups/carnegie_poc/rmcclure/glcp-analysis/glcp_extended_thin5.csv") %>%
    group_by(hylak_id, year, centr_lat, centr_lon, country, bsn_lvl, lake_type) %>%
    #choose what year you want to start from
    
    filter(year>=1995) %>%
    #filter(year>=2000) %>%
    
    #summarizing observations at each lake by year 
    #slicing the first value by this grouping since it is the same for the whole year
    slice(1) %>%
    #BE SURE TO UPDATE YOUR PATH
    write_feather(., path = "/central/groups/carnegie_poc/rmcclure/glcp-analysis/output/D1_glcp_yearly_slice.feather")
    

#### Time check ####
e <- Sys.time()
t=e-s
print(t)
