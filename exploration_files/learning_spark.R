library(sparklyr)
library(dplyr)
library(corrr)
library(ggplot2)
library(dbplot)

# Creating Spark connection
sc <- sparklyr::spark_connect(master = "local", version = "4.0.1")
# Add data to cluster
cars <- sparklyr::copy_to(sc, mtcars)

spark_read_csv(sc, "Test", DBI::dbGetQuery(con, "SELECT *
                              FROM od_agsp_msoa
                              LIMIT 10"))

# Testing dplyr functions
dplyr::summarise_all(cars, mean, na.rm = TRUE)

# Showing off SQL query
dplyr::summarise_all(cars, mean, na.rm = TRUE) %>% 
  dplyr::show_query()

# Testing more complex analysis
cars %>%
  dplyr::mutate(transmission = ifelse(am == 0, "automatic", "manual")) %>%
  dplyr::group_by(transmission) %>%
  dplyr::summarise_all(mean) %>% 
  dplyr::show_query()

# Using SQL functions not available in R
## Percentile function
dplyr::summarise(cars, mpg_percentile = percentile(mpg, 0.25)) %>% 
  dplyr::show_query()

## Array and explode function
dplyr::summarise(cars, mpg_percentile = percentile(mpg, array(0.25, 0.5, 0.75))) %>% 
  dplyr::mutate(mpg_percentile = explode(mpg_percentile))

# Correlation functions
sparklyr::ml_corr(cars)

corrr::correlate(cars, use = "pairwise.complete.obs", method = "pearson") 

corrr::correlate(cars, use = "pairwise.complete.obs", method = "pearson") %>%
  corrr::shave() %>%
  corrr::rplot()

# Visualising
ggplot(aes(as.factor(cyl), mpg), data = mtcars)+ 
  geom_col()

# Perform transformations in Spark before plotting
car_group <- cars %>%
  dplyr::group_by(cyl) %>%
  dplyr::summarise(mpg = sum(mpg, na.rm = TRUE)) %>%
  dplyr::collect() %>%
  print()

ggplot(aes(as.factor(cyl), mpg), data = car_group)+ 
  geom_col(fill = "#999999") + 
  coord_flip()

#Using dbplot to plot directly from Spark
cars %>%
  dbplot::dbplot_histogram(mpg, binwidth = 3) +
  labs(title = "MPG Distribution",
       subtitle = "Histogram over miles per gallon")

# Disconnect from Spark cluster
sparklyr::spark_disconnect(sc)
