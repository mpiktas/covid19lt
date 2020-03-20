library(lubridate)
library(dplyr)

fns <- dir("total", pattern="[0-9]+.csv", full.names = TRUE)

dt <- fns %>% lapply(read.csv, stringsAsFactor=FALSE) %>%
    bind_rows %>% arrange(country,day) %>%
    write.csv("total/lt-covid19-total.csv", row.names = FALSE)
