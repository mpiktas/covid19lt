library(dplyr)
library(lubridate)

dd <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day))
tt <- read.csv("data/lt-covid19-total.csv") %>% mutate(day = ymd(day))
ii <- read.csv("data/lt-covid19-individual.csv") %>% mutate(day = ymd(day))

ii1 <- ii %>% group_by(day) %>% summarize(incidence = n(),
                                          imported = sum(imported == "Taip"))

iit <- ii %>% summarize(confirmed = n(), hospitalized = sum(hospitalized == "Taip" & status == "Gydomas"),
                                         intensive = sum(intensive == "Taip" & status == "Gydomas"),
                                          active = sum(status == "Gydomas"),
                                          deaths = sum(status == "Mirė"),
                                          deaths_different = sum(status == "Kita"),
                                          recovered = sum(status == "Pasveiko"),
                                          imported = sum(imported == "Taip"))



iit <- iit %>% mutate(day = max(ii$day), incidence = ii1$incidence[ii1$day == max(ii1$day)])



