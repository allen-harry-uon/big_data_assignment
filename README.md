# Project format

The project is written solely in R to perform the analysis using Spark and a report with the findings was written using markdown. There will be a html output
of the report to view.

The R code is split into three files:
* A file for variables (`variables.R`)
* A file for initial analysis (`strike_analysis.R`)
* A file for Spark analysis (`spark_analysis.R`)

The first two are in the `exploration_files` folder, along with an `initial_exploration.R` file that is not in use but is being retained for a full look
at the steps taken in this project. 