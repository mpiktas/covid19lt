library(readxl)
library(dplyr)
library(lubridate)
library(tidyr)

rr <- readxl::read_xlsx("raw_data/Lithuania_age_sex_region_2021.xlsx")

##Find the sex split
ind <- as.vector(t(t(rr[4,])))
names(ind) <- NULL
sep <- which(!is.na(ind))

##Get the headder
hdr <- unlist(rr[5,1:(sep[2]-1)])
names(hdr) <- NULL
hdr[1] <- "region"

both <- rr[-5:-1,c(1:(sep[2]-1))]
colnames(both) <- hdr

male <- rr[-5:-1,c(1,sep[2]:(sep[3]-1))]
colnames(male) <- hdr

female <- rr[-5:-1,c(1,sep[3]:(ncol(rr)))]
colnames(female) <- hdr

prepare_data <- function(x, sex = "Moteris") {
    x <- x[,-2]
    x <- x %>% filter(grepl("sav",region))
    x <- x %>% filter(region!= "Marijampolės r. sav.")

    x <- x %>% pivot_longer(`0`:`85 ir vyresni`, names_to = "age",
                            values_to = "population")

    x <- x %>% mutate(sex = sex)
}

arsd <- mapply(prepare_data, list(both, male, female),
               c("Viso","Moteris","Vyras"), SIMPLIFY = FALSE) %>%
    bind_rows

adm <- read.csv("raw_data/administrative_levels.csv")

arsd1 <- arsd %>% rename(municipality_name = region) %>%  inner_join(adm)

aged <- arsd$age %>% unique

agr <- data.frame(age = aged) %>%
    mutate(agen = age) %>%
    mutate(agen = ifelse(agen == "85 ir vyresni","85",agen)) %>%
    mutate(age10 = cut(as.numeric(agen), c(0,10,20,30,40,50,60,70,80, Inf),
                       include.lowest = TRUE, right = FALSE)) %>%
    mutate(age10 = gsub("[[)]","",age10)) %>%
    mutate(age10 = gsub(",","-", age10)) %>%
    mutate(age10 = ifelse(is.na(age10),"80+",age10)) %>%
    mutate(age10 = ifelse(age10 == "80-Inf]","80+",age10))

ards2 <- arsd1 %>% left_join(agr %>%
                                 select(age, age10)) %>%
    mutate(population = as.integer(as.numeric(population)))

ards2 %>% filter(sex == "Viso") %>%
    select(administrative_level_2, administrative_level_3,
           age, age10, population) %>%
    write.csv("data/age_distribution/lt-agedist1-level3.csv")

ards2 %>% filter(sex == "Viso") %>%
    select(administrative_level_2, administrative_level_3,
           age, age10, population) %>%
    group_by(administrative_level_2, administrative_level_3, age = age10) %>%
    summarise(population = sum(population)) %>%
    write.csv("data/age_distribution/lt-agedist10-level3.csv")


ards2 %>% filter(sex != "Viso") %>%
    select(administrative_level_2, administrative_level_3,
           age, age10, sex, population) %>%
    write.csv("data/age_distribution/lt-age-sex-dist1-level3.csv")

ards2 %>% filter(sex == "Viso") %>%
    select(administrative_level_2, administrative_level_3,
           age, age10, sex, population) %>%
    group_by(administrative_level_2, administrative_level_3,
             age = age10, sex) %>%
    summarise(population = sum(population)) %>%
    write.csv("data/age_distribution/lt-age-sex-dist10-level3.csv")




