rm(list=ls())
gc()

#### initial time for script start #### 
s = Sys.time()

#### Load libraries ####
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, ggplot2, maps, feather, patchwork, 
               hexbin, rnaturalearth, units, cartogram, sf)

# Select the global sens slope data
slope_data_all <- read_feather("./outputs/PC5_add_sens_slope_stat.feather") %>% 
  # select the lake id, lat, lon, and slope columns
  select(hylak_id, centr_lat, centr_lon, sens.slope) %>%
  # group them
  group_by(hylak_id, centr_lat, centr_lon) %>%
  # summarize - I'm using the median, but it doesn't really matter 
  # because all the sens.slope vales are the same for each hylak_id
  summarize(lake_sens_slope = median(sens.slope)) %>%
  # Change the projection to the weird SF geometry
  st_as_sf(coords = c("centr_lon", "centr_lat"), crs = 4326) %>%
  st_transform("+proj=eqearth +wktext")

# Download the world shapefile
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
area_hexes <- st_join(slope_data_all, grid, join = st_intersects)

# Calculate the median slope among all of the lakes that are in the respective grid bins
area_hexes_avg <- area_hexes %>%
  st_drop_geometry() %>%
  group_by(index) %>%
  mutate(bin_count = n()) %>%
  summarise(lake_sens_slope = median(lake_sens_slope, na.rm = TRUE),
            bin_count = median(bin_count)) %>%
  right_join(grid, by="index") %>%
  st_sf()

# make the global plot
lake_area_change <-
  ggplot() +
  geom_sf(data = world, lwd = 0.5, color = "black")+
  geom_sf(data = area_hexes_avg,lwd = 0.05,
    aes(fill = lake_sens_slope))+
  #geom_sf_text(data = area_hexes_avg, aes(label = bin_count), size = 1.5)+
  scale_fill_gradient2(midpoint=0, low="tan1", mid="white",
                       high="turquoise1", space ="Lab", na.value="black",
                       name = "**Δ Lake Surface Area** <br>Sen's Slope (km/yr)") +
  coord_sf(xlim = c(-15000000, 16000000), ylim = c(-8600000, 8600000), expand = FALSE) +
  guides(fill = guide_colourbar(title.position = "top"))+
  theme_void()+
  theme(legend.position = c(0.11, 0.35),
        legend.direction = "vertical",
        legend.title = ggtext::element_markdown(size = 10),
        legend.text = element_text(size=9),
        legend.key.height  = unit(.5, 'cm'),
        legend.key.width =  unit(.3, 'cm'))

# Save it as a JPEG picture file (THIS IS A REALLY HIGH RESOLUTION) --> almost 50 MB figure
ggsave(lake_area_change, path = ".",
       filename = "./outputs/figures/global_lake_area_sens_slope.jpg",
       width = 14, height = 8, device='jpg', dpi=2000)
