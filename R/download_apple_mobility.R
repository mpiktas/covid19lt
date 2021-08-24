library(dplyr)
library(tidyr)
library(lubridate)
library(glue)

curdate <- ymd(Sys.Date())

dd <- data.frame(date = ymd("2021-08-19") + days(0:20), hotfix = 7 + 0:20)
# begin nolint
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2105HotfixDev8/v3/en-us/applemobilitytrends-2021-04-02.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2104HotfixDev11/v3/en-us/applemobilitytrends-2021-03-21.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2102HotfixDev17/v3/en-us/applemobilitytrends-2021-02-26.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2105HotfixDev19/v3/en-us/applemobilitytrends-2021-04-12.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2106HotfixDev12/v3/en-us/applemobilitytrends-2021-04-17.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2107HotfixDev7/v3/en-us/applemobilitytrends-2021-05-02.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2108HotfixDev14/v3/en-us/applemobilitytrends-2021-05-18.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2109HotfixDev9/v3/en-us/applemobilitytrends-2021-05-29.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2110HotfixDev12/v3/en-us/applemobilitytrends-2021-06-18.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2112HotfixDev22/v3/en-us/applemobilitytrends-2021-07-21.csv
# https://covid19-static.cdn-apple.com/covid19-mobility-data/2115HotfixDev10/v3/en-us/applemobilitytrends-2021-08-22.csv
# end nolint

lap <- lapply(curdate - days(0:2), function(curd) {
  cdd <- dd %>% filter(date == curd)
  cd <- as.character(cdd$date)
  hf <- as.character(cdd$hotfix)
  lnk <- glue::glue("https://covid19-static.cdn-apple.com/covid19-mobility-data/2115HotfixDev{hf}/v3/en-us/applemobilitytrends-{cd}.csv") # nolint
  print(lnk)
  try(read.csv(lnk))
})

ap <- lap[[min(which(sapply(lap, class) != "try-error"))]]

ap1 <- ap %>% filter(region == "Lithuania")

ap2 <- ap1 %>% pivot_longer(-(geo_type:country), # nolint
  names_to = "date", values_to = "value"
)

ap3 <- ap2 %>% mutate(day = ymd(gsub("X", "", date)))

ap4 <- ap3 %>%
  select(day, transportation_type, value) %>%
  pivot_wider(names_from = "transportation_type") %>%
  arrange(day)

ap4 %>% write.csv("data/lt-apple-mobility-data.csv", row.names = FALSE)
