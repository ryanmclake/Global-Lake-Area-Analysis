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

mutate(pct_change = (Profit/lead(Profit) - 1) * 100)

#### initial time for script start #### 
s = Sys.time()

#### Load libraries ####
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, trend, feather, broom, sf, ggplot2)

d <- read_feather("./outputs/PC4_filter_Ktau_cutoff_lakes.feather")

#### Calculating Senes slope and p value ####
# Quantify the sen's slope (non-parametric)
# Only selecting the hylak_id and total_km2


a <- d %>% filter(hylak_id <= 200000) %>%
  filter(year < 2015) %>%
  dplyr::select(hylak_id, centr_lat, centr_lon, year, mean_annual_temp_k) %>%
  # Grouping by hylak_id
  dplyr::group_by(hylak_id, centr_lat, centr_lon) %>%
  # Z-score lake area
  mutate(mean_annual_temp_k = scale(mean_annual_temp_k) %>% as.vector()) %>%
  
  mutate(pct_change = (Profit/lead(mean_annual_temp_k) - 1) * 100)
  # Run a LM where our predictor is temp and the driver is year
  do(mod = lm(mean_annual_temp_k ~ year, data = ., na.action = na.exclude)) %>%
  # extract the coefficient value for year
  mutate(slope = summary(mod)$coefficients[2],
         r_square = summary(mod)$r.squared) %>%
  # remove the "mod" column as it is a list
  select(-mod)

hist(a$slope, breaks = 1000)


plot(a$year, a$mean-273.15)
  
  


b <- d %>% filter(hylak_id <= 200000) %>%
  dplyr::select(hylak_id, centr_lat, centr_lon, year, mean_annual_temp_k) %>%
  # Grouping by hylak_id
  dplyr::group_by(hylak_id, centr_lat, centr_lon) %>%
  # Z-score lake area
  mutate(mean_annual_temp_k = scale(mean_annual_temp_k) %>% as.vector()) %>%
  # create a column that specifies whether or not the value in the corresponding hylak_id is an outlier
  mutate(outlier = (abs(mean_annual_temp_k - median(mean_annual_temp_k)) > 2*sd(mean_annual_temp_k)) %>% as.vector()) %>%
  # turn those outliers into an NA value
  mutate(mean_annual_temp_k = ifelse(outlier == "TRUE",NA,mean_annual_temp_k)) %>%
  # Run a LM where our predictor is temp and the driver is year
  do(mod = lm(mean_annual_temp_k ~ year, data = ., na.action = na.exclude)) %>%
  # extract the coefficient value for year
  mutate(slope = summary(mod)$coefficients[2]) %>%
  # remove the "mod" column as it is a list
  select(-mod)


c <- d %>% filter(hylak_id <= 200000) %>%
  dplyr::select(hylak_id, centr_lat, centr_lon, mean_annual_temp_k) %>%
  # Grouping by hylak_id
  dplyr::group_by(hylak_id, centr_lat, centr_lon) %>%
  # Z-score lake area
  mutate(mean_annual_temp_k = scale(mean_annual_temp_k) %>% as.vector()) %>%
  # Summarizing and calculating the sens slope from the trend package
  summarise(across(c(1),  ~list(sens.slope(ts(.))))) %>%
  # grop data in hylak_id column
  dplyr::group_by(hylak_id) %>%
  # extract the sen's slope estimate and p.value
  mutate(sens.slope = unlist(purrr::map(mean_annual_temp_k, "estimates")),
         p.value = unlist(purrr::map(mean_annual_temp_k, "p.value"))) %>%
  # remvoe the mean_annual_temp column
  select(-mean_annual_temp_k) %>%
  # get the columns to compare output
  select(hylak_id, centr_lat, centr_lon, sens.slope)


plot(e$slope, e$sens.slope)
abline(a = 0, b = 1, col = "red", lwd = 2)


