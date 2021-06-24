library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)
library(tidyr)

source("R/functions.R")

osp <- tryget("https://opendata.arcgis.com/datasets/7c4b3397dc2c424aa400a5d1aed1fcc7_0.geojson")
osp1 <- fromJSON(rawToChar(osp$content))$features$properties



osp1 %>%
  arrange(test_performed, lab_name) %>%
  select(-object_id) %>%
  write.csv("raw_data/osp/osp_covid19_laboratory.csv", row.names = FALSE)

osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(test_performed)))


osp3 <- osp2 %>%
  select(lab_name, day, test_type, tests_positive, tests_negative, gmp_indication) %>%
  mutate(tests = tests_positive + tests_negative) %>%
  select(-tests_negative) %>%
  arrange(lab_name, day)

osp3 %>% write.csv("data/lt-covid19-laboratory.csv", row.names = FALSE)
