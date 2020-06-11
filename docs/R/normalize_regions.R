library(dplyr)
library(lubridate)

fn <- dir("rc", full.names = TRUE)

fns <- c(fn[grepl("sav_",fn)])

savd <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[2:3],collapse="_")))

savd1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), savd, pt, SIMPLIFY = FALSE) %>% bind_rows %>%
    select(-X) %>% mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

savd2 <-  savd1 %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    select(day, administrative_level_3 = SAV_PAV, administrative_level_2 = APSKRITIS,
           confirmed = TEIGIAMI,
           confirmed_male = VYRAI,
           confirmed_female  = MOTERYS,
           active = GYDOMA,
           recovered = PASVEIKO,
           deaths = MIRE,
           confirmed_14 = ATVEJAI_14,
           downloaded,
           updated =ATNUJINTA
           )

# Do the same for another layer -------------------------------------------

fn <- dir("rc", full.names = TRUE)

fns <- c(fn[grepl("savivaldybiu_",fn)])

savd <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[2:3],collapse="_")))

svd1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), savd, pt, SIMPLIFY = FALSE) %>% bind_rows %>%
    select(-X) %>% mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

svd2 <-  svd1 %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    select(day, administrative_level_3 = SAV_PAV,
           confirmed = TEIGIAMI,
           confirmed_100k = ATVEJAI_10000_GYV,
           confirmed_14 = ATVEJAI_14,
           confirmed_14_100k = ATVEJAI_14_100000,
           confirmed_male = VYRAI,
           confirmed_female  = MOTERYS,
           active = GYDOMA,
           active_100k = GYDOMA_10000_GYV,
           recovered = PASVEIKO,
           deaths = MIRE,
           population = GYV_SK,
           downloaded,
           updated =ATNUJINTA
    )


