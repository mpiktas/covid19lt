library(testthat)
library(gert)
cat("\n=======Downloading tests================\n")
try(source('R/download_osp_tests.R'))
cat("\n=======Downloading cases================\n")
try(source('R/download_osp_cases.R'))
cat("\n=======Downloading hospital================\n")
try(source('R/download_osp_hospital.R'))
cat("\n=======Downloading main OSP site================\n")
try(source('R/download_osp.R'))
cat("\n=======Downloading age distribution data================\n")
try(source("R/download_osp_agedist.R"))
cat("\n=======Downloading EVRK data================\n")
try(source("R/download_osp_evrk.R"))
cat("\n=======Treating OSP data================\n")
try(source("R/treat_osp.R"))
cat("\n=======Creating levels data================\n")
try(source('R/create_levels.R'))

find_root <- function(x) {
    x %>% strsplit("/") %>% sapply("[[",1)
}

##Was the data modified?
##
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
        git_commit("Update OSP data")
        git_remote_add(glue::glue("https://covid19-ci:{ghpt}@github.com/mpiktas/covid19lt.git"), "github")
        git_push(remote = "github")
    } else {
        git_add("raw_data")
        git_add("data")
        git_commit("Update OSP data")
        git_push()
    }
}


