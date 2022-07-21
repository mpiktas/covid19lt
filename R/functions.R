daily_xtable <- function(zz1, colsums = FALSE) {
  ## input is one person per line
  ##
  agad <- zz1 %>%
    count(day, administrative_level_3, age) %>%
    pivot_wider(
      names_from = "age", values_from = "n", values_fill = 0,
      names_sort = TRUE
    ) %>%
    arrange(day, administrative_level_3)

  agr <- zz1$age %>% unique()
  sagr <- sapply(strsplit(agr, "-"), "[[", 1) %>% gsub("[+]", "", .) # Exclude Linting
  agr_sorted <- agr[order(sagr)]

  ad <- zz1 %>%
    count(day, administrative_level_3) %>%
    rename(Total = n)

  agad1 <- agad %>% inner_join(ad, by = c("day", "administrative_level_3"))

  if (colsums) {
    ag <- zz1 %>% count(day, age) # Exclude Linting
    ag1 <- ag %>%
      group_by(day) %>%
      summarise(n = sum(n))
    ag2 <- ag %>%
      bind_rows(ag1 %>%
        mutate(age = "Total")) %>%
      pivot_wider(
        names_from = "age", values_from = "n", values_fill = 0,
        names_sort = TRUE
      ) %>%
      mutate(administrative_level_3 = "ZTotal")

    agad2 <- agad1 %>%
      bind_rows(ag2) %>%
      arrange(day, administrative_level_3) %>%
      mutate(
        administrative_level_3 =
          gsub("ZTotal", "Total", administrative_level_3)
      )
  } else {
    agad2 <- agad1 %>% arrange(day, administrative_level_3) # Exclude Linting
  }

  agad2[, c("day", "administrative_level_3", agr_sorted, "Total")]
}


daily_xtable2 <- function(zz1, colsums = FALSE) {
  ## Input is one administrative level, day, age per line
  agad <- zz1 %>%
    select(day, administrative_level_3, age, indicator) %>%
    pivot_wider(
      names_from = "age", values_from = "indicator",
      values_fill = 0, names_sort = TRUE
    ) %>%
    arrange(day, administrative_level_3)

  agr <- zz1$age %>% unique()
  sagr <- sapply(strsplit(agr, "-"), "[[", 1) %>% gsub("[+]", "", .) # Exclude Linting
  agr_sorted <- agr[order(sagr)]

  ad <- zz1 %>%
    group_by(day, administrative_level_3) %>%
    summarise(Total = sum(indicator))

  agad1 <- agad %>% inner_join(ad, by = c("day", "administrative_level_3"))

  if (colsums) {
    ag <- zz1 %>%
      group_by(day, age) %>%
      summarise(n = sum(indicator)) %>%
      ungroup()
    ag1 <- ag %>%
      group_by(day) %>%
      summarise(n = sum(n))
    ag2 <- ag %>%
      bind_rows(ag1 %>%
        mutate(age = "Total")) %>%
      pivot_wider(
        names_from = "age", values_from = "n", values_fill = 0,
        names_sort = TRUE
      ) %>%
      mutate(administrative_level_3 = "ZTotal")

    agad2 <- agad1 %>%
      bind_rows(ag2) %>%
      arrange(day, administrative_level_3) %>%
      mutate(
        administrative_level_3 =
          gsub("ZTotal", "Total", administrative_level_3)
      )
  } else {
    agad2 <- agad1 %>% arrange(day, administrative_level_3) # Exclude Linting
  }

  agad2[, c("day", "administrative_level_3", agr_sorted, "Total")]
}


fix_esridate <- function(str) {
  dd <- jsonlite::fromJSON(str)
  fn <- dd$fields %>%
    filter(type == "esriFieldTypeDate") %>%
    .$name

  if (length(fn) == 0) {
    return(dd$features$attributes)
  } else {
    for (aa in fn) {
      str <- gsub(paste0("(\"", aa, "\": +)([0-9]+)"), "\\1\"\\2\"", str)
    }
    dd <- jsonlite::fromJSON(str)$features$attributes
    for (aa in fn) {
      dd[[aa]] <- as_datetime(bit64::as.integer64(dd[[aa]]) / 1000)
    }
  }
  dd
}

find_root <- function(x) {
  x %>%
    strsplit("/") %>%
    sapply("[[", 1)
}

tryget <- function(link, times = 10) {
  res <- NULL
  for (i in 1:times) {
    res <- try(httr::GET(link))
    if (inherits(res, "try-error")) {
      cat("\nFailed to get the data, sleeping for 1 second\n")
      Sys.sleep(1)
    } else {
      break
    }
  }
  if (is.null(res)) stop("Failed to get the data after ", times, " times.")
  res
}

set_github_remote <- function(ghpt = Sys.getenv("GITHUB_PA_TOKEN")) {
  if (ghpt != "") {
    rl <- git_remote_list()
    if (!("github" %in% rl[["name"]])) {
      cat("\nSetting Github remote for pushing\n")
      git_remote_add(glue::glue("https://covid19-ci:{ghpt}@github.com/mpiktas/covid19lt.git"), "github")
      cat("\nThe status of remote")
      print(git_remote_list())
    } else {
      cat("\nGithub remote already set")
      print(rl)
    }
  } else {
    cat("\nGithub token not found, remote not set\n")
  }
  ghpt
}


