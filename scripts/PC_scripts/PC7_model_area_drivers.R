
rm(list=ls())
gc()

# Go to where the data are

library(imputeTS)
library(MASS)
library(leaps)
library(cluster)
library("MuMIn")
library(feather)

#  Import test data of made up lake data
# There are three groups of 4, 4 & 3 for a total of 13 lakes.
# In each case there is a variable called Area and then Var1, Var2 and so on.


Lake.SS <- read_feather("./outputs/PC6_filtered_sens_slopes.feather") 

#head(Lake.SS, 21)

#attach(Lake.SS)

#plot(pop_sum~year)

# Now interpolate the population as a linear fit between censuses.

Lake.SS$pop.adj <- na_interpolation(pop_sum, option = "linear")

#head(Lake.SS$pop.adj, 5)		# Make sure it added a column that is the interpolated data

# Now check in the interpolated data looks correct.

#plot(Lake.SS$pop.adj~Lake.SS$year, pch=19, col="black")	# The real data in black
#points(Lake.SS$pop_sum~Lake.SS$year, pch=19, col="green")	# The interpolated data in green

Lake.tiny <- Lake.SS[c('hylak_id','year','permanent_km2','total_precip_mm','mean_annual_temp_k','pop.adj')]

#head(Lake.tiny)


options(na.action = "na.fail")
##  Get the best model topology

lakes.t <- unique(Lake.tiny$hylak_id)	# Make a list of lakes to call one at a time
lakes.t.n <- length(lakes.t)			# How many motherfucking lakes in the motherfucking dataset?
class.lat <- unique(Lake.SS$centr_lat)	# Make a list of longitudes for later plotting
class.lon <- unique(Lake.SS$centr_lon)	# Make a list of latitudes for later plotting


# i <- 3000										# Test index so I can trouble shoot the for loop with one lake at a time.
# make space for results
lake.t.class = array()

#### initial time for script start #### 
s = Sys.time()

# Run loop over lakes
for (i in 1:lakes.t.n){
  topology <- array()
  data.1 <- Lake.tiny[Lake.tiny$hylak_id==lakes.t[i],]			# Pull the data out for lake in queue
  data.2 <- data.1[,3:6]
  data.2 <- as.data.frame(scale(data.2))				# Z-score the data - can comment this out if you want the actual data
  data.2[is.na(data.2)] <- 0						#get rid of NA's that are generated with scaling a vector with zero variance
  fm1 <- lm(permanent_km2 ~ 0+., data = data.2)			# Define the complete linear model statement with no intercept
  dd <- dredge(fm1)								# Dredge for the best model
  best.model <- get.models(dd, 1)[[1]]				# Select the best model
  
  coeff.1 <- names(best.model$coefficients)				# Pull the variables out of the best model and build the answer of rthis lake in the loop
  topology[1] <- "total_precip_mm" %in% coeff.1
  topology[2] <- "mean_annual_temp_k" %in% coeff.1
  topology[3] <- "pop_sum" %in% coeff.1
  
  
  Lake.id.t <- lakes.t[i]							# Keep it straight what lake you're working on
  topology.result <- c(Lake.id.t, as.numeric(topology))		# This creates a list element with the lake ID and the topology
  lake.t.class <- rbind(lake.t.class,topology.result)			# This adds the result from this lake to the accummulating list of lakes.
}										# End of loop


#### Time check ####
e <- Sys.time()
t=e-s
print(t)


# Edit out some junk from the matrix lake.class
lake.t.class <- lake.t.class[-1,]
class.t.1 <- lake.t.class[,2:4]

row.names(class.t.1) <- lakes.t
colnames(class.t.1) <- c("Precip","Temp.","Population")
class.t.1										# Look at it

df3 <- class.t.1
df3 <- data.frame(data.matrix(matrix(as.numeric(class.t.1), ncol = 3)))  # Stuff comes out as text, this converts it to numeric values so we can do the clustering.


distance.1 <- dist(df3, method="binary")					  # Makes a distance matrix
cluster.1 <- hclust(distance.1)						          # Uses the distance matrix to make a cluster object
# plot(cluster.1)									                  # This plots the Dendrogram, but quiet for now.
groups.1 <- cutree(cluster.1, k = 8)					      # This creates an array with which group (# of groups = k) the lakes are in.  I think this is what we want.
rect.hclust(cluster.1, k = 8)							          # This plots the Dendrogram, but with colored boxes around the groups.

##
class.t.2 <- cbind(class.t.1,groups.1)
library(dplyr)

class.t.2 %x% mutate(Source = 
                       case_when(class.t.2[,4] == "5" ~ "Population",
                                 class.t.2[,4] == "6" ~ "None",
                                 class.t.2[,4] == "1" ~ "Climate",
                                 class.t.2[,4] == "3" ~ "Climate",
                                 class.t.2[,4] == "7" ~ "Climate",
                                 class.t.2[,4] == "2" ~ "Both",
                                 class.t.2[,4] == "4" ~ "Both",
                                 class.t.2[,4] == "8" ~ "Both")
)



class.t.3 <- cbind(class.t.1, groups.1, class.lat, class.lon)

data6 <- as.data.frame(cbind(class.lon, class.lat, groups.1))

ggplot(data6, aes(x=class.lon, y=class.lat, color=as.factor(groups.1))) + geom_point() +
  scale_color_manual(values = c("1" = "green",
                                "2" = "yellow",
                                "3" = "green",
                                "4" = "yellow",
                                "5" = "red",	
                                "6" = "white",
                                "7" = "green",
                                "8" = "yellow")) 



Lake.SS[Lake.SS$year=='2000',]	
