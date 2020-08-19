##Do sanity checks

library(testthat)
dd <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day)) %>% arrange(day)
lb <- read.csv("data/lt-covid19-laboratory-total.csv") %>% mutate(day = ymd(day)) %>% arrange(day)

ld <- dd %>% slice_tail(n = 2)

lbl <- lb %>% filter(day == max(dd$day))

test_that("Confirmed match", {

    expect_true(ld$incidence[2] + ld$confirmed[1] == ld$confirmed[2])
})

test_that("Tests match", {
    expect_true(ld$daily_tests[2] + ld$total_tests[1] == ld$total_tests[2])

})

test_that("Decomposition is valid", {
    expect_true(ld$confirmed[2] == ld$active[2] + ld$deaths[2] + ld$recovered[2] + ld$deaths_different[2] )
})

test_that("There are more positive tests than incidence", {
    if(nrow(lbl) > 0 ) {
        expect_true(sum(lbl$positive_all) >= ld$incidence[2])
    }
})