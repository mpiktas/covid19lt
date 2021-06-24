library(dplyr)
library(magick)

im <- image_read("tests/pdfs/covid19_cropped.jpg")

im_proc <- im %>% image_channel("saturation")

imd <- image_data(im_proc)[1, , ]

im_proc2 <- im_proc %>%
  image_threshold("white", "50%")

imd1 <- matrix(as.integer(imd), nrow = dim(imd)[1])

imd2 <- matrix(as.integer(image_data(im_proc2)[1, , ]), nrow = dim(imd)[1])

heights <- round(apply(imd2, 1, function(x) sum(x != 255)) / 4)

heights1 <- heights[9:1107]

dt <- c(heights1[which(heights1 != 0)[which(diff(which(heights1 != 0)) != 1)]], 3)
gaps <- round(diff(which(heights1 != 0))[diff(which(heights1 != 0)) != 1] / 14)

dd <- ymd("2020-02-21") + days(0:64)

res <- data.frame(day = dd[c(1, cumsum(gaps) + 1)], incidence = dt)
