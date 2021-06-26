library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)

source("R/functions.R")
geojson <- FALSE

if (geojson) {
  osp <- GET("https://opendata.arcgis.com/datasets/45b76303953d40e2996a3da255bf8fe8_0.geojson") # Exclude Linting
  osp1 <- fromJSON(rawToChar(osp$content))$features$properties
  osp1 <- osp1 %>% mutate(date = ymd(ymd_hms(date)))
} else {
  httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))

  posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/OV_COVID_atvejai_grafikai/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # Exclude Linting
  posp1 <- fix_esridate(rawToChar(posp$content))
  posp2 <- posp1 %>% mutate(day = ymd(date))

  alls <- lapply(unique(posp2$municipality_name), function(x) {
    sav <- URLencode(x)
    try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/OV_COVID_atvejai_grafikai/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token="))) # Exclude Linting
  })

  osp1 <- lapply(alls, function(l) fix_esridate(rawToChar(l$content))) %>%
    bind_rows()
}

osp1 %>%
  arrange(date, municipality_code) %>%
  select(-municipality_order, -object_id) %>%
  write.csv("raw_data/osp/osp_covid19_cases.csv", row.names = FALSE)

osp2 <- osp1 %>% mutate(day = ymd(date))

adm <- read.csv("raw_data/administrative_levels.csv")


osp3 <- osp2 %>% inner_join(adm)

if (nrow(osp3) == nrow(osp2)) {
  osp4 <- osp3 %>%
    select(day, municipality_code, administrative_level_3,
      confirmed_cases = incidence, recovered_cases = recovered_sttstcl_today,
      active_cases = active_sttstcl, dead_cases = dead_cases_today,
      confirmed_cases_cumulative = cumulative_totals,
      recovered_cases_cumulative = recovered_sttstcl,
      dead_cases_cumulative = dead_cases,
      recovered_cases_de_jure = recovered_de_jure_today,
      recovered_cases_de_jure_cumulative = recovered_de_jure
    ) %>%
    arrange(day, municipality_code)
  osp4 %>% write.csv("data/osp/lt-covid19-cases.csv", row.names = FALSE)
}
