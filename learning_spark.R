library(sparklyr)

# Creating Spark connection
sc <- sparklyr::spark_connect(master = "local", version = "4.0.1")

cars <- sparklyr::copy_to(sc, mtcars)

# Disconnect from Spark cluster
sparklyr::spark_disconnect(sc)
