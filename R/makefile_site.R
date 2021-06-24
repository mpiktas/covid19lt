library(gert)
library(dplyr)
library(lubridate)
source("R/functions.R")

rmarkdown::render_site("website")
# source("R/render_regions.R")

# push_to_github("docs", "Update the site", push = FALSE)
