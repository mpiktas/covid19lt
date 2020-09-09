bb1 <- read.csv("~/Downloads/covid_121_20200901.csv")


bc1 <- bb1 %>% count(ct_e200_sukurimo_data) %>%
    rename(day = ct_e200_sukurimo_data, ct_e200_sukurimo_data = n)

bc2 <-  bb1 %>% count(ct_e200ats_duom_sukurti) %>%
    rename(day = ct_e200ats_duom_sukurti, ct_e200ats_duom_sukurti = n)

bc3 <- bb1 %>% count(e200_sukurimo_periodas) %>%
    rename(day =e200_sukurimo_periodas, e200_sukurimo_periodas = n)

bt <- bc1 %>% inner_join(bc2) %>% inner_join(dd %>% select(day, daily_tests))
