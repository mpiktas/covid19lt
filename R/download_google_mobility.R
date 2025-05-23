library(dplyr)
library(tidyr)
library(lubridate)
library(glue)
library(curl)


curl_download("https://www.gstatic.com/covid19/mobility/Region_Mobility_Report_CSVs.zip", destfile = "gm.zip") # nolint
unzip("gm.zip", exdir = "gmtmp")

go2020 <- read.csv("gmtmp/2020_LT_Region_Mobility_Report.csv") %>%
  mutate(day = ymd(date))

go2021 <- read.csv("gmtmp/2021_LT_Region_Mobility_Report.csv") %>%
  mutate(day = ymd(date))

go2022 <- read.csv("gmtmp/2022_LT_Region_Mobility_Report.csv") %>%
  mutate(day = ymd(date))

go <- bind_rows(go2020, go2021, go2022)

file.remove("gm.zip")
unlink("gmtmp", recursive = TRUE)

colnames(go) <- gsub("_percent_change_from_baseline", "", colnames(go))

sav <- read.csv("raw_data/google_level3.csv")
apskr <- read.csv("raw_data/google_level2.csv")
adm <- read.csv("raw_data/administrative_levels.csv")

lv3 <- go %>% filter(sub_region_2 != "")

lv31 <- lv3 %>%
  inner_join(sav) %>%
  inner_join(adm %>% select(administrative_level_2, administrative_level_3))

if (nrow(lv3) == nrow(lv31)) {
  lv32 <- lv31 %>% select(
    administrative_level_2, administrative_level_3, day,
    retail_and_recreation, grocery_and_pharmacy, parks,
    transit_stations, workplaces, residential
  )

  lv32 %>% write.csv("raw_data/google_mobility_lithuania/google_mobility_lithuania_level3.csv", row.names = FALSE) # nolint
}

lv2 <- go %>% filter(sub_region_2 == "" & sub_region_1 != "")
lv21 <- lv2 %>% inner_join(apskr)
if (nrow(lv2) == nrow(lv21)) {
  lv22 <- lv21 %>% select(
    administrative_level_2, day,
    retail_and_recreation, grocery_and_pharmacy, parks,
    transit_stations, workplaces, residential
  )

  lv22 %>% write.csv("raw_data/google_mobility_lithuania/google_mobility_lithuania_level2.csv", row.names = FALSE) # nolint
}


lv1 <- go %>% filter(sub_region_1 == "", sub_region_2 == "")

lv12 <- lv1 %>% select(
  day,
  retail_and_recreation, grocery_and_pharmacy, parks,
  transit_stations, workplaces, residential
)

lv12 %>% write.csv("raw_data/google_mobility_lithuania/google_mobility_lithuania.csv", row.names = FALSE) # nolint
