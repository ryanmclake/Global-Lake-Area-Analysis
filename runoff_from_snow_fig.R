### READ GLOBAL SNOW DATA ###

rm(list=ls())
gc()


#### initial time for script start #### 
s = Sys.time()

#### Load libraries ####
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, ggplot2, maps, feather, patchwork, 
               hexbin, rnaturalearth, units, cartogram, sf)

# snow_depth <- readr::read_csv("./inputs/cmc_sdepth_mly_clim_1998to2017_v01.2.txt") %>%
#   sf::st_as_sf(coords = c("LONGITUDE", "LATITUDE"), crs = 4326) %>%
#   sf::st_transform("+proj=eqearth +wktext") %>%
#   select(geometry, JAN)

snow_runoff <- readr::read_csv("./inputs/Fig1_data_plot.csv") %>%
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  sf::st_transform("+proj=eqearth +wktext")

world <-  ne_download(scale = 110, type = 'land', category = 'physical', returnclass = "sf") %>%
  st_transform("+proj=eqearth +wktext")

# Set the grid sizing to overlay on the world data
grid_spacing <- 100000 # CRS units in meters (100000 m = 111 km & 111 km ~ 1 Decimal degree) ??? Not sure of this!!!

# Set up our spatial grid
grid <- st_make_grid(
  world,
  cellsize = c(grid_spacing, grid_spacing),
  #n = c(200, 200), # grid granularity
  crs = st_crs(world),
  what = "polygons",
  flat_topped = T,
  square = F) %>%
  st_intersection(world)

# assign an index column in our grid that will match up with our area hexes (below)
grid <- st_sf(index = 1:length(lengths(grid)), grid)

# Join all of the global slope data with the grid overlay
area_hexes <- st_join(snow_runoff, grid, join = st_intersects)

# Calculate the median slope among all of the lakes that are in the respective grid bins
area_hexes_med <- area_hexes %>%
  st_drop_geometry() %>%
  group_by(index) %>%
  summarise(ratio = median(`grid-ratio`, na.rm = TRUE)) %>%
  right_join(grid, by="index") %>%
  st_sf()



# make the global plot
lake_area_change <-
  ggplot() +
  geom_sf(data = world, lwd = 0.5, color = "black")+
  geom_sf(data = area_hexes_med,lwd = 0.05,
          aes(fill = ratio*100))+
  #geom_sf_text(data = area_hexes_avg, aes(label = bin_count), size = 1.5)+
  scale_fill_gradient(low="orange",
                       high="blue", space ="Lab", na.value="black",
                       name = "**% Watershed Runoff** <br> **From Snow & Ice**") +
  coord_sf(xlim = c(-15000000, 16000000), ylim = c(-8600000, 8600000), expand = FALSE) +
  guides(fill = guide_colourbar(title.position = "top"))+
  theme_void()+
  theme(legend.position = c(0.11, 0.35),
        legend.direction = "vertical",
        legend.title = ggtext::element_markdown(size = 10),
        legend.text = element_text(size=9),
        legend.key.height  = unit(.5, 'cm'),
        legend.key.width =  unit(.3, 'cm'))
