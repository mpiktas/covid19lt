library(dplyr)
library(lubridate)

# Do the same for another layer -------------------------------------------

fn <- dir("raw_data/rc", full.names = TRUE)

fns <- c(fn[grepl("savivaldybiu_", fn)])

savd <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x) ymd_hms(paste(x[3:4], collapse = "_")))

svd1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), savd, pt, SIMPLIFY = FALSE) %>%
  bind_rows() %>%
  select(-X) %>%
  mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

svd2 <- svd1 %>%
  group_by(day) %>%
  filter(downloaded == max(downloaded)) %>%
  ungroup() %>%
  select(day,
    administrative_level_3 = SAV_PAV,
    confirmed = TEIGIAMI,
    confirmed_100k = ATVEJAI_10000_GYV,
    confirmed_14 = ATVEJAI_14,
    confirmed_14_100k = ATVEJAI_14_100000,
    confirmed_male = VYRAI,
    confirmed_female = MOTERYS,
    active = GYDOMA,
    active_100k = GYDOMA_10000_GYV,
    recovered = PASVEIKO,
    deaths = MIRE,
    population = GYV_SK,
    updated = ATNUJINTA
  )

rr <- read.csv("data/lt-covid19-regions.csv") %>% mutate(day = ymd(day))

lrr <- rr %>%
  filter(day == max(day)) %>%
  arrange(administrative_level_3)
lsvd <- svd2 %>%
  filter(day == max(day)) %>%
  arrange(administrative_level_3)

ss <- identical(lrr[, -1], data.frame(lsvd[, -1]))

if (ss) {
  cat("\nNo new data for regions\n")
} else {
  write.csv(svd2, "data/lt-covid19-regions.csv", row.names = FALSE)
}


# Do age groups -----------------------------------------------------------

fn <- dir("raw_data/rc", full.names = TRUE)

fns <- c(fn[grepl("amziaus_grupes_", fn)])

agr <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x) ymd_hms(paste(x[4:5], collapse = "_")))

ag1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), agr, pt, SIMPLIFY = FALSE) %>%
  bind_rows() %>%
  select(-X) %>%
  mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

ag2 <- ag1 %>%
  group_by(day) %>%
  filter(downloaded == max(downloaded)) %>%
  ungroup() %>%
  select(day,
    age_group = AMZIAUSGRUPE,
    confirmed = TEIGIAMI,
    confirmed_100k = ATVEJAI_VISI_100000,
    confirmed_male = VYRAI,
    confirmed_male_100k = ATVEJAI_V_100000,
    confirmed_female = MOTERYS,
    confirmed_female_100k = ATVEJAI_M_100000,
    other = KITA,
    total = VISO,
    population = GYV_SKAIC,
    population_male = GYV_SKAIC_V,
    population_female = GYV_SKAIC_M
  )

ag <- read.csv("data/lt-covid19-agegroups.csv") %>% mutate(day = ymd(day))

lag <- ag %>%
  filter(day == max(day)) %>%
  arrange(age_group)
lag2 <- ag2 %>%
  filter(day == max(day)) %>%
  arrange(age_group)

ss <- identical(lag[, -1], data.frame(lag2[, -1]))

if (ss) {
  cat("\nNo new data for age groups\n")
} else {
  write.csv(ag2, "data/lt-covid19-agegroups.csv", row.names = FALSE)
}

# Do profession -----------------------------------------------------------

fn <- dir("raw_data/rc", full.names = TRUE)

fns <- c(fn[grepl("profesijos", fn)])

pr <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x) ymd_hms(paste(x[3:4], collapse = "_")))

pr1 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), pr, pt, SIMPLIFY = FALSE) %>%
  bind_rows() %>%
  select(-X) %>%
  mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

pr2 <- pr1 %>%
  group_by(day) %>%
  filter(downloaded == max(downloaded)) %>%
  ungroup() %>%
  select(day,
    profession = PROFESIJA,
    confirmed = TEIGIAMI,
    confirmed_male = VYRAI,
    confirmed_female = MOTERYS,
    active = GYDOMA,
    recovered = PASVEIKO,
    deaths = MIRE,
    updated = ATNAUJINIMODATA,
  )

pr <- read.csv("data/lt-covid19-professions.csv") %>% mutate(day = ymd(day))

opr <- pr %>%
  filter(day == max(day)) %>%
  arrange(profession)
opr2 <- pr2 %>%
  filter(day == max(day)) %>%
  arrange(profession)

ss <- identical(opr[, -1], data.frame(opr2[, -1]))
if (ss) {
  cat("\nNo new data for professions\n")
} else {
  write.csv(pr2, "data/lt-covid19-professions.csv", row.names = FALSE)
}
