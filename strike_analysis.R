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
                                            peopleCount,
                                            residentSum, 
                                            workerSum, 
                                            visitorSum
                                     FROM msoa_counts
                                     WHERE msoa = 'E02006801'")

strike_data <- waterloo_data %>% 
  dplyr::mutate(time = hms::as_hms(time),
                weekday = lubridate::wday(date, week_start = 1)) %>% 
  dplyr::filter(time >= hms("08:00:00"),
                time <= hms("19:00:00"),
                between(weekday, 1, 5))

baseline <- strike_data %>% 
  dplyr::filter(date >= baseline_start & date <= baseline_end) %>% 
  dplyr::select(-date) %>% 
  dplyr::rename(people_count_baseline = peopleCount,
                resident_count_baseline = residentSum,
                worker_count_baseline = workerSum,
                visitor_count_baseline = visitorSum)