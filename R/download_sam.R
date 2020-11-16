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

raw <- tryget("https://sam.lrv.lt/lt/naujienos/koronavirusas")
#raw <- tryget("https://nvsc.lrv.lt/lt/visuomenei/statistine-metodine-ir-kita-informacija/nacionalinio-visuomenes-sveikatos-centro-duomenys")


#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)

# Add the totals data -----------------------------------------------------

cat("\nParsing daily data\n")

cd <- html_nodes(oo,".text") %>% html_nodes("li") %>% html_text

#cd1 <-  html_nodes(oo,".text") %>% html_nodes("strong") %>% html_text
#cd2 <- html_nodes(oo,".text") %>% html_nodes("b") %>% html_text

aa1 <- cd %>% str_trim %>% strsplit(":")

nums <- sapply(aa1, "[[",2) %>% str_trim %>% gsub("([0-9]+)( )([0-9+])","\\1\\3",.) %>% gsub("\xc2\xa0","",.) %>%  gsub("([0-9]+)(.*)","\\1",.) %>% as.integer %>% na.omit


# Treat and write ---------------------------------------------------------
cat("\nWriting daily  data\n")
crtime <- Sys.time()

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




# Determine where is the hospitalization data ---------------------------

##In this block tbs will contain 3 tables

cat("\nTrying to determine where is the hospitalization data\n")
tbs <- html_table(oo, fill = TRUE)



# Get the total capacity data ------------------------------------------------------

cat("\nParsing total capacity data\n")

if(length(tbs) < 3) {
    cat("\nNo valid hospitalization data present\n")
    tb1 <- tbs[[1]][-4:-1,]
} else {
    tb1 <- tbs[[4]][-4:-1,]

    capacity_total <- data.frame(tbs[[1]][-2:-1,])
    colnames(capacity_total) <- c("description", "total", "intensive", "ventilated", "oxygen_mask")
    capacity_total[,-1] <- sapply(capacity_total[,-1], function(x)as.integer(gsub("[,. ]","", x)))
    rownames(capacity_total) <- NULL


    # Get covid hospitalisation data ----------------------------------------------------------
    cat("\nParsing covid hospitalization data\n")

    cvh <- data.frame(tbs[[2]][-2:-1,,drop = FALSE])

    colnames(cvh) <- c("description","total", "oxygen","ventilated","hospitalized_not_intensive", "intensive")
    cvh[,-1] <- sapply(cvh[,-1], function(x)as.integer(gsub("[,. ]","",x)))


    # Get regional hospitalization data ---------------------------------------
    cat("\nParsing regional hospitalization data\n")

    tlk <- data.frame(tbs[[3]][-2:-1,])
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
    res <- list(total_capacity= capacity_total, covid_hospitalization = cvh, tlk_capacity = tlk)

    dd <- gsub(" ","_",Sys.time())
    fnl <- paste0("raw_data/hospitalization//",names(res),"_",dd,".csv")

    mapply(function(dt, nm) write.csv(dt, nm, row.names = FALSE), res, fnl, SIMPLIFY = FALSE)


}

# Do the laboratory tables data -------------------------------------------
cat("\nParsing laboratory data\n")


colnames(tb1) <- c("laboratory", "tested_all", "tested_mobile", "negative_all", "negative_mobile", "positive_all","positive_mobile","not_tested", "not_tested_mobile")

tb1[, -1] <- sapply(tb1[, -1], function(x)as.integer(gsub("*","",x, fixed = TRUE)))

tbr <- tb1 %>% filter(laboratory != "Iš viso:")

tbr <- bind_cols(data.frame(day = rep(floor_date(crtime, unit = "days")-days(1), nrow(tbr))), tbr)

tot <- tbr[,-1:-2] %>% sapply(sum, na.rm = TRUE)
if(sum(abs(tot - tb1 %>% filter(laboratory == "Iš viso:") %>% .[,-1] %>% unlist)) != 0) cat("\nTotals for laboratory data do not match\n")

tbr <- tbr %>% mutate(positive_new = NA, positive_retested = NA) %>%
    select(day, laboratory, tested_all, tested_mobile,
           negative_all, negative_mobile,
           positive_all, positive_mobile, positive_new, positive_retested,
           not_tested, not_tested_mobile)

write.csv(tbr, glue::glue("raw_data/laboratory/lt-covid19-laboratory_{outd}.csv"), row.names = FALSE )
