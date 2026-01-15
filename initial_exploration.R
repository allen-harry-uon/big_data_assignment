library(jsonencryptor)
library(bigrquery)
library(DBI)
library(sparklyr)

##Authenticate for BQ connection
bigrquery::bq_auth(path = jsonencryptor::secret_read("service_secret.json"))

##Connect to big query
con <- DBI::dbConnect(
  bigrquery::bigquery(),
  project = "dft-gcp-mobilenetworkdata-prod", 
  dataset = "mobilenetwork_data_test"
)

sc <- spark_connect(master = "local", version = "4.0.1")

cars <- sparklyr::copy_to(sc, mtcars)

# spark_disconnect(sc)
