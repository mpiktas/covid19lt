library(dplyr)
library(lubridate)
library(zoo)

tt <- read.csv("data/lt-covid19-tests.csv") %>% mutate(day = ymd(day))
cs <- read.csv("data/lt-covid19-cases.csv") %>% mutate(day = ymd(day))
ii <- read.csv("data/lt-covid19-individual.csv") %>% mutate(day = ymd(day))
iii <- ii %>% group_by(day, administrative_level_3) %>% summarise(imported_daily = sum(imported == "Taip"))

cvh <- read.csv("data/lt-covid19-hospitalized.csv") %>% mutate(day = ymd(day))
vlk <- read.csv("raw_data/vlk_historical.csv") %>% mutate(day = ymd(day))

hosp0 <- vlk %>% full_join(cvh %>% rename(vent = ventilated))
hosp1 <- hosp0 %>% mutate(hospitalized = ifelse(is.na(hospitalized), total, hospitalized),
                         icu = ifelse(is.na(icu), intensive, icu),
                         ventilated = ifelse(is.na(ventilated), vent, ventilated),
                         oxygen = ifelse(is.na(oxygen), oxygen_mask, oxygen)) %>%
    select(day, hospitalized, icu, ventilated, oxygen) %>% arrange(day)



fixNA <- function(x, fix = 0) {
    x[is.na(x)] <- fix
    x
}

adm <- read.csv("raw_data/administrative_levels.csv")

tt <- tt %>% arrange(administrative_level_3, day) %>% group_by(administrative_level_3) %>% mutate(cumulative_tests = cumsum(tests_total))

#cs %>% filter(administrative_level_3 == "Lithuania") %>%
#    select(day, confirmed_cases_cumulative, deaths_cumulative) %>%
#    left_join(aa %>% select(day, confirmed, deaths)) %>%
#    mutate(dc = confirmed_cases_cumulative - confirmed, dd = deaths_cumulative -deaths)

oo <- cs %>%   filter(administrative_level_3!= "Lithuania") %>%select(-municipality_code,-administrative_level_3) %>%
    group_by(day) %>% summarise_all(sum)

sum(abs(cs %>% filter(administrative_level_3 == "Lithuania") %>% select(-administrative_level_3, - municipality_code, - day) - oo %>% select(-day)))

lvl3 <- cs  %>% filter(administrative_level_3 != "Lithuania") %>%
    left_join(tt %>% select(-municipality_code)) %>% left_join(adm %>% select(-municipality_name)) %>%
    left_join(iii) %>%
    mutate(administrative_level_2 = ifelse(is.na(administrative_level_2), "Unknown",administrative_level_2)) %>%
    mutate(tests_negative = fixNA(tests_negative),
           tests_positive = fixNA(tests_positive),
           tests_positive_repeated = fixNA(tests_positive_repeated),
           tests_positive_new = fixNA(tests_positive_new),
           tests_total= fixNA(tests_total),
           tests_mobile_posts = fixNA(tests_mobile_posts),
           cumulative_tests = fixNA(cumulative_tests),
           population = fixNA(population),
           imported_daily = fixNA(imported_daily))



lvl31 <- lvl3 %>% select(day, administrative_level_2, administrative_level_3, municipality_code,
                    confirmed = confirmed_cases_cumulative, tests = cumulative_tests,
                    deaths = deaths_cumulative, other_deaths = other_deaths_cumulative,
                    recovered = recovered_cases_cumulative, active = active_cases,
                    confirmed_daily = confirmed_cases, tests_daily = tests_total, tests_mobile_daily = tests_mobile_posts,
                    deaths_daily = deaths,
                    other_deaths_daily = other_deaths, recovered_daily = recovered_cases,
                    tests_positive_new_daily = tests_positive_new,
                    tests_positive_repeated_daily = tests_positive_repeated,
                    imported_daily, population)

lvl2 <- lvl31 %>% select(-administrative_level_3, -municipality_code) %>%
    group_by(day, administrative_level_2) %>% summarise_all(sum)

