library(TMB)

## Compile and load the model
compile("mini.cpp")
dyn.load(dynlib("mini"))

## Data and parameters
data <- list(x=rivers)
parameters <- list(mu=0, logSigma=0)

## Make a function object
obj <- MakeADFun(data, parameters, DLL="mini")

## Call function minimizer
fit <- nlminb(obj$par, obj$fn, obj$gr)

## Get parameter uncertainties and convergence diagnostics
sdr <- sdreport(obj)
sdr