e <- a %>% st_as_sf(coords = c("centr_lon", "centr_lat"), crs = 4326) %>%
  st_transform("+proj=eqearth +wktext")

e2 <- c %>% st_as_sf(coords = c("centr_lon", "centr_lat"), crs = 4326) %>%
  st_transform("+proj=eqearth +wktext")

e3 <- b %>% st_as_sf(coords = c("centr_lon", "centr_lat"), crs = 4326) %>%
  st_transform("+proj=eqearth +wktext")

# Download the world shapefile
world <-  ne_download(scale = 110, type = 'land', category = 'physical', returnclass = "sf") %>%
  st_transform("+proj=eqearth +wktext")

# make the global plot
lm_slope_temp <-
  ggplot() +
  geom_sf(data = world, lwd = 0.5, color = "black")+
  geom_sf(data = e,
          aes(color = r_square), size = 0.2)+
  #geom_sf_text(data = area_hexes_avg, aes(label = bin_count), size = 1.5)+
  scale_color_gradient2(midpoint=0, low="orange3", mid="white",
                       high="blue3", space ="Lab", na.value="black",
                       name = "**Δ Temperature** <br>Slope using lm() (K/yr)") +
  coord_sf(xlim = c(-15000000, 16000000), ylim = c(-8600000, 8600000), expand = FALSE) +
  labs(title = "    First 200000 lakes from database")+
  guides(fill = guide_colourbar(title.position = "top"))+
  theme_void()+
  theme(legend.position = c(0.11, 0.35),
        legend.direction = "vertical",
        legend.title = ggtext::element_markdown(size = 10),
        legend.text = element_text(size=9),
        legend.key.height  = unit(.5, 'cm'),
        legend.key.width =  unit(.3, 'cm'))

sens_slope_temp <-
  ggplot() +
  geom_sf(data = world, lwd = 0.5, color = "black")+
  geom_sf(data = e2,
          aes(color = sens.slope), size = 0.2)+
  #geom_sf_text(data = area_hexes_avg, aes(label = bin_count), size = 1.5)+
  scale_color_gradient2(midpoint=0, low="orange3", mid="white",
                        high="blue3", space ="Lab", na.value="black",
                        name = "**Δ Temperature** <br>Sen's Slope (K/yr)") +
  coord_sf(xlim = c(-15000000, 16000000), ylim = c(-8600000, 8600000), expand = FALSE) +
  labs(title = "    First 200000 lakes from database")+
  guides(fill = guide_colourbar(title.position = "top"))+
  theme_void()+
  theme(legend.position = c(0.11, 0.35),
        legend.direction = "vertical",
        legend.title = ggtext::element_markdown(size = 10),
        legend.text = element_text(size=9),
        legend.key.height  = unit(.5, 'cm'),
        legend.key.width =  unit(.3, 'cm'))



slope_temp_wo_outliers <-
  ggplot() +
  geom_sf(data = world, lwd = 0.5, color = "black")+
  geom_sf(data = e3,
          aes(color = slope), size = 0.2)+
  #geom_sf_text(data = area_hexes_avg, aes(label = bin_count), size = 1.5)+
  scale_color_gradient2(midpoint=0, low="orange3", mid="white",
                        high="blue3", space ="Lab", na.value="black",
                        name = "**Δ Temperature** <br> Slope using lm() no outliers (K/yr)") +
  coord_sf(xlim = c(-15000000, 16000000), ylim = c(-8600000, 8600000), expand = FALSE) +
  labs(title = "    First 200000 lakes from database")+
  guides(fill = guide_colourbar(title.position = "top"))+
  theme_void()+
  theme(legend.position = c(0.11, 0.35),
        legend.direction = "vertical",
        legend.title = ggtext::element_markdown(size = 10),
        legend.text = element_text(size=9),
        legend.key.height  = unit(.5, 'cm'),
        legend.key.width =  unit(.3, 'cm'))
