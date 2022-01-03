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

adm <- read.csv("raw_data/administrative_levels.csv") %>%
  rbind(data.frame(
    administrative_level_2 = "Unknown",
    administrative_level_3 = "Unknown",
    municipality_name = "Cenzūruota",
    population2020 = NA,
    population2021 = NA
  ))


#-------- Individual data
#
vcfd0 <- readr::read_csv("https://opendata.arcgis.com/datasets/ffb0a5bfa58847f79bf2bc544980f4b6_0.csv")

if (FALSE) {
  vcfd0 <- read.csv("https://get.data.gov.lt/datasets/gov/lsd/covid19/Vakcinavimas/:format/csv")
}



vcfd0 <- vcfd0 %>%
  mutate(age_group = year(Sys.Date()) - birth_year_noisy) %>%
  mutate(age_group = ifelse(is.na(age_group), -1, age_group)) %>%
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

vcfd <- vcfd %>% rename(
  day1 = vacc_date_1,
  day2 = vacc_date_2,
  day3 = vacc_date_3
)

v1 <- vcfd %>%
  group_by(
    municipality_name = municip_a, day = day1,
    age_group, sex
  ) %>%
  summarise(dose1 = n()) %>%
  ungroup()

v2 <- vcfd %>%
  filter(!is.na(day2)) %>%
  group_by(
    municipality_name = municip_a, day = day2,
    age_group, sex
  ) %>%
  summarise(dose2 = n()) %>%
  ungroup()

v3 <- vcfd %>%
  filter(!is.na(day2) & !is.na(day3)) %>%
  group_by(
    municipality_name = municip_a, day = day3,
    age_group, sex
  ) %>%
  summarise(dose3 = n()) %>%
  ungroup()

pp <- vcfd %>%
  filter((vacc_type_1 != "Johnson & Johnson") & is.na(day2) & is.na(day3)) %>%
  mutate(day1 = day1 + days(14)) %>%
  group_by(
    municipality_name = municip_a, day = day1,
    age_group, sex
  ) %>%
  summarise(partial_protection = n()) %>%
  ungroup()

ffjj <- vcfd %>%
  filter(vacc_type_1 == "Johnson & Johnson" & is.na(day2)) %>%
  mutate(day1 = day1 + days(14)) %>%
  group_by(
    municipality_name = municip_a, day = day1,
    age_group, sex
  ) %>%
  summarise(full_jj = n()) %>%
  ungroup()

ffo <- vcfd %>%
  filter(vacc_type_1 != "Johnson & Johnson" & !is.na(day2)) %>%
  mutate(day2 = day2 + days(14)) %>%
  group_by(
    municipality_name = municip_a, day = day2,
    age_group, sex
  ) %>%
  summarise(full_o = n()) %>%
  ungroup()

bbjj <- vcfd %>%
  filter(vacc_type_1 == "Johnson & Johnson" & !is.na(day2)) %>%
  mutate(day2 = day2 + days(14)) %>%
  group_by(
    municipality_name = municip_a, day = day2,
    age_group, sex
  ) %>%
  summarise(booster_jj = n()) %>%
  ungroup()

bbo <- vcfd %>%
  filter(vacc_type_1 != "Johnson & Johnson" & !is.na(day2) & !is.na(day3)) %>%
  mutate(day3 = day3 + days(14)) %>%
  group_by(
    municipality_name = municip_a, day = day3,
    age_group, sex
  ) %>%
  summarise(booster_o = n()) %>%
  ungroup()

vv0 <- expand_grid(
  municipality_name = sort(unique(v1$municipality_name)),
  day = seq(min(v1$day), max(c(v1$day, v2$day, v3$day)), by = "day")
)

vv <- vv0 %>%
  left_join(v1) %>%
  full_join(v2) %>%
  full_join(v3) %>%
  full_join(pp) %>%
  full_join(ffjj) %>%
  full_join(ffo) %>%
  full_join(bbjj) %>%
  full_join(bbo) %>%
  mutate(
    dose1 = fix_na(dose1), dose2 = fix_na(dose2), dose3 = fix_na(dose3),
    partial_protection = fix_na(partial_protection),
    full_protection = fix_na(full_jj) + fix_na(full_o),
    booster_protection = fix_na(booster_jj) + fix_na(booster_o)
  )

bad_join <- vv %>% filter(is.na(age_group) | is.na(sex))
bjs <- bad_join %>% summarise(dose1 = sum(dose1), dose2 = sum(dose2), dose3 = sum(dose3))

if (sum(unlist(bjs)) != 0) {
  warning("Missing age and sex information after join with non zero vaccination numbers")
}

sextb <- data.frame(
  sex = c("M", "V", "Cenzūruota"),
  sex1 = c("Moteris", "Vyras", "Cenzūruota")
)

