library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)

osp <- GET("https://opendata.arcgis.com/datasets/538b7bd574594daa86fefd16509cbc36_0.geojson")


osp1 <- fromJSON(rawToChar(osp$content))$features$properties
osp1 %>% write.csv("raw_data/osp/osp_covid19_tests.csv", row.names = FALSE)


osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(test_performed_date)))

adm <- read.csv("raw_data/administrative_levels.csv")

osp3 <- osp2 %>% inner_join(adm %>% select(-population))

if(nrow(osp3) == nrow(osp2)) {
    osp3 %>% select(day, administrative_level_3,
                    tests_negative, tests_positive, tests_positive_repeated,
                    tests_positive_new, tests_total) %>%
        arrange(day, administrative_level_3) %>%
        write.csv("data/lt-covid19-tests.csv", row.names = FALSE)

}

