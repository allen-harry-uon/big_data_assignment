library(sparklyr)
library(dplyr)
library(ggplot2)
library(leaflet)

# Getting variables 
source("exploration_files/variables.R")

# Run once to install spark
# sparklyr::spark_install(version = "4.0.1")
# Run to check spark installed correctly 
sparklyr::spark_installed_versions()

# Connect to local cluster
sc <- sparklyr::spark_connect(master = "local", version = "4.0.1")

## DO NOT RUN
## Example of how to read the data from BigQuery to Spark directly 
## The version of R and Spark are incompatible with this method
# spark_bq_example <- sparkbq::spark_read_bigquery(sc, name = "test_table",
#                                                  billingProjectId = "dtsg-ana-transporthubcrowdmon",
#                                                  datasetId = "crowd_monitoring_api",
#                                                  tableId = "msoa_counts",
#                                                  serviceAccountKeyFile = bigrquery::bq_auth(path = jsonencryptor::secret_read("service_secret.json")))

# Specifying column types to allow for faster reading into Spark
column_types <- c(date = "Date",
                  time = "POSIXct",
                  msoa = "character",
                  peopleCount = "integer",
                  residentSum = "integer",
                  workerSum = "integer",
                  visitorSum = "integer",
                  maleSum = "integer",
                  femaleSum = "integer",
                  seGradeC2Sum = "integer",
                  seGradeC1Sum = "integer",
                  seGradeDESum = "integer",
                  seGradeABSum = "integer")

baseline_column_types <- c(msoa = "character",
                           people_count_baseline = "double",
                           resident_count_baseline = "double",
                           worker_count_baseline = "double",
                           visitor_count_baseline = "double",
                           weekday = "integer")

se_baseline_column_types <- c(msoa = "character",
                              AB_baseline = "integer",
                              C1_baseline = "integer",
                              C2_baseline = "integer",
                              DE_baseline = "integer",
                              weekday = "integer")

# Reading in data to use for analysis
waterloo_data_sc <- sparklyr::spark_read_csv(sc, 
                                             name = "waterloo_data",
                                             path = "Data/crowd_data/waterloo_table.csv",
                                             columns = column_types,
                                             overwrite = TRUE)

# Reading in baselines for reason for travel and socioeconomic background
baseline_sc <- sparklyr::spark_read_csv(sc,
                                        name = "baseline",
                                        path = "Data/crowd_data/baseline.csv",
                                        columns = baseline_column_types,
                                        overwrite = TRUE)

se_baseline_sc <- sparklyr::spark_read_csv(sc,
                                           name = "se_baseline",
                                           path = "Data/crowd_data/se_baseline.csv",
                                           columns = se_baseline_column_types,
                                           overwrite = TRUE)

# Analysing strike data by reason for travel
strike_data_sc <- waterloo_data_sc %>% 
  # Using Spark date_format transformation as native R functions not compatible
  dplyr::mutate(time = date_format(time, "HH:mm:ss")) %>% 
  # Only looking at times during the workday and commuting
  dplyr::filter(time >= "08:00:00",
                time <= "19:00:00") %>% 
  dplyr::group_by(date, msoa) %>% 
  dplyr::summarise(peopleCount = sum(peopleCount, na.rm = TRUE),
                   residentSum = sum(residentSum, na.rm = TRUE),
                   workerSum = sum(workerSum, na.rm = TRUE),
                   visitorSum = sum(visitorSum, na.rm = TRUE)) %>% 
  dplyr::mutate(weekday = dayofweek(date)) %>% 
  # Filtering weekends to only show the work week data
  dplyr::filter(between(weekday, 2, 6)) %>% 
  dplyr::ungroup() %>% 
  # Joining baseline data
  dplyr::left_join(baseline_sc, by = join_by(weekday, msoa)) %>% 
  dplyr::filter(date >= "2023-03-13") %>% 
  # Calculating % of people compared to the baseline values
  dplyr::mutate(peopleCount_perc = peopleCount / people_count_baseline,
                residentSum_perc = residentSum / resident_count_baseline,
                workerSum_perc = workerSum / worker_count_baseline,
                visitorSum_perc = visitorSum / visitor_count_baseline) %>% 
  # Filtering for area after (hypothetically) aggregating whole data
  sparklyr::filter(msoa == waterloo_msoa) %>% 
  dplyr::select(date, residentSum_perc, workerSum_perc, 
                visitorSum_perc) %>% 
  # Pivoting table to plot multiple reasons for travel in one go
  tidyr::pivot_longer(cols = c(residentSum_perc, workerSum_perc, 
                               visitorSum_perc),
                      names_to = "travel_reason",
                      values_to = "perc") %>% 
  sparklyr::sdf_register(name = "strike_data")

# Collecting reduced data for plotting
strike_data_to_plot <- strike_data_sc %>% 
  sparklyr::collect()

# Socioeconomic analysis using Spark
se_background_sc <- waterloo_data_sc %>% 
  # Using Spark date_format transformation as native R functions not compatible
  dplyr::mutate(time = date_format(time, "HH:mm:ss")) %>% 
  # Only looking at times during the workday and commuting
  dplyr::filter(time >= "08:00:00",
                time <= "19:00:00") %>% 
  dplyr::group_by(date, msoa) %>% 
  dplyr::summarise(seGradeABSum = sum(seGradeABSum),
                   seGradeC1Sum = sum(seGradeC1Sum),
                   seGradeC2Sum = sum(seGradeC2Sum),
                   seGradeDESum = sum(seGradeDESum)) %>% 
  dplyr::mutate(weekday = dayofweek(date)) %>% 
  # Filtering weekends to only show the work week data
  dplyr::filter(between(weekday, 2, 6)) %>% 
  dplyr::ungroup() %>% 
  dplyr::left_join(se_baseline_sc, by = join_by(msoa, weekday)) %>% 
  dplyr::filter(date >= "2023-03-13") %>% 
  dplyr::mutate(AB_perc = seGradeABSum / AB_baseline,
                C1_perc = seGradeC1Sum / C1_baseline,
                C2_perc = seGradeC2Sum / C2_baseline,
                DE_perc = seGradeDESum / DE_baseline) %>% 
  # Filtering for area after aggregating whole data
  sparklyr::filter(msoa == waterloo_msoa) %>% 
  dplyr::select(date, AB_perc, C1_perc, C2_perc, DE_perc) %>% 
  # Pivoting table to plot multiple socioeconomic background grades in one go
  tidyr::pivot_longer(cols = c(AB_perc, C1_perc, C2_perc, DE_perc),
                      names_to = "socioeconomic_background",
                      values_to = "perc") %>% 
  sparklyr::collect()

# Gender analysis
twickenham_by_gender_sc <- waterloo_data_sc %>% 
  dplyr::mutate(hour = lubridate::hour(time)) %>% 
  dplyr::group_by(date, hour, msoa) %>% 
  dplyr::summarise(maleHourly = sum(maleSum),
                   femaleHourly = sum(femaleSum)) %>% 
  dplyr::mutate(datetime = as.POSIXct(paste(date, hour))) %>% 
  # Filter for date of event
  dplyr::filter(date == twickenham_rugby) %>% 
  # Filter for area of event
  dplyr::filter(msoa == twickenham_msoa) %>% 
  dplyr::ungroup() %>% 
  # Pivot table to plot male/female data in one go
  tidyr::pivot_longer(cols = c(maleHourly, femaleHourly),
                      names_to = "gender",
                      values_to = "count") %>% 
  sparklyr::collect()

# Uncomment and run when finished using Spark
# spark_disconnect(sc)
