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
posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_chart_new/FeatureServer/0/query?where=vaccination_state%3D%2700visos%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # nolint
posp1 <- fix_esridate(rawToChar(posp$content))
posp2 <- posp1 %>% mutate(day = ymd(date))

alls <- lapply(unique(posp2$municipality_name), function(x) {
  sav <- URLencode(x)
  try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_chart_new/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token="))) # nolint
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
  dosed <- data.frame(dose_number = c("00visos", "plinai"), dose = c(1, 2))
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
#
vcfd0 <- readr::read_csv("https://opendata.arcgis.com/datasets/ffb0a5bfa58847f79bf2bc544980f4b6_0.csv")

if (FALSE) {
  vcfd0 <- read.csv2("https://ls-osp-sdg.maps.arcgis.com/sharing/rest/content/items/e714f97f593d49c6b751b4b094ac33d2/data") # nolint

  vcfd <- vcfd0 %>%
    rename(
      birth_year_noisy = birth_year,
      vacc_type_1 = vacc_type_, vacc_type_2 = vacc_type1,
      vacc_date_1 = vacc_date_, vacc_date_2 = vacc_date1
    ) %>%
    mutate(vacc_type_2 = ifelse(vacc_type_2 == "", NA, vacc_type_2))
}

vcfd0 <- vcfd0 %>%
  mutate(age_group = year(Sys.Date()) - birth_year_noisy) %>%
  mutate(day = ymd(ymd_hms(vaccination_date))) %>%
  arrange(pseudo_id, day) %>%
  group_by(pseudo_id) %>%
  mutate(dose = 1:n())

vcfd <- vcfd0 %>%
  filter(dose == 1) %>%
  select(pseudo_id,
    municip_a = muni_declared, sex, age_group,
    vacc_date_1 = day, vacc_type_1 = drug_manufacturer
  ) %>%
  left_join(vcfd0 %>% filter(dose == 2) %>% # nolint
    select(pseudo_id, vacc_date_2 = day, vacc_type_2 = drug_manufacturer)) %>%
  left_join(vcfd0 %>% filter(dose == 3) %>% # nolint
    select(pseudo_id, vacc_date_3 = day, vacc_type_3 = drug_manufacturer)) %>%
  ungroup()

oo <- vcfd %>%
  count(vacc_type_1, vacc_type_2) %>%
  arrange(n)

valid <- oo %>%
  filter(vacc_type_1 == vacc_type_2 | is.na(vacc_type_2)) %>%
  .$n %>%
  sum()

cat("\nValid vaccination records:", valid, "out of", nrow(vcfd), "\n")
cat("\nValid vaccination record percentage:", round(100 * valid / nrow(vcfd), 2), "\n")
cat("\nLast date of the vaccination records:", as.character(max(vcfd$vacc_date_1)), "\n")

vcfd <- vcfd %>% filter(vacc_type_1 == vacc_type_2 | is.na(vacc_type_2))

vcfd <- vcfd %>% rename(
  day1 = vacc_date_1,
  day2 = vacc_date_2
)

v1 <- vcfd %>%
  group_by(
    municipality_name = municip_a, day = day1,
    age_group, sex
  ) %>%
  summarise(dose1 = n()) %>%
  ungroup()


vcfd$day2[vcfd$vacc_type_1 == "Johnson & Johnson"] <- vcfd$day1[vcfd$vacc_type_1 == "Johnson & Johnson"]

v2 <- vcfd %>%
  filter(vacc_type_1 == "Johnson & Johnson" | !is.na(vacc_type_2)) %>%
  group_by(
    municipality_name = municip_a, day = day2,
    age_group, sex
  ) %>%
  summarise(dose2 = n()) %>%
  ungroup()

vv <- v1 %>%
  full_join(v2) %>%
  mutate(dose1 = fix_na(dose1), dose2 = fix_na(dose2))
vv <- vv %>% mutate(sex = ifelse(sex == "M", "Moteris", "Vyras"))

agd <- data.frame(age_group = sort(unique(vv$age_group))) %>%
  mutate(
    age10 =
      cut(as.numeric(age_group), c(seq(0, 80, by = 10), Inf),
        include.lowest = TRUE, right = FALSE
      )
  ) %>%
  mutate(age10 = gsub("[[)]", "", age10)) %>%
  mutate(age10 = gsub(",", "-", age10)) %>%
  mutate(age10 = ifelse(is.na(age10), "80+", age10)) %>%
  mutate(age10 = ifelse(age10 == "80-Inf]", "80+", age10)) %>%
  mutate(age10 = convert_interval(age10))

vv1 <- vv %>%
  ungroup() %>%
  inner_join(agd) %>%
  group_by(municipality_name, day, age = age10, sex) %>%
  summarise(dose1 = sum(dose1), dose2 = sum(dose2)) %>%
  ungroup()


vv2 <- vv1 %>% inner_join(adm)
vv2 %>%
  select(
    administrative_level_2,
    administrative_level_3, day, age, sex, dose1, dose2
  ) %>%
  write.csv("data/lt-covid19-vaccinated-agedist10-level3.csv",
    row.names = FALSE
  )

#--- Deliveries


posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_by_drug_name_new/FeatureServer/0/query?where=vaccination_state%3D%27Visi%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # nolint
posp1 <- fix_esridate(rawToChar(posp$content))
posp2 <- posp1 %>% mutate(day = ymd(date))

alls <- lapply(unique(posp2$municipality_name), function(x) {
  sav <- URLencode(x)
  try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_by_drug_name_new/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token="))) # nolint
})

osp1 <- lapply(alls, function(l) fix_esridate(rawToChar(l$content))) %>%
  bind_rows()

osp1 %>%
  arrange(date, municipality_code) %>%
  write.csv("raw_data/osp/osp_covid19_vaccine_supply.csv", row.names = FALSE)

osp2 <- osp1 %>%
  mutate(day = ymd(date)) %>%
  filter(municipality_name == "Lietuva") %>%
  filter(!is.na(vaccines_arrived_day) | !is.na(vaccines_allocated_day)) %>%
  select(day, vaccine_name,
    vaccines_arrived = vaccines_arrived_day,
    vaccines_allocated = vaccines_allocated_day
  ) %>%
  arrange(day)

osp2 %>% write.csv("data/lt-covid19-vaccine-deliveries.csv", row.names = FALSE)
