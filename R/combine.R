library(lubridate)
library(dplyr)
library(tidyr)

fns <- dir("total", pattern = "[0-9]+.csv", full.names = TRUE)

dt <- fns %>% lapply(read.csv, stringsAsFactor = FALSE) %>%
    bind_rows %>% arrange(country,day) %>% fill(under_observation) %>%
    write.csv("data/lt-covid19-total.csv", row.names = FALSE)

fns <- dir("daily", pattern = "[0-9]+.csv", full.names = TRUE)

dt <- fns %>% lapply(read.csv, stringsAsFactor = FALSE) %>%
    bind_rows  %>%
    write.csv("data/lt-covid19-daily.csv", row.names = FALSE)


fns <- dir("tests", pattern = "[0-9]+.csv", full.names = TRUE)

dtl <- fns %>% lapply(read.csv, stringsAsFactor = FALSE) %>%
    bind_rows %>% arrange(day, laboratory)

ln <- read.csv("tests/laboratory_names.csv", stringsAsFactors = FALSE)

lrn <- unique(dtl$laboratory)

lr <- setdiff(lrn,intersect(lrn,ln$lab_reported))
if (length(lr) > 0) {
    warning("New laboratories: ", paste(lr, collapse = ", "))
    ln <- bind_rows(ln, data.frame(lab_reported = lr, lab_actual = lr, stringsAsFactors = FALSE))
    write.csv(ln, "tests/laboratory_names.csv", row.names = FALSE)
}

ln <- ln %>% rename(laboratory=lab_reported)

dtl <- dtl %>% inner_join(ln, by = "laboratory")

oo <- dtl %>% select(-laboratory) %>% rename(laboratory = lab_actual) %>%
    group_by(day, laboratory) %>% summarise_all(sum)


write.csv(oo,"data/lt-covid19-laboratory-total.csv", row.names = FALSE)
