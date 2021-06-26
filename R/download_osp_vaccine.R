library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)
library(tidyr)
library(readr)

source("R/functions.R")

httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_chart_new/FeatureServer/0/query?where=vaccination_state%3D%27Visi%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # Exclude Linting
posp1 <- fix_esridate(rawToChar(posp$content))
posp2 <- posp1 %>% mutate(day = ymd(date))

alls <- lapply(unique(posp2$municipality_name), function(x) {
  sav <- URLencode(x)
  try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_chart_new/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token="))) # Exclude Linting
})

osp1 <- lapply(alls, function(l) fix_esridate(rawToChar(l$content))) %>%
  bind_rows()

osp1 %>%
  arrange(date, municipality_code) %>%
  write.csv("raw_data/osp/osp_covid19_vaccine.csv", row.names = FALSE)

osp2 <- osp1 %>% mutate(day = ymd(date))

adm <- read.csv("raw_data/administrative_levels.csv")

osp3 <- osp2 %>% inner_join(adm)

if (nrow(osp3) == nrow(osp2)) {
  osp4 <- osp3 %>%
    select(day, municipality_code,
      administrative_level_2,
      administrative_level_3,
      dose_number = vaccination_state,
      vaccinated = all_cum
    )
  dosed <- data.frame(dose_number = c("Visi", "Pilnai"), dose = c(1, 2))
  osp5 <- osp4 %>%
    inner_join(dosed) %>%
    select(-dose_number)
  osp6 <- osp5 %>%
    pivot_wider(
      id_cols = day:administrative_level_3, names_from = "dose",
      values_from = vaccinated, names_sort = TRUE
    ) %>%
    arrange(day, municipality_code) %>%
    rename(vaccinated_1 = `1`, vaccinated_2 = `2`) %>%
    group_by(administrative_level_3) %>%
    mutate(
      vaccinated_daily_1 = ddiff(vaccinated_1),
      vaccinated_daily_2 = ddiff(vaccinated_2)
    )

  osp6 %>% write.csv("data/lt-covid19-vaccinated.csv", row.names = FALSE)
}

#-------- Individual data
if (FALSE) {
  vcfd <- readr::read_csv("https://opendata.arcgis.com/datasets/ffb0a5bfa58847f79bf2bc544980f4b6_0.csv") # Exclude Linting

  vcfd <- vcfd %>% mutate(
    day1 = ymd(ymd_hms(vacc_date_1)),
    day2 = ymd(ymd_hms(vacc_date_2))
  )
  v1 <- vcfd %>%
    group_by(
      municipality_name = municip_a, day = day1,
      age_group, sex
    ) %>%
    summarise(dose1 = n())

  v2 <- vcfd %>%
    filter(vacc_type_2 != "") %>%
    group_by(
      municipality_name = municip_b, day = day2,
      age_group, sex
    ) %>%
    summarise(dose2 = n())
  vv <- v1 %>%
    full_join(v2) %>%
    mutate(dose1 = fix_na(dose1), dose2 = fix_na(dose2))
}
#--- Deliveries


posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_by_drug_name_new/FeatureServer/0/query?where=vaccination_state%3D%27Visi%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # Exclude Linting
posp1 <- fix_esridate(rawToChar(posp$content))
posp2 <- posp1 %>% mutate(day = ymd(date))

alls <- lapply(unique(posp2$municipality_name), function(x) {
  sav <- URLencode(x)
  try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_by_drug_name_new/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token="))) # Exclude Linting
})

osp1 <- lapply(alls, function(l) fix_esridate(rawToChar(l$content))) %>%
  bind_rows()

osp1 %>%
  arrange(date, municipality_code) %>%
  write.csv("raw_data/osp/osp_covid19_vaccine_supply.csv", row.names = FALSE)

osp2 <- osp1 %>%
  mutate(day = ymd(date)) %>%
  filter(municipality_name == "Lietuva", vaccination_state == "Pilnai") %>%
  filter(!is.na(vaccines_arrived_day) | !is.na(vaccines_allocated_day)) %>%
  select(day, vaccine_name,
    vaccines_arrived = vaccines_arrived_day,
    vaccines_allocated = vaccines_allocated_day
  ) %>%
  arrange(day)

osp2 %>% write.csv("data/lt-covid19-vaccine-deliveries.csv", row.names = FALSE)
