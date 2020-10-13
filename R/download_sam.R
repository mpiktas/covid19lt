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


# Get the tests and laboratory data ------------------------------------------------------

raw1 <- GET("https://nvsc.lrv.lt/lt/visuomenei/nacionalines-visuomenes-sveikatos-prieziuros-laboratorijos-duomenys")

oo1 <- read_html(raw1)

cd2 <-  html_nodes(oo1,".text") %>% html_nodes("strong") %>% html_text

nums2 <- cd2 %>% str_trim %>% gsub("([0-9]+)( )([0-9+])","\\1\\3",.) %>% gsub("([0-9]+)(.*)","\\1",.) %>% as.integer %>% na.omit

nums <- c(nums1[-8],nums2[1:2])

# Treat and write ---------------------------------------------------------

crtime <- Sys.time()

outd <- gsub(" ","_",gsub("-","",as.character(crtime)))
ndd <- data.frame(country = "Lithuania", day = rep(floor_date(crtime, unit = "days")-days(1))) %>%
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



# Do the laboratory tables data -------------------------------------------

trs <- html_nodes(oo1, "tr")

tbrs1 <- lapply(trs, function(x)html_nodes(x, "td") %>% html_text %>% str_trim)

crtime <- Sys.time()

tb1 <- data.frame(do.call("rbind",tbrs1[-4:-1]))

colnames(tb1) <- c("laboratory", "tested_all", "tested_mobile", "negative_all", "negative_mobile", "positive_all","positive_mobile","not_tested", "not_tested_mobile")

tb1[, -1] <- sapply(tb1[, -1], function(x)as.integer(gsub("*","",x, fixed = TRUE)))

tbr <- tb1 %>% filter(laboratory != "Iš viso:")

tbr <- bind_cols(data.frame(day = rep(floor_date(crtime, unit = "days")-days(1), nrow(tbr))), tbr)

tot <- tbr[,-1:-2] %>% sapply(sum, na.rm = TRUE)
if(sum(abs(tot - tb1 %>% filter(laboratory == "Iš viso:") %>% .[,-1] %>% unlist)) != 0) warning("Totals do not match")

tbr <- tbr %>% mutate(positive_new = NA, positive_retested = NA) %>%
    select(day, laboratory, tested_all, tested_mobile,
           negative_all, negative_mobile,
           positive_all, positive_mobile, positive_new, positive_retested,
           not_tested, not_tested_mobile)


outd <- gsub(" ","_",gsub("-","",as.character(crtime)))

write.csv(tbr, glue::glue("raw_data/laboratory/lt-covid19-laboratory_{outd}.csv"), row.names = FALSE )


# Get education -----------------------------------------------------------

raw <- GET("https://nvsc.lrv.lt/lt/visuomenei/covid-19-ugdymo-istaigose?fbclid=IwAR1RhabJa1O3e1PCaBzRxjifhfCPdrl2qihCvkHEHNJNHRKKyIMvlPZT2Jg")
#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)
tbs <- html_table(oo, fill = TRUE)

tb1 <- tbs[[1]][-2:-1,-1]
colnames(tb1) <- c("educational_institution","confirmed_students","confirmed_teachers","confirmed_other","quarantined","first_case","last_case")

tb1 %>% write.csv(glue::glue("raw_data/nvsc/education_{outd}.csv"), row.names=FALSE)


