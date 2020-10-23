library(lubridate)
library(dplyr)
library(tidyr)
library(testthat)



# Do laboratory data ------------------------------------------------------

fns <- dir("raw_data/laboratory", pattern = "[0-9]+.csv", full.names = TRUE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[3:4],collapse="_")))

lbd <- lapply(fns, read.csv, stringsAsFactor = FALSE)

dtl0 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), lbd, pt, SIMPLIFY = FALSE) %>% bind_rows %>%
    select(-day) %>% mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

dtl <-  dtl0 %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    select(day, laboratory,
           tested_all, tested_mobile,
           negative_all, negative_mobile,
           positive_all, positive_mobile, positive_retested, positive_new, not_tested, not_tested_mobile) %>%
    arrange(day, laboratory)


ln <- read.csv("raw_data/laboratory/laboratory_names.csv", stringsAsFactors = FALSE)

lrn <- unique(dtl$laboratory)

lr <- setdiff(lrn,intersect(lrn,ln$lab_reported))
if (length(lr) > 0) {
    warning("New laboratories: ", paste(lr, collapse = ", "))
    ln <- bind_rows(ln, data.frame(lab_reported = lr, lab_actual = lr, stringsAsFactors = FALSE))
    write.csv(ln, "raw_data/laboratory/laboratory_names.csv", row.names = FALSE)
}

ln <- ln %>% rename(laboratory=lab_reported)

dtl <- dtl %>% inner_join(ln, by = "laboratory")

oo <- dtl %>% select(-laboratory) %>% rename(laboratory = lab_actual) %>%
    group_by(day, laboratory) %>% summarise_all(sum) %>% ungroup %>% arrange(day, laboratory)

lbt <- read.csv("data/lt-covid19-laboratory-total.csv") %>% mutate(day = ymd(day))

llbt <- lbt %>% filter(day == max(day)) %>% arrange(laboratory)

loo <- oo  %>% filter(day == max(day)) %>% arrange(laboratory)

ss <- identical(data.frame(llbt)[,-1], data.frame(loo)[,-1])
if(ss) {
    cat("\nNo new data for laboratory\n")
} else {
    write.csv(oo,"data/lt-covid19-laboratory-total.csv", row.names = FALSE)
}


# Create daily and total files --------------------------------------------

fns <- dir("raw_data/sam", pattern = "daily", full.names = TRUE)

samd <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[3:4],collapse="_")))

sam <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm) %>% select(-day), samd, pt, SIMPLIFY = FALSE) %>% bind_rows  %>% mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

dl <-  sam %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    mutate(country = "Lithuania") %>%
    select(country, day, incidence, daily_tests, confirmed, active, deaths, recovered, quarantined, total_tests, deaths_different, imported0601, under_observation) %>%
    arrange(day)

tst <- dl %>% select(day, daily_tests, total_tests)
lbt <- oo %>% group_by(day) %>% summarise(lab_total = sum(tested_all, na.rm = TRUE))

tst <- tst %>% left_join(lbt, by = "day") %>%
    mutate(tests_daily = ifelse(is.na(lab_total), daily_tests, lab_total), tested = cumsum(tests_daily))

tl <- dl %>% left_join(tst %>% select(day, tested)) %>% select(-confirmed) %>% mutate(confirmed = cumsum(incidence), country = "Lithuania") %>%
    select(country, day, confirmed, deaths, recovered, tested , under_observation, quarantined)

dd <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day)) %>% arrange(day)
ld <- dd %>% filter(day == max(day))
ldl <- dl  %>% filter(day == max(day))
ss <- identical(ld[1,-2:-1], data.frame(ldl[1,-2:-1]))

if(ss) {
    cat("\nNo new data for daily\n")
} else {
    dl %>% write.csv("data/lt-covid19-daily.csv", row.names = FALSE)
    tl %>% write.csv("data/lt-covid19-total.csv", row.names = FALSE)
}


