library(dplyr)
library(lubridate)
library(zoo)

ss <- read.csv("data/osp/lt-covid19-stats.csv") %>% mutate(day = ymd(day))


cvh <- read.csv("data/lt-covid19-hospitals-country.csv") %>%
  mutate(day = ymd(day))
vcn <- read.csv("data/lt-covid19-vaccinated.csv") %>% mutate(day = ymd(day))
vlk <- read.csv("raw_data/vlk_historical.csv") %>% mutate(day = ymd(day))

hosp0 <- vlk %>% full_join(cvh %>% rename(vent = ventilated))
hosp1 <- hosp0 %>%
  mutate(
    hospitalized = ifelse(is.na(hospitalized), total, hospitalized),
    icu = ifelse(is.na(icu), intensive, icu),
    ventilated = ifelse(is.na(ventilated), vent, ventilated),
    oxygen = ifelse(is.na(oxygen), oxygen_mask, oxygen)
  ) %>%
  select(day, hospitalized, icu, ventilated, oxygen) %>%
  arrange(day)



fix_na <- function(x, fix = 0, fill = FALSE) {
  if (fill) {
    n <- length(x)
    if (is.na(x[n])) x[n] <- x[n - 1]
  }
  x[is.na(x)] <- fix
  x
}

adm <- read.csv("raw_data/administrative_levels.csv")

ss <- ss %>%
  arrange(administrative_level_3, day) %>%
  group_by(administrative_level_3) %>%
  mutate(
    cumulative_tests = cumsum(tests_total),
    deaths_1 = cumsum(deaths_1_daily),
    deaths_2 = cumsum(deaths_2_daily),
    deaths_3 = cumsum(deaths_3_daily),
    confirmed_cases_cumulative = cumsum(confirmed_cases),
    infection_1 = cumsum(infection_1_daily),
    infection_2 = cumsum(infection_2_daily),
    infection_3 = cumsum(infection_2_daily)
  ) %>%
  ungroup()

oo <- ss %>%
  filter(administrative_level_3 != "Lithuania") %>%
  select(-municipality_code, -administrative_level_3) %>%
  group_by(day) %>%
  summarise_all(sum)

if ("Lithuania" %in% ss$administrative_level_3) {
  zz <- ss %>%
    filter(administrative_level_3 == "Lithuania") %>%
    select(-administrative_level_3, -municipality_code, -day) - oo %>%
    select(-day)
  zz1 <- bind_cols(oo %>% select(day), zz)
  zz1 %>% write.csv("data/osp/lt-covid19-unassigned.csv", row.names = FALSE)
}

lvl3 <- ss %>%
  left_join(adm %>%
    select(-municipality_name, -population2020, -population2021)) %>%
  left_join(vcn) %>%
  mutate(administrative_level_2 = ifelse(is.na(administrative_level_2),
    "Unknown", administrative_level_2
  )) %>%
  rename(
    vaccinated_1_daily = vaccinated_daily_1,
    vaccinated_2_daily = vaccinated_daily_2,
    vaccinated_3_daily = vaccinated_daily_3
  ) %>%
  group_by(administrative_level_2, administrative_level_3) %>%
  arrange(day) %>%
  mutate(
    tests_positive = fix_na(tests_positive, fill = TRUE),
    tests_total = fix_na(tests_total, fill = TRUE),
    population = fix_na(population, fill = TRUE),
    vaccinated_1 = fix_na(vaccinated_1, fill = TRUE),
    vaccinated_2 = fix_na(vaccinated_2, fill = TRUE),
    vaccinated_3 = fix_na(vaccinated_3, fill = TRUE),
    partialy_protected = fix_na(partial_protection, fill = TRUE),
    fully_protected = fix_na(full_protection, fill = TRUE),
    booster_protected = fix_na(booster_protection, fill = TRUE),
    vaccinated_1_daily = fix_na(vaccinated_1_daily),
    vaccinated_2_daily = fix_na(vaccinated_2_daily),
    vaccinated_3_daily = fix_na(vaccinated_3_daily)
  ) %>%
  ungroup()


