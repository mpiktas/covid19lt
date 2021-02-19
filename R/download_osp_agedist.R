library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)
library(tidyr)

source("R/functions.R")


#osp <- tryget("https://opendata.arcgis.com/datasets/064ca1d6b0504082acb1c82840e79ce0_0.geojson")
osp <- tryget("https://opendata.arcgis.com/datasets/034590b3317d46c0aa2717d0e87760d8_0.geojson")
osp1 <- fromJSON(rawToChar(osp$content))$features$properties



osp1 %>% arrange(confirmation_date, municipality_code, case_code) %>% select(-object_id) %>%
    write.csv("raw_data/osp/osp_covid19_agedist.csv", row.names = FALSE)

osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(confirmation_date)))

adm <- read.csv("raw_data/administrative_levels.csv")


osp3 <- osp2 %>% inner_join(adm)

if(nrow(osp3) == nrow(osp2)) {
    osp4 <- osp3 %>% select(day, administrative_level_2, administrative_level_3, municipality_code,
                    age=age_bracket, sex = gender, case_code) %>%
        arrange(day, municipality_code, case_code)

    osp4 %>%  write.csv("data/lt-covid19-agedist.csv", row.names = FALSE)

    agr <- read.csv("raw_data/agegroups.csv") %>%
        bind_rows(data.frame(age = c("nenustatyta"), age1 = c("Nenustatyta")))
    zz2 <- osp4  %>% inner_join(agr, by = "age") %>% select(-age) %>% rename(age = age1)
    zz2 <- zz2 %>% mutate(administrative_level_3 = ifelse(administrative_level_3 == "Unknown", "", administrative_level_3))
    bb <- daily_xtable(zz2, colsums = TRUE)

    bb %>% write.csv("data/lt-covid19-age-region-incidence.csv", row.names =  FALSE)

}

