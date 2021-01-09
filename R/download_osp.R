library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(tidyr)

source("R/functions.R")

raw <- tryget("https://osp.stat.gov.lt/praejusios-paros-covid-19-statistika")

oo <- read_html(raw)

tbs <- html_table(oo, fill = TRUE)

# Get the total capacity data ------------------------------------------------------

cat("\nParsing total capacity data\n")

# Get covid hospitalisation data ----------------------------------------------------------
cat("\nParsing covid hospitalization data\n")

cvh0 <- data.frame(tbs[[4]])[1:4,]

colnames(cvh0) <- c("description","total", "oxygen","ventilated","hospitalized_not_intensive", "intensive")

cvh <- cvh0[4, ]
cvh$description[1] <- cvh0$description[1]
#cvh$total[1] <- as.integer(strsplit(cvh0$total[2],":")[[1]][2])
cvh$total[1] <- as.integer(cvh0$total[2])
cvh[,-1] <- sapply(cvh[,-1], as.integer)


# Get regional hospitalization data ---------------------------------------
cat("\nParsing regional hospitalization data\n")

tlk <- data.frame(tbs[[4]][-1:-8,])
colnames(tlk) <-c("description", "tlk", "total", "intensive", "ventilated", "oxygen_mask")
tlk[,-2:-1] <- sapply(tlk[,-2:-1], function(x)as.integer(gsub("[,. ]","",x)))
tlk$description[tlk$description == ""] <- NA
tlk <- tlk %>% fill(description)

tt <- tlk %>% filter(tlk == "Iš viso:" | tlk == "VISO")

tlk <- tlk %>% filter(!(tlk %in% c("Iš viso:", "VISO")))

tt1 <- tlk %>% select(-tlk) %>% group_by(description) %>% summarise_all(sum)

test_total <- sum(tt[order(tt$description), -1:-2] - tt1[order(tt1$description),-1])
if(test_total != 0) warning("Totals do not match with TLK breakdown")


# Write everything --------------------------------------------------------
cat("\nWriting hospitalization data\n")
res <- list(covid_hospitalization = cvh, tlk_capacity = tlk)

dd <- gsub(" ","_",Sys.time())
fnl <- paste0("raw_data/hospitalization//",names(res),"_",dd,".csv")

mapply(function(dt, nm) write.csv(dt, nm, row.names = FALSE), res, fnl, SIMPLIFY = FALSE)


# Add the totals data -----------------------------------------------------

cat("\nParsing daily data\n")

cdd <- c(tbs[[2]][,1], tbs[[3]][,1], tbs[[4]][,1])

crtime <- Sys.time()

cdd1 <- cdd[cdd!=""]
cdd2 <- cdd1[grepl("[:]", cdd1)]
cdd3 <- sapply(strsplit(cdd2,":"),"[[",2) %>% str_trim %>% as.integer

nums <- c(cdd3[c(2, 11, 1, 6)],NA,cdd3[10],NA,NA,cdd3[13:16])

outd <- gsub(" ","_",gsub("-","",as.character(crtime)))
ndd <- data.frame(country = "Lithuania", day = rep(floor_date(crtime, unit = "days")-days(1))) %>%
    mutate(confirmed = nums[1],
           active = nums[2],
           incidence = nums[3],
           deaths = nums[4],
           deaths_different = nums[5],
           recovered = nums[6],
           daily_tests = nums[9],
           quarantined = nums[7],
           total_tests = nums[10],
           imported0601 = nums[8],
           vacine_daily = nums[11],
           vacine_total = nums[12])
write.csv(ndd, glue::glue("raw_data/sam/lt-covid19-daily_{outd}.csv"), row.names = FALSE)



## Write the death age distribution
#aged0 <- tbs[[5]]
#aged <- aged0[-1,]
#colnames(aged) <- c(aged0[[1]][1],aged0[[2]][1])
#aged[,2] <- sapply(aged[,2], as.integer)

#write.csv(aged0, glue::glue("raw_data/sam/lt-covid19-death-age_{outd}.csv"), row.names = FALSE)
