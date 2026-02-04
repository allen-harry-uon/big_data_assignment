library(sparklyr)

# Run once to install spark
sparklyr::spark_install(version = "4.0.1")
# Run to check spark installed correctly 
sparklyr::spark_installed_versions()

# Connect to local cluster
sc <- sparklyr::spark_connect(master = "local", version = "4.0.1")

column_types <- c(date = "Date",
                  time = "POSIXct",
                  msoa = "character",
                  peopleCount = "integer",
                  residentSum = "integer",
                  workerSum = "integer",
                  visitorSum = "integer")

waterloo_data_sc <- sparklyr::spark_read_csv(sc, "Data/waterloo_table.csv", columns = column_types)