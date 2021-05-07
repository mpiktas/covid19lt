library(lubridate)
library(dplyr)
library(tidyr)

# Do the covid19 totals -------------------------------------------

fn <- dir("raw_data/hospitalization", full.names = TRUE)

fns <- c(fn[grepl("covid_",fn)])

cvh <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[4:5],collapse="_")))

cvh1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), cvh, pt, SIMPLIFY = FALSE) %>% bind_rows %>%
    mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

cvh2 <-  cvh1 %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    select(day, total, oxygen_mask = oxygen,
           ventilated,
           not_intensive = hospitalized_not_intensive,
           intensive)

cvh <- read.csv("data/lt-covid19-hospitals-country.csv") %>% mutate(day = ymd(day))
lcvh <- cvh %>% filter(day == max(day))
lcvh2 <- cvh2 %>% filter(day == max(day)) %>% data.frame
ss <- identical(lcvh, lcvh2)
if(ss) {
    cat("\nNo hospitalization data\n")
} else {
    write.csv(cvh2, "data/lt-covid19-hospitals-country.csv", row.names = FALSE)
}


