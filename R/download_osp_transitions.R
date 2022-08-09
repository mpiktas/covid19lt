library(dplyr)
library(tidyr)
library(lubridate)
library(glue)
library(curl)


curl_download("https://ls-osp-sdg.maps.arcgis.com/sharing/rest/content/items/12822ba507864e119d713d14c1971e78/data", destfile = "init0.xlsx") # nolint
init0 <- readxl::read_xlsx("init0.xlsx")
file.remove("init0.xlsx")

adm <- read.csv("raw_data/administrative_levels.csv") %>%
  rbind(data.frame(
    administrative_level_2 = "Censored",
    administrative_level_3 = "Censored",
    municipality_name = "Cenzūruota",
    population2020 = NA,
    population2021 = NA
  )) %>%
  rename(municipality = municipality_name)

init01 <- init0 %>% inner_join(adm)

if (nrow(init01) == nrow(init0)) {
  init02 <- init01 %>% select(administrative_level_2, administrative_level_3, age_gr, at_risk)
  write.csv(init02, "data/osp/lt-covid19-transition-init.csv", row.names = FALSE)
}

osp <- read.csv("https://open-data-ls-osp-sdg.hub.arcgis.com/datasets/1fd352a1c4534afe8ff87c564c0724c0_0.csv")

osp1 <- osp %>% mutate(day = ymd(ymd_hms(date)))

osp2 <- osp1 %>% inner_join(adm)

if (nrow(osp1) == nrow(osp2)) {
  cnames <- c("day", "administrative_level_2", "administrative_level_3", "sex", "age_gr", "r0i0", "r0r1", "r0c0", "r0i1", "r0c1", "r1i1", "r1r2", "r1c1", "r1i2", "r1c2", "r2i2", "r2r3", "r2c2", "r2i3", "r2c3", "r3i3", "r3c3", "r1i1_mdsv", "r2i2_mdsv", "r1i1_john", "r2i2_john") # nolint
  osp3 <- osp2[, cnames]
  write.csv(osp3, "data/osp/lt-covid19-transition.csv", row.names = FALSE)
}
