library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)
library(tidyr)

source("R/functions.R")


osp1 <- read.csv("https://opendata.arcgis.com/datasets/97efefc004af4ef3a23158aec14a1363_0.csv")


osp1 %>% arrange(date, healthcare_region) %>% select(-object_id) %>%
    write.csv("raw_data/osp/osp_covid19_hospital.csv", row.names = FALSE)

osp2 <- osp1 %>% mutate(day = ymd(date)) %>% select(-object_id,-date)


osp3 <- osp2 %>% arrange(day,healthcare_region)
osp3 <- osp3[,c(ncol(osp3),1:(ncol(osp3)-1))]

osp3 %>%  write.csv("data/lt-covid19-hospitals-region.csv", row.names = FALSE)


