library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)

source("R/functions.R")


httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))

posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/OV_COVID_tyrimai_grafikai/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # Exclude Linting
posp1 <- fix_esridate(rawToChar(posp$content))
posp2 <- posp1 %>% mutate(day = ymd(date))
posp22 <- posp2 %>% filter(day == max(day))

alls <- lapply(unique(posp22$municipality_name), function(x) {
  sav <- URLencode(x)
  try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/OV_COVID_tyrimai_grafikai/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token="))) # Exclude Linting
})

osp1 <- lapply(alls, function(l) fix_esridate(rawToChar(l$content))) %>%
  bind_rows()


osp1 %>%
  arrange(date, municipality_code) %>%
  write.csv("raw_data/osp/osp_covid19_tests.csv", row.names = FALSE)


osp2 <- osp1 %>% mutate(day = ymd(date))

adm <- read.csv("raw_data/administrative_levels.csv")


osp3 <- osp2 %>% inner_join(adm)

if (nrow(osp3) == nrow(osp2)) {
  osp4 <- osp3 %>% mutate(
    pcr_positive = round(pcr_tot_day * pcr_prc_day / 100),
    ag_positive = round(ag_tot_day * ag_prc_day / 100),
    ab_positive = round(ab_tot_day * ab_prc_day / 100),
    tests_positive = pcr_positive + ag_positive,
    tests_total = pcr_tot_day + ag_tot_day
  )

  osp5 <- osp4 %>%
    select(day, municipality_code, administrative_level_3,
      tests_positive, tests_total,
      tests_pcr = pcr_tot_day,
      tests_ag = ag_tot_day,
      tests_ab = ab_tot_day,
      tests_pcr_positive = pcr_positive,
      tests_ag_positive = ag_positive,
      tests_ab_positive = ab_positive
    ) %>%
    arrange(day, municipality_code)

  osp5 %>% write.csv("data/osp/lt-covid19-tests.csv", row.names = FALSE)
}
