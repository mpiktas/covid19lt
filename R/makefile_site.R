library(gert)
library(dplyr)
library(lubridate)

aa <- read.csv("data/lt-covid19-aggregate.csv") %>% mutate(day = ymd(day))
cdt <- ymd(floor_date(Sys.time(),unit = "day"))-days(1)

if(cdt == max(aa$day)) {
    rmarkdown::render_site()
    source("R/render_regions.R")
    git_add("docs")
    git_commit("Update the site")
    git_push()
} else {
    cat("\nNo new data.gov.lt data, not updating the site")
}