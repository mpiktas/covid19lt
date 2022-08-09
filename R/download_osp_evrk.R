library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)

source("R/functions.R")


osp <- tryget("https://opendata.arcgis.com/datasets/44e6fa7b27434eedbbf75e3f15068e91_0.geojson") # Exclude Linting
osp1 <- fromJSON(rawToChar(osp$content))$features$properties

osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(test_date)))


evrk <- tryget("https://opendata.arcgis.com/datasets/161c571cb56c4f9da294c0133a9d8766_0.geojson") # Exclude Linting
evrk1 <- fromJSON(rawToChar(evrk$content))$features$properties

evrk1 %>%
  select(-object_id) %>%
  write.csv("raw_data/osp/evrk_meta.csv", row.names = FALSE)

osp3 <- osp2 %>%
  inner_join(evrk1 %>% select(evrk_group_code, evrk_group_title) %>% unique())

if (nrow(osp3) == nrow(osp2)) {
  osp4 <- osp3 %>%
    select(
      day, evrk_group_code, evrk_group_title,
      tests_positive, tests_negative
    ) %>%
    mutate(tests = tests_positive + tests_negative) %>%
    select(-tests_negative) %>%
    arrange(day, evrk_group_code)

  osp4 %>% write.csv("data/lt-covid19-evrk.csv", row.names = FALSE)
}
