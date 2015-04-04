library(Rainmerging)

load("sat.rda")
load("gauge.rda")

# define interpolation grid  
coords 	<- sat[["pixels"]] # this is default case where
		# interpolation grid == satellite grid. otherwise define coords. 

# regrid satellite data onto interpolation grids
sat   	<- NN.interp(sat,coords) #uncomment if interp grid != satellite grid

# colocate gauge with pixels and take average when #gauges/pixel > 1 
gauge  	<- colocate.gauge (gauge,coords)


#######################################################################################

# perform merging 

#######################################################################################

# Mean-field (i.e spatial) bias correction
MBC_out	<- MBC(sat,gauge)

# Double kernel smoothing
DS_out 	<- DS (sat,gauge)

# Ordinary Kriging
OK_out  <- OK (coords,gauge)

# Universal Kriging/Kriging with External Drift
KED_out <- KED(sat,gauge)

# Bayesian Combination
BC_out  <- BC (sat,gauge)

# save results
results 	<- list(sat[["ts"]],MBC_out, DS_out, OK_out, KED_out, BC_out)
names(results) <- list("SAT","MBC","DS", "OK", "KED", "BC")

#######################################################################################

# visualise output 

#######################################################################################

#select either mean or single timestep

fun 			<- function(ts) { return(apply(ts, 2, mean))}
map  			<- sapply(results , fun)

map 			<- data.frame(map)
coordinates(map) 	<- coordinates(sat[[2]])
map 			<- as(map,"SpatialPixelsDataFrame")

bitmap(file="CompareAvg.png", res=300)
spplot(map)
dev.off()

#######################################################################################

# run cross-validation

#######################################################################################


# Mean-field (i.e spatial) bias correction
MBC_cv	<- MBC(sat,gauge, cross.val=TRUE)

# Double kernel smoothing
DS_cv 	<- DS (sat,gauge, cross.val=TRUE)

# Ordinary Kriging
OK_cv  	<- OK (coords,gauge,cross.val=TRUE)

# Universal Kriging/Kriging with External Drift
KED_cv 	<- KED(sat,gauge,cross.val=TRUE)

# Bayesian Combination
BC_cv  	<- BC (sat,gauge,cross.val=TRUE)

# Satellite product
loc <- numeric()
for (i in 1:length(gauge[[2]][,])) loc[i] <- which.min(spDists(sat[[2]],gauge[[2]][i,] ,longlat=TRUE))
SAT_cv <- sat[[1]][,loc]

# save results
results_CV 	<- list(SAT_cv, MBC_cv, DS_cv, OK_cv, KED_cv, BC_cv)
names(results_CV) <- list("SAT","MBC","DS", "OK", "KED", "BC")

# calculate and compare scores
scores <- crossval_score(results_CV,gauge)

summary(scores[["me"]])
summary(scores[["mae"]])
summary(scores[["rmse"]])
summary(scores[["r"]])
summary(scores[["nse"]])

map 			<- scores[["me"]]
coordinates(map) 	<- coordinates(gauge[[2]])
map 			<- as(map,"SpatialPixelsDataFrame")

bitmap(file="me_scores.png", res=300)
trellis.par.set(sp.theme())
spplot(map)
dev.off()

#######################################################################################


