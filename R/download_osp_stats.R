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
                    tests_pcr_positive = pcr_pos_day, tests_ag_positive = ag_pos_day, tests_ab_positive = ab_pos_day) %>%
        arrange(day, municipality_code)

    osp4 %>% write.csv("data/osp/lt-covid19-stats.csv", row.names = FALSE)


}

if(FALSE) {
    bb <- osp2
    zz <- bb %>% filter(day == max(day)) %>% select(municipality_code, municipality_name, map_colors) %>% inner_join(adm)
    dp0 <- read.csv("data/lt-covid19-level3.csv") %>% mutate(day = ymd(day)) %>% filter(day == max(day))
    cn <- read.csv("data/lt-covid19-country.csv") %>% mutate(day = ymd(day)) %>% filter(day == max(day)) %>% mutate(administrative_level_3 = "Lietuva", administrative_level_2 = "Lietuva")

    dp00 <- dp0 %>% bind_rows(cn)

    dp <- dp00 %>% filter(administrative_level_3!="Unknown") %>% select(Savivaldybė = administrative_level_3,
                                                                        Apskritis = administrative_level_2,
                                                                        `Atvejai_100k` = confirmed_100k,
                                                                        `Atvejų augimas` = confirmed_growth_weekly,
                                                                        `Teigiamų tyrimų dalis` = tpr_dgn,
                                                                        `Mirtys_100k` = deaths_100k,
                                                                        `Testai_100k` = tests_100k,
                                                                        `Paskiepyta pirma doze (%)` = vaccinated_1_percent, `Paskiepyta (%)`= vaccinated_2_percent, Populiacija = population ) %>% arrange(-Populiacija)

    zz <- zz %>% mutate(administrative_level_3  =ifelse(administrative_level_3 == "Lithuania","Lietuva",administrative_level_3))
    dp1 <- dp %>% left_join(zz %>% select(Savivaldybė = administrative_level_3, Spalva = map_colors))

    dp2 <- dp1 %>% mutate(`Pradinis ugdymas` = ifelse(Spalva %in% c("Žalia A","Geltona B1", "Geltona B2", "Raudona C2", "Raudona C1"),"Taip","Ne"),
                          `Pagrindinis, vidurinis ugdymas` = ifelse(Spalva %in% c("Žalia A","Geltona B1", "Geltona B2"),"Taip","Ne"),
                          `Abiturientai` = ifelse(Spalva %in% c("Žalia A","Geltona B1", "Geltona B2","Raudona C1"),"Taip","Ne"),
                          )

}
