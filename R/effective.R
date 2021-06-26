library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(EpiEstim)

aa <- read.csv("data/lt-covid19-country.csv", stringsAsFactors = FALSE) %>%
  mutate(day = ymd(day))
last_day <- max(aa$day)

ag <- function(x) (c(x[1], diff(x)))
dt <- aa %>%
  mutate(incidence = confirmed_daily) %>%
  select(day, confirmed, incidence) %>%
  mutate(day = ymd(day), w = ifelse(incidence == 0, 0, 1))
dtf <- dt
dt <- dt %>%
  filter(day >= "2020-03-11") %>%
  mutate(times = 1:n())

incidence_data <- dt %>% select(date = day, I = incidence)
lt_r <- estimate_R(incidence_data,
  method = "uncertain_si",
  config = make_config(list(
    mean_si = 4.8, std_mean_si = 3.0,
    min_mean_si = 2, max_mean_si = 7.5,
    std_si = 3.0, std_std_si = 1.0,
    min_std_si = 0.5, max_std_si = 4.0,
    n1 = 1000, n2 = 1000
  ))
)
dput(lt_r, "raw_data/effectiveR/lt_r.R")

rr <- lt_r$R

rr[, 1] <- rr[, 2]
rr[, 2] <- dt$day[rr[, 1]]

colnames(rr)[1:2] <- c("t_end", "day")
rr <- rr[, -1]
rr %>% write.csv("data/lt-covid19-effective-R.csv", row.names = FALSE)
