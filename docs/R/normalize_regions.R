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
write.csv(svd2, "data/lt-covid19-regions.csv", row.names = FALSE)


# Last 14 days for regions ------------------------------------------------

sdd <- function(x)c(0, diff(x))

rr <- svd2 %>% arrange(administrative_level_3,day) %>%
    filter(day == max(day) | day == (max(day) - days(14))) %>%
    group_by(administrative_level_3) %>%
    mutate(incidence = sdd(confirmed)) %>%
    ungroup %>%
    filter(day == max(day)) %>%
    select(day, administrative_level_3, incidence, population)

svap <- adsd$sav %>% select(administrative_level_3 = SAV_PAV, administrative_level_2 = APSKRITIS) %>% unique
rr1 <- rr %>% inner_join(svap)

rr2 <- rr1 %>% group_by(administrative_level_2) %>%
    summarize(n = n(), s=sum(incidence), p = sum(incidence<=0), population = sum(population)) %>%
    mutate(s14 = s/population*1e5)


# Do age groups -----------------------------------------------------------

fn <- dir("rc", full.names = TRUE)

fns <- c(fn[grepl("amziaus_grupes_",fn)])

agr <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[3:4],collapse="_")))

ag1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), agr, pt, SIMPLIFY = FALSE) %>% bind_rows %>%
    select(-X) %>% mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

ag2 <-  ag1 %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    select(day, age_group= AMZIAUSGRUPE,
           confirmed = TEIGIAMI,
           confirmed_100k = ATVEJAI_VISI_100000,
           confirmed_male = VYRAI,
           confirmed_male_100k = ATVEJAI_V_100000,
           confirmed_female  = MOTERYS,
           confirmed_female_100k  = ATVEJAI_M_100000,
           other = KITA,
           total = VISO,
           population = GYV_SKAIC,
           population_male = GYV_SKAIC_V,
           population_female = GYV_SKAIC_M,
           downloaded
    )
write.csv(ag2, "data/lt-covid19-agegroups.csv", row.names = FALSE)

# Do profession -----------------------------------------------------------

fn <- dir("rc", full.names = TRUE)

fns <- c(fn[grepl("profesijos",fn)])

pr <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[2:3],collapse="_")))

pr1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), pr, pt, SIMPLIFY = FALSE) %>% bind_rows %>%
    select(-X) %>% mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

pr2 <-  pr1 %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    select(day, profession = PROFESIJA,
           confirmed = TEIGIAMI,
           confirmed_male = VYRAI,
           confirmed_female  = MOTERYS,
           active = GYDOMA,
           recovered = PASVEIKO,
           deaths = MIRE,
           updated = ATNAUJINIMODATA,
           downloaded
    )

source("R/sanity_checks.R")