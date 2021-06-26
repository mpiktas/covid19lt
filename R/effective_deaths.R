library(dplyr)
library(tidyr)
library(lubridate)
library(EpiEstim)
library(zoo)

aa <- read.csv("data/lt-covid19-country.csv", stringsAsFactors = FALSE) %>%
  mutate(day = ymd(day))

last_day <- max(aa$day)

dt0 <- aa %>%
  select(day, deaths_daily, other_deaths_daily) %>%
  mutate(
    d7 = rollsum(deaths_daily, 7, fill = 0, align = "right"),
    a7 = rollsum(deaths_daily + other_deaths_daily, 7,
      fill = 0,
      align = "right"
    )
  )

dt <- dt0 %>% select(day, incidence = d7, incidence1 = a7)

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

rr <- lt_r$R

rr[, 1] <- rr[, 2]
rr[, 2] <- dt$day[rr[, 1]]

colnames(rr)[1:2] <- c("t_end", "day")
rr <- rr[, -1]

incidence_data1 <- dt %>% select(date = day, I = incidence1)
lt_r1 <- estimate_R(incidence_data1,
  method = "uncertain_si",
  config = make_config(list(
    mean_si = 4.8, std_mean_si = 3.0,
    min_mean_si = 2, max_mean_si = 7.5,
    std_si = 3.0, std_std_si = 1.0,
    min_std_si = 0.5, max_std_si = 4.0,
    n1 = 1000, n2 = 1000
  ))
)

rr1 <- lt_r1$R

rr1[, 1] <- rr1[, 2]
rr1[, 2] <- dt$day[rr1[, 1]]

colnames(rr1)[1:2] <- c("t_end", "day")
rr1 <- rr1[, -1]

cmp <- rr %>%
  select(day, deaths = `Mean(R)`) %>%
  inner_join(rr1 %>%
    select(day, cases = `Mean(R)`)) %>%
  inner_join(rr1 %>%
    select(day, all_deaths = `Mean(R)`))

xcmp <- xts(cmp %>% select(-day), order.by = cmp$day)

dygraph(xcmp) %>%
  dyOptions(colors = RColorBrewer::brewer.pal(3, "Set1")[c(1, 2, 3)]) %>%
  dyRangeSelector()
