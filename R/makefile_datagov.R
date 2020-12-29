library(dplyr)
library(lubridate)
library(testthat)
library(gert)

source("R/functions.R")

cat("\n=======Downloading tests================\n")
try(source('R/download_osp_tests.R'))
cat("\n=======Downloading cases================\n")
try(source('R/download_osp_cases.R'))
cat("\n=======Downloading age distribution data================\n")
try(source("R/download_osp_agedist.R"))
cat("\n=======Download datagov data================\n")
try(source("R/download_datagov.R"))
cat("\n=======Creating levels data================\n")
try(source('R/create_levels.R'))



modf <- git_status() %>% .$file %>% find_root %>% unique
if(!("data" %in% modf)) {
    cat("\nNo new data, not pushing anything\n")
} else {
    push_to_github(c("data","raw_data"), "Update data.gov.lt data", push = TRUE)
}


