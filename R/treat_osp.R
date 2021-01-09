library(lubridate)
library(dplyr)
library(tidyr)

# Create daily files --------------------------------------------
fns <- dir("raw_data/sam", pattern = "daily", full.names = TRUE)

samd <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[3:4],collapse="_")))

sam <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm) %>% select(-day), samd, pt, SIMPLIFY = FALSE) %>% bind_rows  %>% mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

dl <-  sam %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    mutate(country = "Lithuania") %>%
    select(country, day, incidence, daily_tests, confirmed, active, deaths, recovered, quarantined, total_tests, deaths_different, imported0601, under_observation, vacine_daily, vacine_total) %>%
    arrange(day)

dd <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day)) %>% arrange(day)
ld <- dd %>% filter(day == max(day))
ldl <- dl  %>% filter(day == max(day))
ss <- identical(ld[1,-2:-1], data.frame(ldl[1,-2:-1]))

if(ss) {
    cat("\nNo new data for daily\n")
} else {
    dl %>% write.csv("data/lt-covid19-daily.csv", row.names = FALSE)
}

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

cvh <- read.csv("data/lt-covid19-hospitalized.csv") %>% mutate(day = ymd(day))
lcvh <- cvh %>% filter(day == max(day))
lcvh2 <- cvh2 %>% filter(day == max(day)) %>% data.frame
ss <- identical(lcvh, lcvh2)
if(ss) {
    cat("\nNo hospitalization data\n")
} else {
    write.csv(cvh2, "data/lt-covid19-hospitalized.csv", row.names = FALSE)
}