lvl31 <- lvl3 %>% select(day, administrative_level_2, administrative_level_3,
  municipality_code,
  confirmed = confirmed_cases_cumulative,
  tests = cumulative_tests,
  deaths = deaths_3,
  deaths_1,
  deaths_2,
  active = active_cases,
  vaccinated_1, vaccinated_2, vaccinated_3,
  partialy_protected, fully_protected, booster_protected,
  infection_1,
  infection_2,
  infection_3,
  confirmed_daily = confirmed_cases,
  tests_daily = tests_total,
  tests_mobile_daily = tests_mobile,
  tests_pcr_daily = tests_pcr,
  tests_ag_daily = tests_ag,
  tests_ab_daily = tests_ab,
  tests_positive_daily = tests_positive,
  tests_pcr_positive_daily = tests_pcr_positive,
  tests_ag_positive_daily = tests_ag_positive,
  tests_ab_positive_daily = tests_ab_positive,
  deaths_daily = deaths_3_daily,
  deaths_1_daily,
  deaths_2_daily,
  deaths_population_daily,
  vaccinated_1_daily, vaccinated_2_daily, vaccinated_3_daily,
  infection_1_daily,
  infection_2_daily,
  infection_3_daily,
  population
)

lvl2 <- lvl31 %>%
  filter(administrative_level_3 != "Lithuania") %>%
  select(-administrative_level_3, -municipality_code) %>%
  group_by(day, administrative_level_2) %>%
  summarise_all(sum)

lvl1 <- lvl31 %>%
  filter(administrative_level_3 == "Lithuania") %>%
  select(-administrative_level_3, -municipality_code, -administrative_level_2)

lvl31 <- lvl31 %>% filter(administrative_level_3 != "Lithuania")

lvl11 <- lvl1 %>%
  left_join(hosp1) %>%
  mutate(
    hospitalized = fix_na(hospitalized),
    icu = fix_na(icu),
    ventilated = fix_na(ventilated),
    oxygen = fix_na(oxygen)
  )



