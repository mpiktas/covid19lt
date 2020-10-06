library(dplyr)
library(lubridate)

fn <- dir("raw_data/hospitalization", full.names = TRUE)

fns <- c(fn[grepl("tlk_",fn)])

tlk <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[4:5],collapse="_")))

tlk1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), tlk, pt, SIMPLIFY = FALSE) %>%
    bind_rows %>%  mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

tlk2 <-  tlk1 %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    select(day, description, tlk, total, intensive, ventilated, oxygen_mask)

write.csv(tlk2, "data/hospital-capacity.csv", row.names = FALSE)

# Do the same for another layer -------------------------------------------

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
           intensive)

write.csv(cvh2, "data/lt-covid19-hospitalized.csv", row.names = FALSE)

