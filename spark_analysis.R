library(sparklyr)
library(dplyr)
library(ggplot2)

# Run once to install spark
# sparklyr::spark_install(version = "4.0.1")
# Run to check spark installed correctly 
sparklyr::spark_installed_versions()

# Connect to local cluster
sc <- sparklyr::spark_connect(master = "local", version = "4.0.1")

# DO NOT RUN
# Example of how to read the data from BigQuery to Spark directly 
# The version of R and Spark are incompatible with this method
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
                  visitorSum = "integer")

baseline_column_types <- c(msoa = "character",
                           people_count_baseline = "double",
                           resident_count_baseline = "double",
                           worker_count_baseline = "double",
                           visitor_count_baseline = "double",
                           weekday = "integer")

waterloo_data_sc <- sparklyr::spark_read_csv(sc, 
                                             name = "waterloo_data",
                                             path = "Data/crowd_data/waterloo_table.csv", 
                                             columns = column_types)

baseline_sc <- sparklyr::spark_read_csv(sc,
                                        name = "baseline",
                                        path = "Data/crowd_data/baseline.csv",
                                        columns = baseline_column_types)

strike_data_sc <- waterloo_data_sc %>% 
  sparklyr::filter(msoa %in% msoa_codes) %>% 
  # Using Spark date_format transformation as native R functions not compatible
  dplyr::mutate(time = date_format(time, "HH:mm:ss")) %>% 
  dplyr::filter(time >= "08:00:00",
                time <= "19:00:00") %>% 
  dplyr::group_by(date, msoa) %>% 
  dplyr::summarise(peopleCount = mean(peopleCount, na.rm = TRUE),
                   residentSum = mean(residentSum, na.rm = TRUE),
                   workerSum = mean(workerSum, na.rm = TRUE),
                   visitorSum = mean(visitorSum, na.rm = TRUE)) %>% 
  dplyr::mutate(weekday = dayofweek(date)) %>% 
  dplyr::filter(between(weekday, 2, 6)) %>% 
  dplyr::ungroup() %>% 
  # Joining baseline data
  dplyr::left_join(baseline_sc, by = join_by(weekday, msoa)) %>% 
  dplyr::filter(date >= "2023-03-13") %>% 
  dplyr::mutate(peopleCount_perc = peopleCount / people_count_baseline,
                residentSum_perc = residentSum / resident_count_baseline,
                workerSum_perc = workerSum / worker_count_baseline,
                visitorSum_perc = visitorSum / visitor_count_baseline) %>% 
  dplyr::select(date, residentSum_perc, workerSum_perc, 
                visitorSum_perc) %>% 
  tidyr::pivot_longer(cols = c(residentSum_perc, workerSum_perc, 
                               visitorSum_perc),
                      names_to = "travel_reason",
                      values_to = "perc") %>% 
  sparklyr::sdf_register(name = "strike_data")

# Collecting reduced data for plotting
strike_data_to_plot <- strike_data_sc %>% 
  sparklyr::collect()

# Plotting strike data
ggplot(data = strike_data_to_plot, aes(x = date,
                                  y = perc,
                                  group = travel_reason,
                                  colour = travel_reason))+
  geom_line(linewidth = 1)+
  scale_colour_manual(values = palette)+
  scale_y_continuous(labels = scales::label_percent(),
                     limits = c(0, 1.5),
                     name = "")+
  scale_x_date(name = "Date")+
  ggplot2::theme(panel.background = ggplot2::element_rect(fill = "white"),
                 panel.grid.major.y = ggplot2::element_line(colour = "grey", linewidth = 0.1),
                 strip.background = ggplot2::element_rect(fill = "white"),
                 axis.line.x = ggplot2::element_line(colour = "black", linewidth = 1),
                 axis.line.y = ggplot2::element_line(colour = "black", linewidth = 1))+
  geom_vline(xintercept = all_strike_date,
             colour = "grey")+
  geom_vline(xintercept = all_bank_hols,
             colour = "grey",
             linetype = "dashed")+
  geom_hline(yintercept = 1,
             colour = "black",
             size = 1)+
  annotate("label",
           label = "Solid line =\n Train strikes",
           x = as.Date("2023-05-21"),
           y = 1.5)+
  annotate("label",
           label = "Dashed line =\n Bank holidays",
           x = as.Date("2023-05-21"),
           y = 1.35)+
  labs(colour = "Reason for travel")

# Plotting most recent data on map
waterloo_mapped <- waterloo_data_sc %>% 
  dplyr::filter(date == max(date),
                time == max(time)) %>% 
  sparklyr::collect()

# Uncomment and run when finished using Spark
# spark_disconnect(sc)
