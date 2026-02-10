# Project format

The project is written solely in R to perform the analysis using Spark and a report with the findings was written using markdown. There will be a html output
of the report to view.

The R code is split into three files:
* A file for variables (`variables.R`)
* A file for initial analysis (`strike_analysis.R`)
* A file for Spark analysis (`spark_analysis.R`)

The first two are in the `exploration_files` folder, along with an `initial_exploration.R` file that is not in use but is being retained for a full look
at the steps taken in this project. 

# How to run the code

When you've cloned the repo, you will need to run `renv::restore()` in the console to download and install the packages used in this project.

After that, you will need to have the encrypted json key and `GARGLE_PASSWORD` to access the data used in BigQuery, otherwise use the data in the 
`dummy_data.R` file. You will need to run up to line 147 of the `strike_analysis.R` file to create the csv's used for the Spark analysis. 

In the `spark_analysis.R` file, uncomment line 10 to install Spark on your local computer and comment it back out as this only needs to be run once. The you 
can run the rest of the code in this file to make sure it works as expected. 

With this, you should be able to generate the `index.Rmd` report. 