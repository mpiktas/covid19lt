library(dplyr)
library(lubridate)

dd0 <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day))
tt0 <- read.csv("data/lt-covid19-total.csv") %>% mutate(day = ymd(day))
ii <- read.csv("data/lt-covid19-individual.csv") %>% mutate(day = ymd(day))
iit <- read.csv("data/lt-covid19-individual-daily.csv") %>% mutate(day = ymd(day))

md <- max(dd0$day)
mi <- max(ii$day)

if(md > mi) {
    dd <-dd0 %>% filter(day <= mi)
    tt <- tt0 %>% filter(day <= mi)
    dd1 <- dd0 %>% filter(day > mi)
    tt1 <- tt %>% filter(day > mi)
} else {
    dd <- dd0
    tt <- tt0
}


ii1 <- ii %>% group_by(day) %>% summarize(incidence = n(),
                                          imported_daily = sum(imported == "Taip"))


fixNA <- function(x, fix = 0) {
    x[is.na(x)] <- fix
    x
}

diff1 <- function(x) {
    c(x[1],diff(x))
}


ii2 <- tt %>% select(day, recovered, deaths, tested, under_observation) %>% left_join(ii1) %>%
    mutate(incidence = fixNA(incidence), imported_daily = fixNA(imported_daily)) %>%
    mutate(confirmed = cumsum(incidence), imported = cumsum(imported_daily))

ii3 <- ii2 %>% left_join(dd %>% select(day, deaths_different, quarantined)) %>%
     mutate(deaths_different = fixNA(deaths_different),tests_daily = diff1(tested))

ii4 <- ii3 %>% left_join(iit %>% select(day, hospitalized, intensive, rec0 = recovered, dd1 = deaths_different, dd0 = deaths)) %>%
            mutate(deaths_different = ifelse(is.na(dd1), deaths_different, dd1)) %>% select(-dd1) %>%
            mutate(deaths = ifelse(is.na(dd0), deaths, dd0)) %>% select(-dd0) %>%
            mutate(recovered = ifelse(is.na(rec0), recovered, rec0)) %>% select(-rec0) %>%
            mutate(active = confirmed - recovered - deaths - deaths_different)


ii5 <- ii4 %>% select(day, confirmed, deaths, deaths_different, recovered, active, imported, tested,
                      incidence, tests_daily, imported_daily, quarantined, hospitalized, intensive)

if(md > mi) {
    ##assume only one day is missing
    dd2 <- dd1 %>% select(day, confirmed, deaths, deaths_different, recovered, active,
                          tested = total_tests, incidence, tests_daily = daily_tests, quarantined)
    id <- diff(dd0$imported0601)
    dd2$imported_daily <- id[length(id)]
    #dd2$imported <- ii5$import
}

ii5 %>% write.csv("data/lt-covid19-aggregate.csv", row.names = FALSE)


