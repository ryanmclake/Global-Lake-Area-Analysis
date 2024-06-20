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
library(parallel, warn.conflicts = FALSE)
library(doParallel, warn.conflicts = FALSE)
library(snow, warn.conflicts = FALSE)

file <-  list.files(path = "/central/groups/carnegie_poc/rmcclure/GLCP-2.0/GLCP_2.0_official/Africa_country")
  #imports using 'vroom' 
  #BE SURE TO UPDATE YOUR PATH

slice_glcp <- function(x){

# vroom::vroom(paste0("/central/groups/carnegie_poc/rmcclure/GLCP-2.0/GLCP_2.0_official/",file)) %>%
d <- vroom::vroom(paste0("/central/groups/carnegie_poc/rmcclure/GLCP-2.0/GLCP_2.0_official/Africa_country/", file), col_names = F) 

m <- vroom::vroom("/central/groups/carnegie_poc/rmcclure/GLCP-2.0/basin_matches.csv") |>
  rename(X1 = HYBAS_ID)

d %>%
    left_join(., m, by = "X1") %>%
    group_by(X3, X2, X9, X10, X7) %>%
    #choose what year you want to start from
    
    #filter(year>=1995) %>%
    filter(X2>=2000) %>%
    
    #summarizing observations at each lake by year 
    #slicing the first value by this grouping since it is the same for the whole year
    slice(1) %>%
    #BE SURE TO UPDATE YOUR PATH
    
    write.table(., file = paste0("/central/groups/carnegie_poc/rmcclure/GLCP-2.0/outputs/D1_glcp_yearly_slice.csv"),
                   append = T,
                   row.names = F,
                   col.names = !file.exists("/central/groups/carnegie_poc/rmcclure/GLCP-2.0/outputs/D1_glcp_yearly_slice.csv"))

}

# Windows 
# no_cores <- detectCores() - 2
# cl<-makeCluster(no_cores, type="SOCK")
# system.time(clusterApply(cl, file, slice_glcp(file)))
# stopCluster(cl)

# Apple & Linux
no_cores <- detectCores()
cl <- makeCluster(no_cores, type="FORK")
registerDoParallel(cl)
foreach(x=file) %dopar% slice_glcp(x)

#### Time check ####
e <- Sys.time()
t=e-s
print(t)
