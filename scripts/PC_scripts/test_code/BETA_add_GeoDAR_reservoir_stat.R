rm(list=ls())
gc()

# script pairs lakes with GeoDAR to identify lakes as reservoirs or lakes from the glcp slim kendall cutoff data set
  # glcp slim kendall cutoff is the GLCP 2.0 with only the columns of interest, plus the column of kendal tau of permanent water, and the cutoff column
  #script:
     # selects columns 
     # makes lakes spatial
     # brings in GeoDAR data 
     # pairs with lakes based on distance buffer
     # identifies lakes that are RESERVOIRS or LAKES 
       #makes new column for tagging
     # joins to original data set
     # exports

# =======================================================================
#------------------------------------------------------------------------

#### initial time for script start #### 
s = Sys.time()

# Elegant way to quickly install packages fast
if (!require("pacman")) install.packages("pacman")
pacman::p_load(vroom, dplyr, tidyr, feather, sf, units)

#### Bringing in the data set ####

d <- read_feather("./outputs/PC3_calc_cutoff_ratio_stat.feather")

#making data spatial
d2 <- d %>% 
#selecting columns   
  select(hylak_id, centr_lon, centr_lat) %>%
#making spatial in lat lon
  st_as_sf(coords = c("centr_lon", "centr_lat"), crs = 4326) %>%
#projecting
  st_transform("+proj=eqearth +wktext")

#### Bringing in GeoDAR data ####
dam_data <- vroom::vroom("./inputs/GeoDAR_v11_dams_beta_pr1.csv", delim = ",", col_names = T) %>%
#selecting lat lon
  select(longitude, latitude) %>%
#making spatial in lat lon
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
#projecting
  st_transform("+proj=eqearth +wktext")

#### Pairing reservoirs to our lakes ####
dam_glcp_link <- d2 %>%
#binding the reservoirs to our lakes (d2) with the nearest geometry 
  cbind(dam_data[st_nearest_feature(d2, dam_data),]) %>%
#calculating distance between the nearest reservoir and the nearest lake
  mutate(dist = st_distance(geometry, geometry.1, by_element = T))

#cleaning data for subsequent actions
   # units are in meters --> Removing the units so we can work with the column in the left_join function
dam_glcp_link$dist <- drop_units(dam_glcp_link$dist)

#removing the spatial object so it is just a data frame
dams_to_remove <- dam_glcp_link %>% 
  st_drop_geometry() %>%
  select(-geometry.1) %>% unique()

#### Identifying RESERVOIRS or LAKES ####
left_join(d, dams_to_remove, by = "hylak_id") %>%
#adding tagging column for RESERVOIRS or LAKES
  mutate(water_body_type = ifelse(dist <= 5000, "RESERVOIR", "LAKE")) %>%
#removing dist column
  select(-dist) %>% 
#exporting
  write_feather(., path = paste0("./outputs/PC4_add_GeoDAR_reservoir_stat.feather"))

#### Time check ####
e <- Sys.time()
t=e-s
print(t)
