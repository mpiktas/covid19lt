library(gert)
library(dplyr)
library(lubridate)

source("R/functions.R")
rmarkdown::render_site("website/index.Rmd")

cat("\nSending the site downstream\n")
push_to_github(c("docs"), "Update index page", push = FALSE)
