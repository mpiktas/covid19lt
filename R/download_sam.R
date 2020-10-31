library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)

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

raw <- tryget("https://nvsc.lrv.lt/lt/visuomenei/nacionalinio-visuomenes-sveikatos-centro-duomenys")


#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)

# Add the totals data -----------------------------------------------------

cat("\nParsing daily data\n")

cd <- html_nodes(oo,".text") %>% html_nodes("li") %>% html_text

cd1 <-  html_nodes(oo,".text") %>% html_nodes("strong") %>% html_text

nums1 <- cd1 %>% str_trim %>% gsub("([0-9]+)( )([0-9+])","\\1\\3",.) %>% gsub("([0-9]+)(.*)","\\1",.) %>% as.integer %>% na.omit

ia1 <- nums1[8]

# Determine where is the hospitalization data ---------------------------

##In this block tbs will contain 3 tables

cat("\nTrying to determine where is the hospitalization data\n")
tbs <- html_table(oo, fill = TRUE)

raw1 <- tryget("https://nvsc.lrv.lt/lt/visuomenei/nacionalines-visuomenes-sveikatos-prieziuros-laboratorijos-duomenys")

oo1 <- read_html(raw1)

trs <- html_nodes(oo1, "tr")

tbrs1 <- lapply(trs, function(x)html_nodes(x, "td") %>% html_text %>% str_trim)

crtime <- Sys.time()
outd <- gsub(" ","_",gsub("-","",as.character(crtime)))

stbrs1 <- tbrs1 %>% sapply(paste,collapse=";")

writeLines(stbrs1, glue::glue("raw_data/laboratory/lt-covid19-laboratory_raw_{outd}.csv"))

##Test for the NVSC fuckup

tbrs2 <- tbrs1[-4:-1]
rc <- sapply(tbrs2, length)
tb1 <- data.frame(do.call("rbind",tbrs2[rc == 9]))

if(length(tbs) != 3) {
    cat("\nNo hospitalization data in the daily NVSC page")
    ##Always prefer NVSC page if the data is there
    if(length(unique(rc))>1)  {
        cat("\nHospitalization data is in the laboratory NVSC page")
        tbrs3 <- tbrs2[rc != 9]
        tmp_extend <- function(x, n = 6) {
            if(length(x)<6) {
                x <- c(rep("",6-length(x)), x)
            }
            x
        }
        tbs <- list(do.call("rbind",tbrs3[1:4]),
                    do.call("rbind",tbrs3[5:7]),
                    do.call("rbind",lapply(tbrs3[8:length(tbrs3)],tmp_extend,n=6))
                    )

    } else {
        cat("\nLooking into SAM page")
        rawh <- tryget("https://sam.lrv.lt/lt/naujienos/koronavirusas")
        ooh <- read_html(rawh)
        tbs <- html_table(ooh, fill = TRUE)
    }
}

# Get the total capacity data ------------------------------------------------------

cat("\nParsing total capacity data\n")

if(length(tbs) < 3) {
    cat("\nNo valid hospitalization data present\n")
} else {
    capacity_total <- data.frame(tbs[[1]][-2:-1,])
    colnames(capacity_total) <- c("description", "total", "intensive", "ventilated", "oxygen_mask")
    capacity_total[,-1] <- sapply(capacity_total[,-1], function(x)as.integer(gsub(" ","",x)))
    rownames(capacity_total) <- NULL


    # Get covid hospitalisation data ----------------------------------------------------------
    cat("\nParsing covid hospitalization data\n")

    cvh <- data.frame(tbs[[2]][-2:-1,,drop = FALSE])

    colnames(cvh) <- c("description","total", "oxygen","ventilated","hospitalized_not_intensive", "intensive")
    cvh[,-1] <- sapply(cvh[,-1], as.integer)


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
# Get the tests and laboratory data ------------------------------------------------------
cat("\nParsing test data\n")

cd2 <-  html_nodes(oo1,".text") %>% html_nodes("strong") %>% html_text

nums2 <- cd2 %>% str_trim %>% gsub("([0-9]+)( )([0-9+])","\\1\\3",.) %>% gsub("([0-9]+)(.*)","\\1",.) %>% as.integer %>% na.omit

nums <- c(nums1[-8],nums2[1:2])

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
           daily_tests = nums[8],
           quarantined = nums[7],
           total_tests = nums[9],
           imported0601 = ia1)
write.csv(ndd, glue::glue("raw_data/sam/lt-covid19-daily_{outd}.csv"), row.names = FALSE)



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


# Get education -----------------------------------------------------------
cat("\nParsing educational incidence data\n")

raw3 <- GET("https://nvsc.lrv.lt/lt/visuomenei/covid-19-ugdymo-istaigose?fbclid=IwAR1RhabJa1O3e1PCaBzRxjifhfCPdrl2qihCvkHEHNJNHRKKyIMvlPZT2Jg")
#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo3 <- read_html(raw3)
tbs <- html_table(oo3, fill = TRUE)

if(length(tbs)>0) {
    tb1 <- tbs[[1]][-2:-1,-1]
    colnames(tb1) <- c("educational_institution","confirmed_students","confirmed_all","first_case","last_case")

    tb1 %>% write.csv(glue::glue("raw_data/nvsc/education_{outd}.csv"), row.names=FALSE)
} else {
    cat("\nNo educational data\n")
}

