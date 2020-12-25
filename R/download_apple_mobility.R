library(dplyr)
library(tidyr)
library(lubridate)
library(glue)

dd <- ymd(Sys.Date())

zz <- dd - days(1:3)

lap <- lapply(zz, function(d) {
    cd <- as.character(d)
    try(read.csv(glue::glue("https://covid19-static.cdn-apple.com/covid19-mobility-data/2023HotfixDev17/v3/en-us/applemobilitytrends-{cd}.csv")))
})

ap <- lap[[min(which(sapply(lap, class)!="try-error"))]]


ap1 <- ap %>% filter(region == "Lithuania")

ap2 <- ap1 %>% pivot_longer(-(geo_type:country), names_to = "date", values_to ="value")

ap3 <- ap2 %>% mutate(day = ymd(gsub("X","",date)))

ap4 <- ap3 %>% select(day, transportation_type, value) %>% pivot_wider(names_from = "transportation_type") %>% arrange(day)

ap4 %>% write.csv("data/lt-apple-mobility-data.csv", row.names = FALSE)

