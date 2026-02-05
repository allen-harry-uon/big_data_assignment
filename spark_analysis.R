library(sparklyr)

# Run once to install spark
# sparklyr::spark_install(version = "4.0.1")
# Run to check spark installed correctly 
sparklyr::spark_installed_versions()

# Connect to local cluster
sc <- sparklyr::spark_connect(master = "local", version = "4.0.1")

# Specifying column types to allow for faster reading into Spark
column_types <- c(date = "Date",
                  time = "POSIXct",
                  msoa = "character",
                  peopleCount = "integer",
                  residentSum = "integer",
                  workerSum = "integer",
                  visitorSum = "integer")

baseline_column_types <- c(msoa = "character",
                           peopleCount = "double",
                           residentSum = "double",
                           workerSum = "double",
                           visitorSum = "double",
                           weekday = "integer")

waterloo_data_sc <- sparklyr::spark_read_csv(sc, 
                                             name = "waterloo_data",
                                             path = "Data/crowd_data/waterloo_table.csv", 
                                             columns = column_types)

baseline_sc <- sparklyr::spark_read_csv(sc,
                                        name = "baseline",
                                        path = "Data/crowd_data/baseline.csv",
                                        columns = baseline_column_types)

# When finished using Spark
spark_disconnect(sc)