##gbif credentials, package listing

source("creds.R")

install.packages("leaflet")
install.packages("rgbif")

library(leaflet)
library(rgbif)
library(dplyr)
library(readxl)


Species_List <- read_excel("Species List.xlsx")

##First API query using taxonKey from the Lookup and the species name in the file.
#The csv below (API) is the results of that downloaded from my account and contains substantial synomyms
#in both taxonKey and in verbatimScientificName

occ_download(
  pred_in("taxonKey", 4829020),
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  pred_in("basisOfRecord", c('PRESERVED_SPECIMEN','HUMAN_OBSERVATION','OBSERVATION','MACHINE_OBSERVATION')),
  format = "SIMPLE_CSV",
  user=user,pwd=pwd,email=email
)

API <- read.csv("4829020.csv", sep = "\t", quote = "", stringsAsFactors = FALSE)
unique(API$verbatimScientificName)

##Second API query is using taxonKey from the Lookup and the species name in the file, and happens to be one of
#the synonyms present in the first query. There are still synonyms present, but far less.

occ_download(
  pred_in("taxonKey", 5786854),
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  pred_in("basisOfRecord", c('PRESERVED_SPECIMEN','HUMAN_OBSERVATION','OBSERVATION','MACHINE_OBSERVATION')),
  format = "SIMPLE_CSV",
  user=user,pwd=pwd,email=email
)

API2 <- read.csv("5786854.csv", sep = "\t", quote = "", stringsAsFactors = FALSE)
unique(API2$verbatimScientificName)