vvv <- vv %>%
  ungroup() %>%
  filter(!(is.na(age_group) | is.na(sex))) %>%
  filter(day <= max(vv0$day))

vvv1 <- vvv %>% inner_join(sextb)

if (nrow(vvv1) != nrow(vvv)) warning("After joining sex information disappeared")

vvv2 <- vvv1 %>%
  select(-sex) %>%
  rename(sex = sex1)

agd <- data.frame(age_group = sort(unique(vv$age_group))) %>%
  mutate(
    age10 =
      cut(as.numeric(age_group), c(-1, seq(0, 80, by = 10), Inf),
        include.lowest = TRUE, right = FALSE
      )
  ) %>%
  mutate(age10 = gsub("[[)]", "", age10)) %>%
  mutate(age10 = gsub(",", "-", age10)) %>%
  mutate(age10 = ifelse(is.na(age10), "80+", age10)) %>%
  mutate(age10 = ifelse(age10 == "80-Inf]", "80+", age10)) %>%
  mutate(age10 = convert_interval(age10)) %>%
  mutate(age10 = ifelse(age_group == -1, "Nenustatyta", age10))

vv1 <- vvv2 %>%
  inner_join(agd) %>%
  group_by(municipality_name, day, age = age10, sex) %>%
  summarise(across(
    .cols = c("dose1", "dose2", "dose3", "partial_protection", "full_protection", "booster_protection"),
    .fns = sum
  )) %>%
  ungroup()


vv2 <- vv1 %>%
  inner_join(adm) %>%
  select(
    administrative_level_2,
    administrative_level_3, day, age, sex, dose1, dose2, dose3,
    partial_protection, full_protection, booster_protection
  )

vv2 %>%
  filter(age != "Nenustatyta") %>%
  write.csv("data/lt-covid19-vaccinated-agedist10-level3.csv",
    row.names = FALSE
  )

#-------- Do the aggregate statistics

cvv0 <- vv2 %>%
  group_by(day, administrative_level_2, administrative_level_3) %>%
  summarise(across(
    .cols = c("dose1", "dose2", "dose3", "partial_protection", "full_protection", "booster_protection"),
    .fns = sum
  ))

vvf <- expand_grid(
  administrative_level_3 = sort(unique(cvv0$administrative_level_3)),
  day = seq(ymd("2020-12-01"), max(c(vv1$day)), by = "day")
) %>%
  left_join(adm %>% select(administrative_level_2, administrative_level_3))

cvv <- vvf %>%
  left_join(cvv0) %>%
  mutate(across(
    .cols = c("dose1", "dose2", "dose3", "partial_protection", "full_protection", "booster_protection"),
    .fns = fix_na
  ))

cvv1 <- cvv %>%
  arrange(administrative_level_2, administrative_level_3, day) %>%
  group_by(administrative_level_2, administrative_level_3) %>%
  mutate(
    vaccinated_1 = cumsum(dose1),
    vaccinated_2 = cumsum(dose2),
    vaccinated_3 = cumsum(dose3),
    partial_protection = cumsum(partial_protection),
    full_protection = cumsum(full_protection),
    booster_protection = cumsum(booster_protection),
  ) %>%
  ungroup()

cvv2 <- cvv1 %>% select(day, administrative_level_2, administrative_level_3,
  vaccinated_1, vaccinated_2, vaccinated_3,
  partial_protection, full_protection, booster_protection,
  vaccinated_daily_1 = dose1,
  vaccinated_daily_2 = dose2,
  vaccinated_daily_3 = dose3
)

ltv <- cvv2 %>%
  group_by(day) %>%
  summarise(across(
    .cols = c(
      "vaccinated_1", "vaccinated_2", "vaccinated_3",
      "partial_protection", "full_protection", "booster_protection",
      "vaccinated_daily_1", "vaccinated_daily_2", "vaccinated_daily_3"
    ),
    .fns = sum
  )) %>%
  ungroup() %>%
  mutate(administrative_level_2 = "Lithuania", administrative_level_3 = "Lithuania")

cvv3 <- cvv2 %>% bind_rows(ltv)

cvv3 %>% write.csv("data/lt-covid19-vaccinated.csv", row.names = FALSE)
#--- Deliveries

## nolint start
## Leave old code for a while
## posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_by_drug_name_new/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # nolint
## posp1 <- fix_esridate(rawToChar(posp$content))
## posp2 <- posp1 %>% mutate(day = ymd(date))
## nolint end

httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/covid_vaccinations_chart_new/FeatureServer/0/query?where=vaccination_state%3D%2700visos%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") # nolint
posp1 <- fix_esridate(rawToChar(posp$content))
posp2 <- posp1 %>% mutate(day = ymd(date))

muni_name <- unique(posp2$municipality_name)


alls <- lapply(unique(muni_name), function(x) {
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
