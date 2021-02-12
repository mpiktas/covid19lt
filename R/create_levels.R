library(dplyr)
library(lubridate)
library(zoo)

tt <- read.csv("data/lt-covid19-tests.csv") %>% mutate(day = ymd(day))
cs <- read.csv("data/lt-covid19-cases.csv") %>% mutate(day = ymd(day))
dd <- read.csv("data/lt-covid19-deaths.csv") %>% mutate(day = ymd(day))

cvh <- read.csv("data/lt-covid19-hospitalized.csv") %>% mutate(day = ymd(day))
vcn <- read.csv("data/lt-covid19-vaccinated.csv") %>% mutate(day = ymd(day))
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
dd <- dd %>%  arrange(administrative_level_3, day) %>% group_by(administrative_level_3) %>% mutate(deaths_1 = cumsum(deaths_1_daily),
                                                                                                   deaths_2 = cumsum(deaths_2_daily),
                                                                                                   deaths_3 = cumsum(deaths_3_daily))
#cs %>% filter(administrative_level_3 == "Lithuania") %>%
#    select(day, confirmed_cases_cumulative, deaths_cumulative) %>%
#    left_join(aa %>% select(day, confirmed, deaths)) %>%
#    mutate(dc = confirmed_cases_cumulative - confirmed, dd = deaths_cumulative -deaths)

oo <- cs %>%   filter(administrative_level_3!= "Lithuania") %>%select(-municipality_code,-administrative_level_3) %>%
    group_by(day) %>% summarise_all(sum)

if("Lithuania" %in% cs$administrative_level_3) {
    sum(abs(cs %>% filter(administrative_level_3 == "Lithuania") %>% select(-administrative_level_3, - municipality_code, - day) - oo %>% select(-day)))
}

lvl3 <- cs  %>% filter(administrative_level_3 != "Lithuania") %>%
    left_join(tt %>% select(-municipality_code)) %>% left_join(adm %>% select(-municipality_name)) %>%
    left_join(vcn %>% select(-municipality_code) %>% filter(administrative_level_3 != "Lithuania")) %>%
    left_join(dd %>% select(-municipality_code, -tests_daily, -tests_positive_daily) %>% filter(administrative_level_3 != "Lithuania")) %>%
    mutate(administrative_level_2 = ifelse(is.na(administrative_level_2), "Unknown",administrative_level_2)) %>%
    mutate(tests_positive = fixNA(tests_positive),
           tests_total= fixNA(tests_total),
           population = fixNA(population)) %>%
    rename(vaccinated_1_daily = vaccinated_daily_1,
           vaccinated_2_daily = vaccinated_daily_2) %>%
    mutate(vaccinated_1 = fixNA(vaccinated_1),
           vaccinated_2 = fixNA(vaccinated_2),
           vaccinated_1_daily = fixNA(vaccinated_1_daily),
           vaccinated_2_daily = fixNA(vaccinated_2_daily))



lvl31 <- lvl3 %>% select(day, administrative_level_2, administrative_level_3, municipality_code,
                    confirmed = confirmed_cases_cumulative, tests = cumulative_tests,
                    deaths = deaths_3,
                    deaths_1,
                    deaths_2,
                    recovered = recovered_cases_cumulative, active = active_cases,
                    dead_cases = dead_cases_cumulative,
                    vaccinated_1, vaccinated_2,
                    confirmed_daily = confirmed_cases, tests_daily = tests_total,
                    tests_positive_daily = tests_positive,
                    deaths_daily = deaths_3_daily,
                    deaths_1_daily,
                    deaths_2_daily,
                    recovered_daily = recovered_cases,
                    dead_cases_daily = dead_cases,
                    vaccinated_1_daily, vaccinated_2_daily,
                    population)

lvl2 <- lvl31 %>% select(-administrative_level_3, -municipality_code) %>%
    group_by(day, administrative_level_2) %>% summarise_all(sum)

lvl1 <- lvl2 %>% select(-administrative_level_2) %>% summarise_all(sum)

lvl11 <- lvl1 %>% left_join(hosp1) %>%
    mutate(hospitalized = fixNA(hospitalized),
           icu = fixNA(icu),
           ventilated = fixNA(ventilated),
           oxygen = fixNA(oxygen))



add_stats <- function(dt) {
    dt %>% select(day,region, confirmed_daily, tests_daily, tests_positive_daily, deaths_daily, deaths_1_daily, deaths_2_daily,
                  vaccinated_1, vaccinated_2, population) %>%
        arrange(region, day) %>% group_by(region) %>%
        mutate(cases_sum7 = rollsum(confirmed_daily, 7, fill = NA, align = "right"),
               cases_sum14 = rollsum(confirmed_daily, 14, fill = NA, align = "right"),
               test_sum7 = rollsum(tests_daily, 7, fill = NA, align = "right"),
               test_sum14 = rollsum(tests_daily, 14, fill = NA, align = "right"),
               deaths_sum14 = rollsum(deaths_daily, 14, fill = NA, align = "right"),
               deaths_sum7 = rollsum(deaths_daily, 7, fill = NA, align = "right"),
               deaths_1_sum14 = rollsum(deaths_1_daily, 14, fill = NA, align = "right"),
               deaths_1_sum7 = rollsum(deaths_1_daily, 7, fill = NA, align = "right"),
               deaths_2_sum14 = rollsum(deaths_2_daily, 14, fill = NA, align = "right"),
               deaths_2_sum7 = rollsum(deaths_2_daily, 7, fill = NA, align = "right"),
               tpn_sum7 = rollsum(tests_positive_daily, 7, fill = NA, align = "right"),
               tpn_sum14 = rollsum(tests_positive_daily, 14, fill = NA, align = "right"),
               tpr_tpn =round(100*tpn_sum7/test_sum7,2),
               confirmed_100k = cases_sum14/population*100000,
               tpn_100k = tpn_sum14/population*100000,
               deaths_100k = deaths_sum14/population*100000,
               deaths_1_100k = deaths_1_sum14/population*100000,
               deaths_2_100k = deaths_2_sum14/population*100000,
               tests_100k = test_sum14/population*100000,
               confirmed_growth_weekly = round(100*(cases_sum7/lag(cases_sum7,7)-1),2),
               tpn_growth_weekly = round(100*(tpn_sum7/lag(tpn_sum7,7)-1),2),
               tpr_tpn_diff_weekly = tpr_tpn - lag(tpr_tpn, 7),
               confirmed_100k_growth_weekly=round(100*(confirmed_100k/lag(confirmed_100k,7) - 1),2),
               tpn_100k_growth_weekly=round(100*(tpn_100k/lag(tpn_100k,7) - 1),2),
               deaths_growth_weekly=round(100*(deaths_sum7/lag(deaths_sum7,7) - 1),2),
               deaths_1_growth_weekly=round(100*(deaths_1_sum7/lag(deaths_1_sum7,7) - 1),2),
               deaths_2_growth_weekly=round(100*(deaths_2_sum7/lag(deaths_2_sum7,7) - 1),2),
               tests_growth_weekly = round(100*(test_sum7/lag(test_sum7,7)-1),2),
               vaccinated_1_percent = round(vaccinated_1/population*100,2),
               vaccinated_2_percent = round(vaccinated_2/population*100,2)
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

