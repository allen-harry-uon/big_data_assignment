library(bigrquery)
library(DBI)
library(dplyr)

strike_data <- DBI::dbGetQuery(con, "SELECT date, 
                                            msoa,
                                            SUM(residentSum), 
                                            SUM(workerSum), 
                                            SUM(visitorSum)
                                     FROM msoa_counts
                                     WHERE msoa = 'E02006801'
                                     GROUP BY date, msoa")

baseline <- DBI::dbGetQuery(con, "SELECT date, 
                                            msoa,
                                            SUM(residentSum), 
                                            SUM(workerSum), 
                                            SUM(visitorSum)
                                     FROM msoa_counts
                                     WHERE msoa = 'E02006801'
                                     AND date >= '2023-03-06'
                                     AND date <= '2023-03-12'
                                     GROUP BY date, msoa")