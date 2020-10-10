library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)

raw <- GET("https://nvsc.lrv.lt/lt/visuomenei/nacionalinio-visuomenes-sveikatos-centro-duomenys")
#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)

# Add the totals data -----------------------------------------------------

cd <- html_nodes(oo,".text") %>% html_nodes("li") %>% html_text

cd1 <-  html_nodes(oo,".text") %>% html_nodes("strong") %>% html_text

nums1 <- cd1 %>% str_trim %>% gsub("([0-9]+)( )([0-9+])","\\1\\3",.) %>% gsub("([0-9]+)(.*)","\\1",.) %>% as.integer %>% na.omit

ia1 <- nums1[8]


# Get the tests data ------------------------------------------------------

raw1 <- GET("https://nvsc.lrv.lt/lt/visuomenei/nacionalines-visuomenes-sveikatos-prieziuros-laboratorijos-duomenys")

oo1 <- read_html(raw1)

cd2 <-  html_nodes(oo1,".text") %>% html_nodes("strong") %>% html_text

nums2 <- cd2 %>% str_trim %>% gsub("([0-9]+)( )([0-9+])","\\1\\3",.) %>% gsub("([0-9]+)(.*)","\\1",.) %>% as.integer %>% na.omit

nums <- c(nums1[-8],nums2[1:2])

# Treat and write ---------------------------------------------------------

crtime <- Sys.time()

outd <- gsub(" ","_",gsub("-","",as.character(crtime)))
ndd <- new_day_data %>% select(country, day) %>%
    mutate(confirmed = nums[1],
           active = nums[2],
           incidence = nums[3],
           deaths = nums[4],
           deaths_different = nums[5],
           recovered = nums[6],
           daily_tests = nums[8],
           quarantined = nums[7],
           total_tests = nums[9],
           imported0601 = ia1)
write.csv(ndd, glue::glue("raw_data/sam/lt-covid19-daily_{outd}.csv"), row.names = FALSE)

