library(testthat)
library(gert)
source("R/download_rc.R")
source("R/treat_rc.R")

find_root <- function(x) {
    x %>% strsplit("/") %>% sapply("[[",1)
}

##Was the data modified?
##
modf <- git_status() %>% .$file %>% find_root %>% unique
#if(!("data" %in% modf)) {
#    cat("\nNo new data, not pushing anything\n")
#} else {
    cat("\nSending the new data downstream\n")
    #git_add("raw_data")
    #git_add("data")

    ghpt <- Sys.getenv("GITHUB_PA_TOKEN")
    if(ghpt!="") {
        git_branch_checkout("test")
        git_add("raw_data")
        git_commit("Update sam and rc data", author = "Gitlab CI bot")
        git_remote_add(glue::glue("https://covid19-ci:{ght}@github.com/mpiktas/covid19lt.git"), "github")
        git_push(remote = "github")
    } else {
        git_commit("Update sam and rc data")
        git_push()
    }
#}




