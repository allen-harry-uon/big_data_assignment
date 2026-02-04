library(jsonencryptor)
library(bigrquery)
library(DBI)
library(dplyr)

##Authenticate for BQ connection
bigrquery::bq_auth(path = jsonencryptor::secret_read("service_secret.json"))

con <- DBI::dbConnect(
  bigrquery::bigquery(),
  project = "dtsg-ana-transporthubcrowdmon", 
  dataset = "crowd_monitoring_api"
)

waterloo_data <- DBI::dbGetQuery(con, "SELECT date,
                                            time,
                                            msoa,
                                            residentSum, 
                                            workerSum, 
                                            visitorSum
                                     FROM msoa_counts
                                     WHERE msoa = 'E02006801'")

strike_data <- waterloo_data %>% 
  dplyr::mutate(time = hms::as_hms(time)) %>% 
  dplyr::filter(time >= hms("08:00:00"),
                time <= hms("17:00:00"))