add_stats <- function(dt) {
  dt <- dt %>%
    select(
      day, region, confirmed_daily, tests_daily, tests_positive_daily,
      tests_mobile_daily,
      tests_pcr_daily, tests_ag_daily, tests_ab_daily,
      tests_pcr_positive_daily, tests_ag_positive_daily,
      tests_ab_positive_daily,
      deaths_daily, deaths_1_daily, deaths_2_daily,
      vaccinated_1, vaccinated_2, vaccinated_3,
      partialy_protected, fully_protected, booster_protected,
      population
    ) %>%
    arrange(region, day) %>%
    group_by(region) %>%
    mutate(
      cases_sum7 = rollsum(confirmed_daily, 7, fill = NA, align = "right"),
      cases_sum14 = rollsum(confirmed_daily, 14, fill = NA, align = "right"),
      test_sum7 = rollsum(tests_daily, 7, fill = NA, align = "right"),
      test_pcr_sum7 = rollsum(tests_pcr_daily, 7, fill = NA, align = "right"),
      test_ag_sum7 = rollsum(tests_ag_daily, 7, fill = NA, align = "right"),
      test_ab_sum7 = rollsum(tests_ab_daily, 7, fill = NA, align = "right"),
      test_sum14 = rollsum(tests_daily, 14, fill = NA, align = "right"),
      test_mobile_sum14 = rollsum(tests_mobile_daily, 14,
        fill = NA,
        align = "right"
      ),
      deaths_sum14 = rollsum(deaths_daily, 14, fill = NA, align = "right"),
      deaths_sum7 = rollsum(deaths_daily, 7, fill = NA, align = "right"),
      deaths_1_sum14 = rollsum(deaths_1_daily, 14, fill = NA, align = "right"),
      deaths_1_sum7 = rollsum(deaths_1_daily, 7, fill = NA, align = "right"),
      deaths_2_sum14 = rollsum(deaths_2_daily, 14, fill = NA, align = "right"),
      deaths_2_sum7 = rollsum(deaths_2_daily, 7, fill = NA, align = "right"),
      dgn_sum7 = rollsum(tests_positive_daily, 7, fill = NA, align = "right"),
      pcr_sum7 = rollsum(tests_pcr_positive_daily, 7,
        fill = NA,
        align = "right"
      ),
      ag_sum7 = rollsum(tests_ag_positive_daily, 7, fill = NA, align = "right"),
      ab_sum7 = rollsum(tests_ab_positive_daily, 7, fill = NA, align = "right"),
      dgn_sum14 = rollsum(tests_positive_daily, 14, fill = NA, align = "right"),
      tpr_dgn = round(100 * dgn_sum7 / test_sum7, 2),
      tpr_pcr = round(100 * pcr_sum7 / test_pcr_sum7, 2),
      tpr_ag = round(100 * ag_sum7 / test_ag_sum7, 2),
      tpr_ab = round(100 * ab_sum7 / test_ab_sum7, 2),
      confirmed_100k = cases_sum14 / population * 100000,
      dgn_100k = dgn_sum14 / population * 100000,
      deaths_100k = deaths_sum14 / population * 100000,
      deaths_1_100k = deaths_1_sum14 / population * 100000,
      deaths_2_100k = deaths_2_sum14 / population * 100000,
      tests_100k = test_sum14 / population * 100000,
      tests_mobile_100k = test_mobile_sum14 / population * 100000,
      confirmed_growth_weekly =
        round(100 * (cases_sum7 / lag(cases_sum7, 7) - 1), 2),
      dgn_growth_weekly = round(100 * (dgn_sum7 / lag(dgn_sum7, 7) - 1), 2),
      tpr_dgn_diff_weekly = tpr_dgn - lag(tpr_dgn, 7),
      tpr_pcr_diff_weekly = tpr_pcr - lag(tpr_pcr, 7),
      tpr_ag_diff_weekly = tpr_ag - lag(tpr_ag, 7),
      tpr_ab_diff_weekly = tpr_ab - lag(tpr_ab, 7),
      deaths_growth_weekly =
        round(100 * (deaths_sum7 / lag(deaths_sum7, 7) - 1), 2),
      deaths_1_growth_weekly =
        round(100 * (deaths_1_sum7 / lag(deaths_1_sum7, 7) - 1), 2),
      deaths_2_growth_weekly =
        round(100 * (deaths_2_sum7 / lag(deaths_2_sum7, 7) - 1), 2),
      vaccinated_1_percent = round(vaccinated_1 / population * 100, 2),
      vaccinated_2_percent = round(vaccinated_2 / population * 100, 2),
      vaccinated_3_percent = round(vaccinated_3 / population * 100, 2),
      partialy_protected_percent = round(partialy_protected / population * 100, 2),
      fully_protected_percent = round(fully_protected / population * 100, 2),
      booster_protected_percent = round(booster_protected / population * 100, 2)
    )

  dt <- dt %>% select(-(confirmed_daily:dgn_sum14)) # nolint
  dt %>% ungroup() # nolint
}

lvl31_stats <- lvl31 %>%
  rename(region = administrative_level_3) %>%
  add_stats() %>%
  rename(administrative_level_3 = region)
lvl2_stats <- lvl2 %>%
  filter(administrative_level_2 != "Unknown") %>%
  rename(region = administrative_level_2) %>%
  add_stats() %>%
  rename(administrative_level_2 = region)
lvl11_stats <- lvl1 %>%
  mutate(region = "Lithuania") %>%
  add_stats() %>%
  select(-region)

lvl32 <- lvl31 %>% left_join(lvl31_stats)
lvl21 <- lvl2 %>% left_join(lvl2_stats)
lvl12 <- lvl11 %>% left_join(lvl11_stats)

lvl32 %>%
  arrange(day, municipality_code) %>%
  select(-municipality_code) %>%
  write.csv("data/lt-covid19-level3.csv", row.names = FALSE)
lvl21 %>% write.csv("data/lt-covid19-level2.csv", row.names = FALSE)
lvl12 %>% write.csv("data/lt-covid19-country.csv", row.names = FALSE)
