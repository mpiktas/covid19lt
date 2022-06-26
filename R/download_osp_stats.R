library(httr)
library(rvest)
library(dplyr)
library(lubridate)
library(stringr)
library(jsonlite)
library(bit64)

source("R/functions.R")

if (TRUE) {
  httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))

  posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/arcgis/rest/services/COVID19_statistika_dashboards/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # nolint: line_length_linter

  posp1 <- fix_esridate(rawToChar(posp$content))
  posp2 <- posp1 %>% mutate(day = ymd(date))

  alls <- lapply(unique(posp2$municipality_name), function(x) {
    sav <- URLencode(x)
    try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/arcgis/rest/services/COVID19_statistika_dashboards/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token="))) # nolint: line_length_linter
  })


  osp1 <- lapply(alls, function(l) fix_esridate(rawToChar(l$content))) %>%
    bind_rows()
  osp1 %>%
    arrange(date, municipality_code) %>%
    write.csv("raw_data/osp/osp_covid19_stats.csv", row.names = FALSE)
} else {
  osp0 <- read.csv("https://get.data.gov.lt/datasets/gov/lsd/covid-19/svieslenciu_statistika/SvieslenciuStatistika/:format/csv") # nolint: line_length_linter
  osp1 <- osp0 %>%
    mutate(municipality_code = as.character(municipality_code)) %>%
    mutate(
      municipality_code =
        ifelse(municipality_code == "0", "00", municipality_code)
    )

  osp1 %>%
    select(-X_type, -X_id, -X_revision) %>%
    arrange(date, municipality_code) %>%
    write.csv("raw_data/osp/osp_covid19_stats.csv", row.names = FALSE)
}

osp2 <- osp1 %>% mutate(day = ymd(date))

adm <- read.csv("raw_data/administrative_levels.csv")

osp3 <- osp2 %>% inner_join(adm)

if (nrow(osp3) == nrow(osp2)) {
  osp4 <- osp3 %>%
    select(day, municipality_code, administrative_level_3,
      confirmed_cases = incidence, active_cases = active_sttstcl,
      infection_1_daily = infection1,
      infection_2_daily = infection2,
      infection_3_daily = infection3,
      deaths_1_daily = daily_deaths_def1,
      deaths_2_daily = daily_deaths_def2,
      deaths_3_daily = daily_deaths_def3,
      deaths_population_daily = daily_deaths_all,
      tests_positive = dgn_pos_day,
      tests_total = dgn_tot_day,
      tests_mobile = dgn_tot_day_gmp,
      tests_pcr = pcr_tot_day,
      tests_ag = ag_tot_day,
      tests_ab = ab_tot_day,
      tests_pcr_positive = pcr_pos_day,
      tests_ag_positive = ag_pos_day,
      tests_ab_positive = ab_pos_day,
      population = population
    ) %>%
    arrange(day, municipality_code)

  osp4 %>% write.csv("data/osp/lt-covid19-stats.csv", row.names = FALSE)
}
