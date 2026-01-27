library(jsonencryptor)
library(bigrquery)
library(DBI)
library(dplyr)
library(sf)
library(leaflet)
library(ggplot2)
library(lubridate)

##Authenticate for BQ connection
bigrquery::bq_auth(path = jsonencryptor::secret_read("service_secret.json"))

con <- DBI::dbConnect(
  bigrquery::bigquery(),
  project = "dtsg-ana-transporthubcrowdmon", 
  dataset = "crowd_monitoring_api"
)

codes <- readr::read_csv("Data/PCD_OA_LSOA_MSOA_LAD_NOV21_UK_LU.csv")
msoa_shapefile <- sf::read_sf("Data/Middle_layer_Super_Output_Areas_(December_2021)_Boundaries_EW_BFE_(V8)_and_RUC.shp")

waterloo_shape <- msoa_shapefile %>% 
  dplyr::filter(MSOA21CD == "E02006801") %>% 
  sf::st_as_sf() %>% 
  sf::st_transform(crs = "+proj=longlat +datum=WGS84")