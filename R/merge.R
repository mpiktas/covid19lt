library(dplyr)
library(lubridate)

dd <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day))
tt <- read.csv("data/lt-covid19-total.csv") %>% mutate(day = ymd(day))
ii <- read.csv("data/lt-covid19-individual.csv") %>% mutate(day = ymd(day))

ii1 <- ii %>% group_by(day) %>% summarize(incidence = n(),
                                          imported_daily = sum(imported == "Taip"))

iit <- ii %>% summarize(confirmed = n(), hospitalized = sum(hospitalized == "Taip" & status == "Gydomas"),
                                         intensive = sum(intensive == "Taip" & status == "Gydomas"),
                                          active = sum(status == "Gydomas"),
                                          deaths = sum(status == "Mirė"),
                                          deaths_different = sum(status == "Kita"),
                                          recovered = sum(status == "Pasveiko"),
                                          imported = sum(imported == "Taip"))


iit <- iit %>% mutate(day = max(ii$day), incidence = ii1$incidence[ii1$day == max(ii1$day)])

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
     mutate(deaths_different = fixNA(deaths_different),tests_daily = diff1(tested),
            active = confirmed - recovered - deaths - deaths_different)

ii4 <- ii3 %>% select(day, confirmed, deaths, deaths_different, recovered, active, imported, tested,
                      incidence, tests_daily, imported_daily, quarantined)

ii5 <- ii4 %>% left_join(iit %>% select(day, hospitalized, intensive))





