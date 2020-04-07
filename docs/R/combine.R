library(lubridate)
library(dplyr)
library(tidyr)

fns <- dir("total", pattern = "[0-9]+.csv", full.names = TRUE)

dt <- fns %>% lapply(read.csv, stringsAsFactor = FALSE) %>%
    bind_rows %>% arrange(country,day) %>% fill(under_observation) %>%
    write.csv("total/lt-covid19-total.csv", row.names = FALSE)


fns <- dir("tests", pattern = "[0-9]+.csv", full.names = TRUE)

dt <- fns %>% lapply(read.csv, stringsAsFactor = FALSE) %>%
    bind_rows %>% arrange(day, laboratory)  %>%
    write.csv("tests/lt-covid19-laboratory-total.csv", row.names = FALSE)