lvl1 <- lvl2 %>% select(-administrative_level_2) %>% summarise_all(sum)

lvl11 <- lvl1 %>% left_join(hosp1) %>%
    mutate(hospitalized = fixNA(hospitalized),
           icu = fixNA(icu),
           ventilated = fixNA(ventilated),
           oxygen = fixNA(oxygen))



add_stats <- function(dt) {
    dt %>% select(day,region, confirmed_daily, tests_daily, tests_positive_new_daily, deaths_daily, other_deaths_daily, population) %>%
        arrange(region, day) %>% group_by(region) %>%
        mutate(cases_sum7 = rollsum(confirmed_daily, 7, fill = NA, align = "right"),
               cases_sum14 = rollsum(confirmed_daily, 14, fill = NA, align = "right"),
               test_sum7 = rollsum(tests_daily, 7, fill = NA, align = "right"),
               deaths_sum14 = rollsum(deaths_daily, 14, fill = NA, align = "right"),
               other_deaths_sum14 = rollsum(other_deaths_daily, 14, fill = NA, align = "right"),
               tpn_sum7 = rollsum(tests_positive_new_daily, 7, fill = NA, align = "right"),
               tpn_sum14 = rollsum(tests_positive_new_daily, 14, fill = NA, align = "right"),
               tpr_confirmed = round(100*cases_sum7/test_sum7,2),
               tpr_tpn =round(100*tpn_sum7/test_sum7,2),
               confirmed_100k = cases_sum14/population*100000,
               tpn_100k = tpn_sum14/population*100000,
               deaths_100k = deaths_sum14/population*100000,
               other_deaths_100k = other_deaths_sum14/population*100000,
               all_deaths_100k = (deaths_sum14+other_deaths_sum14)/population*100000,
               confirmed_growth_weekly = round(100*(cases_sum7/lag(cases_sum7,7)-1),2),
               tpn_growth_weekly = round(100*(tpn_sum7/lag(tpn_sum7,7)-1),2),
               tpr_confirmed_diff_weekly = tpr_confirmed-lag(tpr_confirmed, 7),
               tpr_tpn_diff_weekly = tpr_tpn - lag(tpr_tpn, 7),
               confirmed_100k_growth_weekly=round(100*(confirmed_100k/lag(confirmed_100k,7) - 1),2),
               tpn_100k_growth_weekly=round(100*(tpn_100k/lag(tpn_100k,7) - 1),2),
               deaths_100k_growth_weekly=round(100*(deaths_100k/lag(deaths_100k,7) - 1),2),
               other_deaths_100k_growth_weekly=round(100*(other_deaths_100k/lag(other_deaths_100k,7) - 1),2),
               all_deaths_100k_growth_weekly=round(100*(all_deaths_100k/lag(all_deaths_100k,7) - 1),2)
        ) %>% select(-(confirmed_daily:tpn_sum14)) %>% ungroup
}

lvl31_stats <- lvl31 %>% rename(region = administrative_level_3) %>% add_stats %>% rename(administrative_level_3 = region)
lvl2_stats <- lvl2 %>% filter(administrative_level_2!="Unknown") %>% rename(region = administrative_level_2) %>% add_stats %>%
    rename(administrative_level_2 = region)
lvl11_stats <- lvl1 %>% mutate(region = "Lithuania") %>% add_stats %>% select(-region)

lvl32 <- lvl31 %>% left_join(lvl31_stats)
lvl21 <- lvl2 %>% left_join(lvl2_stats)
lvl12 <- lvl11 %>% left_join(lvl11_stats)

lvl32 %>% arrange(day, municipality_code) %>% select(-municipality_code) %>%  write.csv("data/lt-covid19-level3.csv", row.names = FALSE)
lvl21 %>% write.csv("data/lt-covid19-level2.csv", row.names = FALSE)
lvl12 %>% write.csv("data/lt-covid19-country.csv", row.names = FALSE)

