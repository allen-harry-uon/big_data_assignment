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