push_to_github <- function(dirs, commit_message, push = FALSE) {
  cat("\nSending the site downstream\n")

  remote <- TRUE
  cat("\nChecking Github PA status")
  ghpt <- Sys.getenv("GITHUB_PA_TOKEN")

  if (ghpt == "") {
    remote <- FALSE
  } else {
    set_github_remote(ghpt)
  }

  if (remote) {
    cat("\nTrying to set signature\n")
    git_config_set("user.name", "Gitlab CI bot")
    git_config_set("user.email", "test@email.com")
    cat("\nCurrent git status\n")
    print(git_status())
    print(git_info())
    git_branch_checkout("master")
    for (dd in dirs) {
      git_add(dd)
    }
    cat("\nTrying to commit\n")
    git_commit(commit_message)
    if (push) git_push(remote = "github")
  } else {
    cat("\nGithub token not found, relying on local git configuration\n")
    for (dd in dirs) {
      git_add(dd)
    }
    git_commit(commit_message)
    git_push()
  }
}

fix_na <- function(x, value = 0) {
  x[is.na(x)] <- value
  x
}

ddiff <- function(x) {
  c(0, diff(x))
}

scen_abcd <- function(c100k, tpr, t100k) {
  res <- rep(0, length(c100k))
  res[c100k < 25 & tpr < 4] <- 1
  res[c100k >= 25 & c100k < 100] <- 2
  res[c100k >= 100 & c100k < 500] <- 3
  res[c100k >= 500] <- 4
  res[t100k <= 500] <- 0
  res <- res / 4
  res
}

## Input 0-10, output 0-9
convert_interval <- function(x) {
  int <- grepl("-", x)
  xx <- x[int]
  spl <- strsplit(xx, "-")
  left <- as.integer(sapply(spl, "[[", 1))
  right <- as.integer(sapply(spl, "[[", 2))
  x[int] <- paste(left, right - 1, sep = "-")
  x
}

add_states <- function(tr, init, level = NULL, group = NULL) {
  if (is.null(level)) {
    tr0 <- tr
    init0 <- init
  } else {
    if (level %in% init[, "administrative_level_2"]) {
      tr0 <- tr %>% filter(administrative_level_2 == level)
      init0 <- init %>% filter(administrative_level_2 == level)
    } else {
      tr0 <- tr %>% filter(administrative_level_3 == level)
      init0 <- init %>% filter(administrative_level_3 == level)
    }
  }
  if (is.null(group)) {
    group1 <- "day"
  } else {
    group1 <- c(group, "day")
  }

  acols <- c("r0i0", "r0r1", "r0c0", "r0i1", "r0c1", "r1i1", "r1r2", "r1c1", "r1i2", "r1c2", "r2i2", "r2r3", "r2c2", "r2i3", "r2c3", "r3i3", "r3c3") # nolint
  tr1 <- tr0 %>%
    group_by(across(.cols = all_of(group1))) %>%
    summarise(across(.cols = all_of(acols), .fns = sum)) %>%
    ungroup()

  if (is.null(group)) {
    tr1 <- tr1 %>% mutate(at_risk = sum(init0[, "at_risk"]))
  } else {
    init1 <- init0 %>%
      group_by(across(.cols = all_of(group))) %>%
      summarise(at_risk = sum(at_risk))
    tr1 <- tr1 %>% left_join(init1)
  }

  if (!is.null(group)) tr1 <- tr1 %>% group_by(across(.cols = all_of(group)))
  tr2 <- tr1 %>%
    arrange(day) %>%
    mutate(
      i0 = r0i0 + r0i1,
      i1 = r1i1 + r1i2,
      i2 = r2i2 + r2i3,
      i3 = r3i3,
      r0 = -(r0i0 + r0i1 + r0c0 + r0c1 + r0r1),
      r1 = r0r1 - (r1i1 + r1i2 + r1c1 + r1c2 + r1r2),
      r2 = r1r2 - (r2i2 + r2i3 + r2c2 + r2c3 + r2r3),
      r3 = r2r3 - (r3i3 + r3c3),
      sr0 = cumsum(r0) + at_risk,
      sr1 = cumsum(r1),
      sr2 = cumsum(r2),
      sr3 = cumsum(r3),
      c0 = r0c0,
      c1 = r0c1 + r1c1,
      c2 = r1c2 + r2c2,
      c3 = r2c3 + r3c3
    ) %>%
    mutate(
      ai0 = rollsum(i0, 7, fill = NA, align = "right"),
      ai1 = rollsum(i1, 7, fill = NA, align = "right"),
      ai2 = rollsum(i2, 7, fill = NA, align = "right"),
      ai3 = rollsum(i3, 7, fill = NA, align = "right"),
      bi0 = rollsum(i0, 14, fill = NA, align = "right"),
      bi1 = rollsum(i1, 14, fill = NA, align = "right"),
      bi2 = rollsum(i2, 14, fill = NA, align = "right"),
      bi3 = rollsum(i3, 14, fill = NA, align = "right")
    ) %>%
    mutate(
      pi0 = 100 * ai0 / (ai0 + ai1 + ai2 + ai3),
      pi1 = 100 * ai1 / (ai0 + ai1 + ai2 + ai3),
      pi2 = 100 * ai2 / (ai0 + ai1 + ai2 + ai3),
      pi3 = 100 * ai3 / (ai0 + ai1 + ai2 + ai3)
    ) %>%
    mutate(
      bni0 = bi0 / lag(sr0, 14) * 1e5,
      bni1 = bi1 / lag(sr1, 14) * 1e5,
      bni2 = bi2 / lag(sr2, 14) * 1e5,
      bni3 = bi3 / lag(sr3, 14) * 1e5
    ) %>%
    mutate(
      ani0 = ai0 / lag(sr0, 7) * 1e6,
      ani1 = ai1 / lag(sr1, 7) * 1e6,
      ani2 = ai2 / lag(sr2, 7) * 1e6,
      ani3 = ai3 / lag(sr3, 7) * 1e6
    ) %>%
    ungroup()
  tr2
}
