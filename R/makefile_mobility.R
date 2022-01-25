library(dplyr)
library(lubridate)
library(testthat)
library(gert)

source("R/functions.R")

cat("\n=======Downloading Apple mobility data================\n")
try(source("R/download_apple_mobility.R"))
cat("\n=======Downloading Google mobility data================\n")
try(source("R/download_google_mobility.R"))

set_github_remote()

modf <- git_status() %>%
  .$file %>%
  find_root() %>%
  unique()
if (!(any(c("raw_data", "data") %in% modf))) {
  cat("\nNo new data, not pushing anything\n")
} else {
  push_to_github(c("data", "raw_data"), "Update mobility data", push = FALSE)
}
