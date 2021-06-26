library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)
library(tidyr)

source("R/functions.R")

httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))

posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/arcgis/rest/services/Agreguoti_COVID19_atvejai_ir_mirtys/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # Exclude Linting

posp1 <- fix_esridate(rawToChar(posp$content))
posp2 <- posp1 %>% mutate(day = ymd(date))

posp3 <- posp2 %>% filter(day == max(day))


osp0 <- read.csv("https://opendata.arcgis.com/datasets/ba35de03e111430f88a86f7d1f351de6_0.csv") # Exclude Linting

dd <- ymd(unique(osp0$date))
ld <- ymd(posp3$date %>% unique())
if (!(ld %in% dd)) {
  warning("Last day not present, adding a new day from another source")
  osp1 <- bind_rows(osp0, posp3 %>% select(-day))
} else {
  osp1 <- osp0
}

osp1 %>%
  arrange(date, municipality_name) %>%
  select(-object_id) %>%
  write.csv("raw_data/osp/osp_covid19_agedist.csv", row.names = FALSE)

osp2 <- osp1 %>% mutate(day = ymd(date))

adm <- read.csv("raw_data/administrative_levels.csv")


osp3 <- osp2 %>% inner_join(adm)

if (nrow(osp3) == nrow(osp2)) {
  osp4 <- osp3 %>%
    select(day, administrative_level_2, administrative_level_3,
      age = age_gr, sex = sex,
      confirmed_daily = new_cases,
      deaths_population_daily = deaths_all,
      deaths_1_daily = deaths_cov1,
      deaths_2_daily = deaths_cov2,
      deaths_3_daily = deaths_cov3
    ) %>%
    arrange(day, administrative_level_2, administrative_level_3)

  osp4 %>% write.csv("data/lt-covid19-agedist.csv", row.names = FALSE)

  agr <- read.csv("raw_data/agegroups2.csv") %>%
    bind_rows(data.frame(age = c("Nenustatyta"), age1 = c("Nenustatyta")))
  zz2 <- osp4 %>%
    inner_join(agr, by = "age") %>%
    select(-age) %>%
    rename(age = age1)
  zz2 <- zz2 %>%
    mutate(administrative_level_3 =
        ifelse(administrative_level_3 == "Unknown", "", administrative_level_3))
  zz2 <- zz2 %>%
    group_by(day, administrative_level_3, age) %>%
    summarise(
      confirmed_daily = sum(confirmed_daily),
      deaths_3_daily = sum(deaths_3_daily)
    ) %>%
    ungroup()
  bb <- daily_xtable2(zz2 %>% rename(indicator = confirmed_daily),
                      colsums = TRUE)
  bb1 <- daily_xtable2(zz2 %>% rename(indicator = deaths_3_daily),
                       colsums = TRUE)
  bb %>% write.csv("data/lt-covid19-age-region-incidence.csv",
                   row.names = FALSE)
  bb1 %>% write.csv("data/lt-covid19-age-region-deaths.csv",
                    row.names = FALSE)
}
