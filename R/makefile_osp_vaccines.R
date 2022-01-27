library(testthat)
library(gert)
library(dplyr)
library(lubridate)

source("R/functions.R")
zz <- read.csv("data/lt-covid19-vaccinated.csv") %>% mutate(day = ymd(day))
lv1 <- read.csv("data/lt-covid19-country.csv") %>% mutate(day = ymd(day))

set_github_remote()

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
    rmarkdown::render_site("website/index.Rmd")
    rmarkdown::render_site("website/weeks.Rmd")
    cat("\nSending the data and site downstream\n")
    push_to_github(c("docs", "data", "raw_data"), "Update vaccine data", push = FALSE)
    system("git push github master")
  }
}
