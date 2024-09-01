library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)
library(tidyr)

source("R/functions.R")
osp0 <- read.csv("https://get.data.gov.lt/datasets/gov/lsd/covid19/LigoniniuDuomenys/:format/csv")


osp1 <- osp0 %>%
  group_by(date, hospital_name) %>%
  slice(1) %>%
  ungroup()

osp2 <- osp1 %>%
  mutate(day = ymd(date)) %>%
  select(-date, -X_type, -X_id, -X_revision, -koord, -X_page.next)


osp3 <- osp2 %>% arrange(day, healthcare_region, hospital_name)
osp3 <- osp3[, c(ncol(osp3), 1:(ncol(osp3) - 1))]

osp3 %>% write.csv("data/lt-covid19-hospitals-region.csv", row.names = FALSE)
