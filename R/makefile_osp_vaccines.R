library(testthat)
library(gert)

source("R/functions.R")
zz <- read.csv("data/lt-covid19-vaccinated.csv") %>% mutate(day = ymd(day))
lv1 <- read.csv("data/lt-covid19-country.csv") %>% mutate(day = ymd(day))

if (max(zz$day) < max(lv1$day)) {
  cat("\n=======Downloading vaccine data ================\n")
  try(source("R/download_osp_vaccine.R"))
  cat("\n=======Creating levels data================\n")
  try(source("R/create_levels.R"))

  find_root <- function(x) {
    x %>%
      strsplit("/") %>%
      sapply("[[", 1)
  }

  ## Was the data modified?
  ##
  ##

  modf <- git_status() %>%
    .$file %>%
    find_root() %>%
    unique()
  if (!("data" %in% modf)) {
    cat("\nNo new data, not pushing anything\n")
  } else {
    push_to_github(c("data", "raw_data"), "Update OSP data", push = FALSE)
  }
}
