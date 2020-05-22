library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)

ds <- GET("https://maps.registrucentras.lt/arcgis/rest/services/covid/pjuviai/MapServer/1/query?f=json&where=1%3D1&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&callback=dojo_request_script_callbacks.dojo_request_script35")


geo <- GET("https://maps.registrucentras.lt/arcgis/rest/services/covid/pjuviai/FeatureServer/0/query?f=json&where=1%3D1&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=MIRE%20desc&resultType=standard&callback=dojo_request_script_callbacks.dojo_request_script24")




dst1 <- fromJSON(sub("[)];$","",sub("^.*[(]","",rawToChar(ds$content))))

geo1 <- fromJSON(sub("[)];$","",sub("^.*[(]","",gsub("(\"ATNUJINTA\":)([0-9]+)","\\1\"\\2\"", rawToChar(geo$content)))))



dd <- gsub(" ","_",Sys.time())

write.csv(dst1$features$attributes, file = paste0("rc/susirgimai_", dd,".csv"), row.names=FALSE)

write.csv(geo1$features$attributes, file = paste0("rc/savivaldybes_", dd,".csv"), row.names=FALSE)




