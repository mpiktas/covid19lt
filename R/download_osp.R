library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(tidyr)

tryget <- function(link, times = 10) {
    res <- NULL
    for (i in 1:times) {
        res <- try(GET(link))
        if(inherits(res, "try-error")) {
            cat("\nFailed to get the data, sleeping for 1 second\n")
            Sys.sleep(1)
        } else break
    }
    if(is.null(res))stop("Failed to get the data after ", times, " times.")
    res
}

raw <- tryget("https://osp.stat.gov.lt/informaciniai-pranesimai?articleId=8225529")

oo <- read_html(raw)

tbs <- html_table(oo, fill = TRUE)

# Add the totals data -----------------------------------------------------

cat("\nParsing daily data\n")

cdd <- tbs[[3]][,1]

crtime <- Sys.time()

cdd1 <- cdd[cdd!=""]
cdd2 <- sapply(strsplit(cdd1,":"),"[[",2) %>% str_trim %>% as.integer

nums <- c(cdd2[c(1, 7, 2, 4, 5, 6)],NA,NA,cdd2[8:9])
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
           imported0601 = nums[8])
write.csv(ndd, glue::glue("raw_data/sam/lt-covid19-daily_{outd}.csv"), row.names = FALSE)





# Get the total capacity data ------------------------------------------------------

cat("\nParsing total capacity data\n")

# Get covid hospitalisation data ----------------------------------------------------------
cat("\nParsing covid hospitalization data\n")

cvh0 <- data.frame(tbs[[4]])

colnames(cvh0) <- c("description","total", "oxygen","ventilated","hospitalized_not_intensive", "intensive")

cvh <- cvh0[4, ]
cvh$description[1] <- cvh0$description[1]
cvh$total[1] <- as.integer(strsplit(cvh0$total[1],":")[[1]][2])
cvh[,-1] <- sapply(cvh[,-1], as.integer)


# Get regional hospitalization data ---------------------------------------
cat("\nParsing regional hospitalization data\n")

tlk <- data.frame(tbs[[5]][-2:-1,])
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



