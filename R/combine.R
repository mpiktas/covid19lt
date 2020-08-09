library(lubridate)
library(dplyr)
library(tidyr)

fns <- dir("total", pattern = "[0-9]+.csv", full.names = TRUE)

fns %>% lapply(read.csv, stringsAsFactor = FALSE) %>%
    bind_rows %>% arrange(country,day) %>% fill(under_observation) %>%
    write.csv("data/lt-covid19-total.csv", row.names = FALSE)

fns <- dir("daily", pattern = "[0-9]+.csv", full.names = TRUE)

fns %>% lapply(read.csv, stringsAsFactor = FALSE) %>%
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

dc <- dtl %>% select(day, created) %>% unique

oo <- dtl %>% select(-laboratory, - created) %>% rename(laboratory = lab_actual) %>%
    group_by(day, laboratory) %>% summarise_all(sum) %>% left_join(dc)


write.csv(oo,"data/lt-covid19-laboratory-total.csv", row.names = FALSE)


##Do sanity checks
##

dd <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day)) %>% arrange(day)

library(testthat)
ld <- dd %>% slice_tail(n = 2)

test_that("Confirmed match", {

    expect_true(ld$incidence[2] + ld$confirmed[1] == ld$confirmed[2])
})

test_that("Tests match", {
    expect_true(ld$daily_tests[2] + ld$total_tests[1] == ld$total_tests[2])

})

test_that("Decomposition is valid", {
    expect_true(ld$confirmed[2] == ld$active[2] + ld$deaths[2] + ld$recovered[2] + ld$deaths_different[2] )
})