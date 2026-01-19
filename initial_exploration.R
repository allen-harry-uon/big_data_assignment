library(jsonencryptor)
library(bigrquery)
library(DBI)
library(dplyr)
library(sf)
library(leaflet)

##Authenticate for BQ connection
bigrquery::bq_auth(path = jsonencryptor::secret_read("service_secret.json"))

##Connect to big query
con <- DBI::dbConnect(
  bigrquery::bigquery(),
  project = "dft-gcp-mobilenetworkdata-prod"
)

codes <- readr::read_csv("Data/PCD_OA_LSOA_MSOA_LAD_NOV21_UK_LU.csv")

birmingham_codes <- codes %>% 
  dplyr::filter(grepl("Birmingham", msoa11nm))

new_street_codes <- birmingham_codes %>% 
  dplyr::filter(msoa11cd == "E02006899"| msoa11cd == "E02006896")

msoa_shapefile <- sf::read_sf("Data/Middle_layer_Super_Output_Areas_(December_2021)_Boundaries_EW_BFE_(V8)_and_RUC.shp")

birmingham_shapes <- msoa_shapefile %>% 
  dplyr::filter(grepl("Birmingham", MSOA21NM)) %>% 
  sf::st_as_sf()

new_street_station <- birmingham_shapes %>% 
  dplyr::filter(MSOA21CD == "E02006899" | MSOA21CD == "E02006896") %>% 
  sf::st_as_sf()

leaflet::leaflet() %>% 
  addTiles() %>% 
  setView(lng=-1.353181, lat=52.867467, zoom=6) %>% 
  addPolygons(data = new_street_station)