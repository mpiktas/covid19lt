library(lubridate)
library(dplyr)
library(tidyr)

# Do the covid19 totals -------------------------------------------

fn <- dir("raw_data/hospitalization", full.names = TRUE)

fns <- c(fn[grepl("covid_", fn)])

cvh <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>%
  lapply(function(x) ymd_hms(paste(x[4:5], collapse = "_")))

cvh1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), cvh, pt,
  SIMPLIFY = FALSE
) %>%
  bind_rows() %>%
  mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

cvh2 <- cvh1 %>%
  group_by(day) %>%
  filter(downloaded == max(downloaded)) %>%
  ungroup() %>%
  select(day, total,
    oxygen_mask = oxygen,
    ventilated,
    not_intensive = hospitalized_not_intensive,
    intensive,
    hospitalized_not_vaccinated = total_not_vaccinated,
    intensive_not_vaccinated = intensive_not_vaccinated
  )

## Fix various historically accumulated innacuracies in a consistent manner.
## Intensive should always be part of total. Historically that was the case,
## but it changed.

cvh3 <- cvh2 %>% mutate(
  total2 = ifelse(is.na(not_intensive), total + intensive, total),
  not_intensive2 = ifelse(is.na(not_intensive), total, not_intensive),
  total_not_vaccinated = intensive_not_vaccinated + hospitalized_not_vaccinated
)

cvh4 <- cvh3 %>%
  select(-total, -not_intensive) %>%
  rename(total = total2, not_intensive = not_intensive2) %>%
  select(
    day, total,
    oxygen_mask,
    ventilated,
    intensive,
    total_not_vaccinated,
    intensive_not_vaccinated
  )



cvh <- read.csv("data/lt-covid19-hospitals-country.csv") %>%
  mutate(day = ymd(day))
lcvh <- cvh %>% filter(day == max(day))
lcvh4 <- cvh4 %>%
  filter(day == max(day)) %>%
  data.frame()
ss <- identical(lcvh, lcvh4)
if (ss) {
  cat("\nNo hospitalization data\n")
} else {
  write.csv(cvh4, "data/lt-covid19-hospitals-country.csv", row.names = FALSE)
}
