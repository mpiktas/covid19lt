library(dplyr)
library(lubridate)

tt <- read.csv("data/lt-covid19-tests.csv") %>% mutate(day = ymd(day))
cs <- read.csv("data/lt-covid19-cases.csv") %>% mutate(day = ymd(day))
ii <- read.csv("data/lt-covid19-individual.csv") %>% mutate(day = ymd(day))
iii <- ii %>% group_by(day, administrative_level_3) %>% summarise(imported_daily = sum(imported == "Taip"))

fixNA <- function(x, fix = 0) {
    x[is.na(x)] <- fix
    x
}

adm <- read.csv("raw_data/administrative_levels.csv")

tt <- tt %>% arrange(administrative_level_3, day) %>% group_by(administrative_level_3) %>% mutate(cumulative_tests = cumsum(tests_total))

cs %>% filter(administrative_level_3 == "Lithuania") %>%
    select(day, confirmed_cases_cumulative, deaths_cumulative) %>%
    left_join(aa %>% select(day, confirmed, deaths)) %>%
    mutate(dc = confirmed_cases_cumulative - confirmed, dd = deaths_cumulative -deaths)

oo <- cs %>%   filter(administrative_level_3!= "Lithuania") %>%select(-municipality_code,-administrative_level_3) %>%
    group_by(day) %>% summarise_all(sum)

sum(abs(cs %>% filter(administrative_level_3 == "Lithuania") %>% select(-administrative_level_3, - municipality_code, - day) - oo %>% select(-day)))

lvl3 <- cs %>% select(-municipality_code) %>% filter(administrative_level_3 != "Lithuania") %>%
    left_join(tt %>% select(-municipality_code)) %>% left_join(adm %>% select(-municipality_name)) %>%
    left_join(iii) %>%
    mutate(administrative_level_2 = ifelse(is.na(administrative_level_2), "Unknown",administrative_level_2)) %>%
    mutate(tests_negative = fixNA(tests_negative),
           tests_positive = fixNA(tests_positive),
           tests_positive_repeated = fixNA(tests_positive_repeated),
           tests_positive_new = fixNA(tests_positive_new),
           tests_total= fixNA(tests_total),
           cumulative_tests = fixNA(cumulative_tests),
           population = fixNA(population),
           imported_daily = fixNA(imported_daily))



lvl31 <- lvl3 %>% select(day, administrative_level_2, administrative_level_3,
                    confirmed = confirmed_cases_cumulative, tests = cumulative_tests,
                    deaths = deaths_cumulative, other_deaths = other_deaths_cumulative,
                    recovered = recovered_cases_cumulative, active = active_cases,
                    confirmed_daily = confirmed_cases, tests_daily = tests_total, deaths_daily = deaths,
                    other_deaths_daily = other_deaths, recovered_daily = recovered_cases,
                    tests_positive_new_daily = tests_positive_new,
                    tests_positive_repeated_daily = tests_positive_repeated,
                    imported_daily, population)

lvl2 <- lvl31 %>% select(-administrative_level_3) %>%
    group_by(day, administrative_level_2) %>% summarise_all(sum)

lvl1 <- lvl2 %>% select(-administrative_level_2) %>% summarise_all(sum)


