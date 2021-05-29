##gbif credentials, package listing, 
##working directory (documentation to describe appropriate folder nomenclature for reproduction)



install.packages("leaflet")
install.packages("rgbif")
install.packages("spThin")
library(leaflet)
library(rgbif)
library(dplyr)
library(readxl)

setwd("G:/My Drive/PhD/Chapter 3")

##---------------FIRST TIME ONLY------------------------------
##Getting the taxon key to search occurrences within GBIF (binding key to species name) 
##and giving NA if species does not exist

Species_List <- read_excel("G:/My Drive/PhD/Chapter 3/Data/Species List.xlsx")
Species_List[,"Key"] <- NA

for (i in 1:nrow(Species_List)) {
a <- Species_List[[i,1]]
tryCatch(Species_List$Key[[i]] <- name_usage(name = a)$data[[1,2]], error = function(e) 
{Species_List$Key[[i]] <- NA})
}

##move species that are not present in GBIF to new dataset
Species_NoGBIF <- subset(Species_List, is.na(Species_List$Key))
Species_List <- na.omit(Species_List)

##export taxon keys
write.csv(Species_List, "G:/My Drive/PhD/Chapter 3/Data/FullTaxonKeys.csv")
write.csv(Species_NoGBIF, "G:/My Drive/PhD/Chapter 3/Data/No Data Species.csv")
##turn Key column into easy vector
Species_List <- read.csv("Data/FullTaxonKeys.csv")
taxon_key <- Species_List$keyg

##set up occurrence downloads
occ_download(
  pred_in("taxonKey", confirm$keyg),
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  pred_in("basisOfRecord", c('PRESERVED_SPECIMEN','HUMAN_OBSERVATION','OBSERVATION','MACHINE_OBSERVATION')),
  format = "SIMPLE_CSV",
  user=user,pwd=pwd,email=email
)

##---------------START HERE TO RECREATE SMALLER DATASETS AFTER DOWNLOAD OF RAW FILE-------------
##import download

raw <- read.csv("Data/RawOccurrences.csv", sep = "\t", quote = "", stringsAsFactors = FALSE)
key2 <- raw$taxonKey
test <- read.csv("Data/secondrun.csv", sep = "\t", quote = "", stringsAsFactors = FALSE)

for (i in 1:235244) {
  test$check[i] <- is.element(test$taxonKey[i], taxon_key)
}
testf <- subset(test, test$check == FALSE)
test2 <- subset(test, test$check == TRUE)
species2 <- unique(test2$species)
raw2 <- subset(raw, raw$check == TRUE)
species <- unique(test$species)

for (i in 1:1734) {
  Species_List$check[i] <- is.element(species[i], Species_List$Species)
}

confirm <- subset(Species_List, Species_List$check == FALSE)
write.csv(raw, "Data/RawOccurrences.csv")
##rename lat/lon for easier usage later
raw <- raw %>% 
  rename(lat = decimalLatitude,
         lon = decimalLongitude)


##organize raw datasets by number of occurrences: small ones between 5-25
##which will require special ensemble techniques, and ones above 25 points which will be normal techniques.
##1-4 points will simply be given a radius/polygon EOO.

tK <- raw %>% 
  group_by(taxonKey)

small <- tK  %>%
  filter(n() >= 5 && n() < 25)

large <- tK  %>%
  filter(n() >= 25) %>%
  filter(class != "Pycnogonida")

polygon <- CO %>% 
  filter(n() < 5)

##count the total number of species in each group
n_distinct(large_CO$taxonKey)
n_distinct(small_CO$taxonKey)
n_distinct(polygon_CO$taxonKey)

##cleaning and filtering procedures to select 3 species from each size group/class for model tuning/hyperparameters

##start by confirming class is complete in the dataset, and then identify expected levels and ensure no weird outliers
sum(is.na(small_CO$class))
sum(is.na(large_CO$class)) 

unique(small_CO$class)
unique(large_CO$class)

##create subsets related to the classes

large_CO_class <- large_CO %>%
  group_by(class)


small_CO_class <- small_CO %>%
  group_by(class)

##set seed, make sure no duplicate species are selected, and subset the datasets for occurrences. Double check counts.

set.seed(10)

largekeys <- sample_n(large_CO_class, 3)$taxonKey
while (any(duplicated(largekeys))) {
  largekeys <- sample_n(large_CO_class, 3)$taxonKey
}

large_CO_sample <- large_CO_class %>%
    filter(taxonKey %in% largekeys)

smallkeys <- sample_n(small_CO_class, 3)$taxonKey
while (any(duplicated(smallkeys))) {
 smallkeys <- sample_n(small_CO_class, 3)$taxonKey
}

small_CO_sample <- small_CO_class %>%
  filter(taxonKey %in% smallkeys)

small_CO_sample %>%
  count(taxonKey)

large_CO_sample %>%
  count(taxonKey)

##Reduce to taxonKey, Scientific name, and lat/lon as these will be the raw datasets for model tuning
COtestL <- large_CO_sample %>%
  select(taxonKey, species, lat, lon, class)
COtestS <- small_CO_sample %>%
  select(taxonKey, species, lat, lon, class)

write.csv(COtestL, "Data/COtestL.csv")
write.csv(COtestS, "Data/COtestS.csv")


##--------------SPATIAL THINNING PROCESS FOR LARGE DATASETS-----------------
library(spthin)
