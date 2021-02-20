library(httr)
library(rvest)
library(dplyr)
library(lubridate)
library(stringr)

source("R/functions.R")

osp1 <- read.csv("https://opendata.arcgis.com/datasets/d49a63c934be4f65a93b6273785a8449_0.csv")

osp1 %>% arrange(date, municipality_code) %>% write.csv("raw_data/osp/osp_covid19_stats.csv", row.names = FALSE)


osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(date)))

adm <- read.csv("raw_data/administrative_levels.csv")

osp3 <- osp2 %>% inner_join(adm)

if(nrow(osp3) == nrow(osp2)) {

    osp4 <- osp3 %>% select(day, municipality_code, administrative_level_3,
                            confirmed_cases=incidence, active_cases=active_sttstcl, active_cases_de_jure = active_de_jure,
                            confirmed_cases_cumulative = cumulative_totals, recovered_cases_cumulative = recovered_sttstcl, dead_cases_cumulative = dead_cases,
                            recovered_cases_de_jure_cumulative = recovered_de_jure,
                            deaths_1_daily = daily_deaths_def1, deaths_2_daily= daily_deaths_def2, deaths_3_daily = daily_deaths_def3, deaths_population_daily = daily_deaths_all,
                    tests_positive = dgn_pos_day, tests_total = dgn_tot_day, tests_mobile = dgn_tot_day_gmp,
                    tests_pcr = pcr_tot_day, tests_ag = ag_tot_day, tests_ab = ab_tot_day,
                    tests_pcr_positive = pcr_pos_day, tests_ag_positive = ag_pos_day, tests_ab_positive = ab_tot_day) %>%
        arrange(day, municipality_code)

    osp4 %>% write.csv("data/osp/lt-covid19-stats.csv", row.names = FALSE)


}


