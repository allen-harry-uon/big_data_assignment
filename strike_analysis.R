library(jsonencryptor)
library(bigrquery)
library(DBI)
library(dplyr)
library(lubridate)
library(ggplot2)

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
  dplyr::filter(hms::as_hms(time) >= hms("08:00:00"),
                hms::as_hms(time) <= hms("19:00:00")) %>% 
  dplyr::group_by(date, msoa) %>% 
  dplyr::summarise(peopleCount = mean(peopleCount),
                   residentSum = mean(residentSum),
                   workerSum = mean(workerSum),
                   visitorSum = mean(visitorSum)) %>% 
  dplyr::mutate(weekday = lubridate::wday(date, week_start = 1)) %>% 
  dplyr::filter(between(weekday, 1, 5)) %>% 
  dplyr::ungroup()

baseline <- strike_data %>% 
  dplyr::filter(date >= baseline_start & date <= baseline_end) %>% 
  dplyr::select(-date) %>% 
  dplyr::rename(people_count_baseline = peopleCount,
                resident_count_baseline = residentSum,
                worker_count_baseline = workerSum,
                visitor_count_baseline = visitorSum)

waterloo_with_baseline <- strike_data %>% 
  dplyr::left_join(baseline, by = join_by(weekday, msoa)) %>% 
  dplyr::filter(date >= "2023-03-13") %>% 
  dplyr::mutate(peopleCount_perc = peopleCount / people_count_baseline,
                residentSum_perc = residentSum / resident_count_baseline,
                workerSum_perc = workerSum / worker_count_baseline,
                visitorSum_perc = visitorSum / visitor_count_baseline)