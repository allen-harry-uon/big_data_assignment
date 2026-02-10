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

# Reading in shapefiles
msoa_shapefile <- sf::read_sf("Data/map/Middle_layer_Super_Output_Areas_(December_2021)_Boundaries_EW_BFE_(V8)_and_RUC.shp")

waterloo_shape <- msoa_shapefile %>% 
  dplyr::filter(MSOA21CD == waterloo_msoa) %>% 
  sf::st_as_sf() %>% 
  # Making sure shape is properly projected on to world map
  sf::st_transform(crs = "+proj=longlat +datum=WGS84")

# Getting sample of data
waterloo_data <- DBI::dbGetQuery(con, "SELECT date, 
                                              time, 
                                              peopleCount, 
                                              msoa, 
                                              residentSum, 
                                              workerSum, 
                                              visitorSum
                                       FROM msoa_counts
                                       WHERE date = DATE '2023-05-17'
                                       AND msoa = 'E02006801'")

# Joining shape data to crowd data
waterloo_mapped_data <- waterloo_data %>% 
  dplyr::group_by(date, msoa) %>% 
  # Calculating total count per day
  dplyr::summarise(total_count = sum(peopleCount)) %>% 
  dplyr::left_join(waterloo_shape, by = join_by(msoa == MSOA21CD)) %>% 
  sf::st_as_sf() %>% 
  sf::st_transform(crs = "+proj=longlat +datum=WGS84")

# Formatting label when hovering over shape
location_label <- sprintf("<span style='font-weight:bold; font-size:1.5em;'>%s</span>", waterloo_mapped_data$MSOA21NM)
count_label <- sprintf("<br>Count: %s", waterloo_mapped_data$total_count)

labels <- paste(location_label, count_label) %>% 
  lapply(htmltools::HTML)

# Creating map
leaflet::leaflet() %>% 
  # Adding world map underneath
  addTiles(options = tileOptions(opacity = 0.5)) %>% 
  addPolygons(data = waterloo_mapped_data,
              weight = 3,
              color = "#004D3B",
              fillColor = "#004D3B",
              fillOpacity= 0.6,
              label = labels,
              highlight = highlightOptions(weight = 3,
                                           color = "#666",
                                           fillOpacity = 0.1))