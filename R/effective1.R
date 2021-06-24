library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(EpiEstim)

tt <- read.csv("data/lt-covid19-tests.csv", stringsAsFactors = FALSE) %>% mutate(day = ymd(day))

last_day <- max(aa$day)

ag <- function(x) (c(x[1], diff(x)))
dt <- tt %>%
  select(day, incidence = tests_positive_new) %>%
  group_by(day) %>%
  summarise(incidence = sum(incidence))

incidence_data <- dt %>% select(date = day, I = incidence)
ltR <- estimate_R(incidence_data,
  method = "uncertain_si",
  config = make_config(list(
    mean_si = 4.8, std_mean_si = 3.0,
    min_mean_si = 2, max_mean_si = 7.5,
    std_si = 3.0, std_std_si = 1.0,
    min_std_si = 0.5, max_std_si = 4.0,
    n1 = 1000, n2 = 1000
  ))
)
# dput(ltR, "raw_data/effectiveR/ltR.R")

RR <- ltR$R

RR[, 1] <- RR[, 2]
RR[, 2] <- dt$day[RR[, 1]]

colnames(RR)[1:2] <- c("t_end", "day")
RR <- RR[, -1]
# RR %>% write.csv("data/lt-covid19-effective-R.csv", row.names = FALSE)
