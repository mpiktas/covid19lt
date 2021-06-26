library(dplyr)
library(lubridate)
library(testthat)
library(gert)
library(EpiEstim)

source("R/functions.R")
source("R/effective.R")

push_to_github(c("data", "raw_data"), "Update effective R data", push = FALSE)
