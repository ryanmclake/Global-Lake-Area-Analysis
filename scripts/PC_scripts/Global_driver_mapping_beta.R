if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, ggplot2, maps, feather, patchwork, readr,
               hexbin, rnaturalearth, units, cartogram, sf, Ternary, tidyr)

source("/Users/ryanmcclure/Documents/tricolore/R/tricolore.R")
source("/Users/ryanmcclure/Documents/GLEE2/ggtern/R/ggtern-constructor.R")
source("/Users/ryanmcclure/Documents/GLEE2/ggtern/R/coord-tern.R")
source("/Users/ryanmcclure/Documents/GLEE2/ggtern/R/utilities.R")
source("/Users/ryanmcclure/Documents/GLEE2/ggtern/R/geom-mask.R")
source("/Users/ryanmcclure/Documents/GLEE2/ggtern/R/scales-tern.R")
source("/Users/ryanmcclure/Documents/GLEE2/ggtern/R/calc-tern-tlr2xy.R")
source("/Users/ryanmcclure/Documents/GLEE2/ggtern/R/annotation-raster-tern.R")


clim <- read_csv("/Users/ryanmcclure/Documents/Global-Lake-Area-Analysis/outputs/model_output/climate.pts.shrink.csv",
                 col_select = c(2,6,7)) %>%
  rename(hylak_id = Lake.ID) %>%
  mutate(driver = "CLIMATE")

both <- read_csv("/Users/ryanmcclure/Documents/Global-Lake-Area-Analysis/outputs/model_output/both.pts.shrink.csv",
                 col_select = c(2,6,7)) %>%
  rename(hylak_id = Lake.ID) %>%
  mutate(driver = "BOTH")

pop <- read_csv("/Users/ryanmcclure/Documents/Global-Lake-Area-Analysis/outputs/model_output/populatipon.pts.shrink.csv",
                 col_select = c(2,6,7)) %>%
  rename(hylak_id = Lake.ID) %>%
  mutate(driver = "POPULATION")

drivers <- rbind(clim, both, pop) %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) %>%
  st_transform("+proj=eqearth +wktext")

# Download the world shapefile
world <-  ne_download(scale = 110, type = 'land', category = 'physical', returnclass = "sf") %>%
  st_transform("+proj=eqearth +wktext")

# Set the grid sizing to overlay on the world data
grid_spacing <- 300000 # CRS units in meters (100000 m = 111 km & 111 km ~ 1 Decimal degree) ??? Not sure of this!!!

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
driver_hexes <- st_join(drivers, grid, join = st_intersects)

# Calculate the median slope among all of the lakes that are in the respective grid bins
driver_hexes_proportion <- driver_hexes %>%
  st_drop_geometry() %>%
  group_by(index, driver) %>%
  summarise(n = n()) %>%
  mutate(freq = n / sum(n),
         freq = freq)%>%
  ungroup() %>%
  group_by(index) %>%
  mutate(lake_count = sum(n)) %>%
  select(-n) %>%
  pivot_wider(names_from = driver, values_from = freq) %>%
  mutate(CLIMATE = as.numeric(ifelse(is.na(CLIMATE),0,CLIMATE)),
         POPULATION = as.numeric(ifelse(is.na(POPULATION),0,POPULATION)),
         BOTH = as.numeric(ifelse(is.na(BOTH),0,BOTH))) 

driver_hexes_proportion_map <- driver_hexes_proportion %>% 
  dplyr::right_join(grid, by="index") %>%
  st_sf()

library(assertthat)

P <- as.data.frame(prop.table(matrix(runif(3^6), ncol = 3), 1))

P <- as.data.frame(driver_hexes_proportion[3:5])

driver_hexes_proportion_colors <- Tricolore(P,
                       p1 = 'CLIMATE', p2 = 'POPULATION', p3 = 'BOTH',
                       breaks = Inf)

driver_hexes_proportion_colors$key

driver_hexes_proportion$rgb <- as.data.frame(driver_hexes_proportion_colors$rgb)

driver_hexes_proportion_map <- driver_hexes_proportion %>% 
  dplyr::right_join(grid, by="index") %>%
  st_sf()

driver_hexes_proportion_colors$rgb
# make the global plot
lake_area_drivers <-
  ggplot() +
  geom_sf(data = world, lwd = 0.5, color = "black")+
  geom_sf(data = driver_hexes_proportion_map,lwd = 0.05,
          aes(fill = rgb$`driver_hexes_proportion_colors$rgb`))+
  scale_fill_identity()

data <- driver_hexes_proportion_colors$key$data

TernaryPlot(alab = "POPULATION \u2192", blab = "\u2190 BOTH", clab = "CLIMATE \u2192",
            lab.col = c("#FF80F7", "#00D1D0", "#CFB000"),
            main = "Drivers", # Title
            point = "right", lab.cex = 0.8, grid.minor.lines = 0,
            grid.lty = "solid", col = rgb(0.9, 0.9, 0.9), grid.col = "white", 
            axis.col = rgb(0.6, 0.6, 0.6), ticks.col = rgb(0.6, 0.6, 0.6),
            axis.rotate = FALSE,
            padding = 0.08)
# Colour the background:

ramp <- colorRamp(c("#FF80F7", "#00D1D0", "#CFB000"))
rgb( ramp(seq(0, 1, length = 1000)), max = 255)
cols <- TernaryPointValues(rgb(ramp(seq(0, 1, length = 1000)), max = 255))
ColourTernary(cols, spectrum = NULL)

lake_area_drivers +
  annotation_custom(
    ggplotGrob(driver_hexes_proportion_colors$key),
    xmin = 55e5, xmax = 75e5, ymin = 8e5, ymax = 80e5
  )
  

geom_sf_text(data = driver_hexes_proportion, aes(label = lake_count), size = 1.5)+
  scale_fill_gradient2(midpoint=50, low="red", mid="darkgreen",
                       high="blue", space ="Lab", na.value="black",
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
