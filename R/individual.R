library(jsonlite)

system("wget ftp://atviriduomenys.nvsc.lt/COVID19.json")
file.copy("COVID19.json","individual/COVID19.json",overwrite=TRUE)
suff <- gsub("-","",Sys.Date())

file.copy("COVID19.json",paste0("~/tmp/covid19lt-json/COVID19-",suff,".json"))
file.remove("COVID19.json")



zz <- fromJSON("individual/COVID19.json")

zz1 <- zz %>% rename(actual_day = `Susirgimo data`,
                     day = `Atvejo patvirtinimo data`,
                     imported = `Įvežtinis`,
                     country = `Šalis`,
                     status = `Išeitis`,
                     foreigner  = `Užsienietis`,
                     age  =  `Atvejo amžius`,
                     sex = `Lytis`,
                     administrative_level_3 = `Savivaldybė`,
                     hospitalized = `Ar hospitalizuotas`,
                     intensive = `Gydomas intensyvioje terapijoje`,
                     precondition = `Turi lėtinių ligų`) %>%
    arrange(day, actual_day, administrative_level_3, age)

zz1 %>% write.csv("individual/lt-covid19-individual.csv", row.names = FALSE)


zz2 <- lapply(sort(unique(zz1$day)), function(d) zz1 %>% filter(day <= d))

zz3 <- lapply(zz2, function(d) d %>% mutate(dday = day) %>% summarize(day = max(day), confirmed = n(), incidence = sum(dday == max(day)),
                                               imported = sum(imported == "Taip"),
                                               recovered = sum(status == "Pasveiko"),
                                               deaths = sum(status == "Mirė"),
                                               deaths_different = sum(status == "Kita"),
                                               hospitalized = sum(hospitalized == "Taip"),
                                               intensive = sum(intensive == "Taip"))) %>% bind_rows
