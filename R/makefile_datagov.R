library(dplyr)
library(lubridate)
library(testthat)
library(gert)

source("R/download_datagov.R")
source("R/merge.R")


find_root <- function(x) {
    x %>% strsplit("/") %>% sapply("[[",1)
}

modf <- git_status() %>% .$file %>% find_root %>% unique
if(!("data" %in% modf)) {
    cat("\nNo new data, not pushing anything\n")
} else {
    cat("\nSending the new data downstream\n")
    ghpt <- Sys.getenv("GITHUB_PA_TOKEN")
    if(ghpt!="") {
        cat("\nTrying to set signature\n")
        git_config_set("user.name", "Gitlab CI bot")
        git_config_set("user.email", "test@email.com")
        cat("\nCurrent git status\n")
        print(git_status())
        print(git_info())
        git_branch_checkout("master")
        git_add("raw_data")
        git_add("data")
        cat("\nTrying to commit\n")
        git_commit("Update data.gov.lt data")
        git_remote_add(glue::glue("https://covid19-ci:{ghpt}@github.com/mpiktas/covid19lt.git"), "github")
        git_push(remote = "github")
    } else {
        cat("\nGithub token not found, relying on local git configuration\n")
        git_add("raw_data")
        git_add("data")
        git_commit("Update data.gov.lt data")
        git_push()
    }
}


