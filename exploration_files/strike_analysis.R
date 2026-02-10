library(jsonencryptor)
library(bigrquery)
library(DBI)
library(dplyr)
library(lubridate)
library(ggplot2)

source("exploration_files/variables.R")

##Authenticate for BQ connection
bigrquery::bq_auth(path = jsonencryptor::secret_read("service_secret.json"))

con <- DBI::dbConnect(
  bigrquery::bigquery(),
  project = "dtsg-ana-transporthubcrowdmon", 
  dataset = "crowd_monitoring_api"
)

waterloo_data <- DBI::dbGetQuery(con, paste("SELECT date,
                                            time,
                                            msoa,
                                            peopleCount,
                                            residentSum, 
                                            workerSum, 
                                            visitorSum,
                                            maleSum, 
                                            femaleSum,
                                            seGradeC2Sum,
                                            seGradeC1Sum,
                                            seGradeDESum,
                                            seGradeABSum
                                     FROM msoa_counts
                                     WHERE msoa IN (", all_msoa, ")", sep = ""))

readr::write_csv(waterloo_data, "Data/waterloo_table.csv")

strike_data <- waterloo_data %>% 
  dplyr::filter(msoa == waterloo_msoa) %>% 
  dplyr::filter(hms::as_hms(time) >= hms("08:00:00"),
                hms::as_hms(time) <= hms("19:00:00")) %>% 
  dplyr::group_by(date, msoa) %>% 
  dplyr::summarise(peopleCount = mean(peopleCount),
                   residentSum = mean(residentSum),
                   workerSum = mean(workerSum),
                   visitorSum = mean(visitorSum)) %>% 
  dplyr::mutate(weekday = lubridate::wday(date)) %>% 
  dplyr::filter(between(weekday, 2, 6)) %>% 
  dplyr::ungroup()
  
baseline <- strike_data %>% 
  dplyr::filter(date >= baseline_start & date <= baseline_end) %>% 
  dplyr::select(-date) %>% 
  dplyr::rename(people_count_baseline = peopleCount,
                resident_count_baseline = residentSum,
                worker_count_baseline = workerSum,
                visitor_count_baseline = visitorSum)

readr::write_csv(baseline, "Data/crowd_data/baseline.csv")

waterloo_with_baseline <- strike_data %>% 
  dplyr::left_join(baseline, by = join_by(weekday, msoa)) %>% 
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
                      values_to = "perc")
  
ggplot(data = waterloo_with_baseline, aes(x = date,
                                          y = perc,
                                          group = travel_reason,
                                          colour = travel_reason))+
  geom_line(linewidth = 1)+
  scale_colour_manual(values = palette)+
  scale_y_continuous(labels = scales::label_percent(),
                     limits = c(0, 1.5),
                     name = "")+
  scale_x_date(name = "Date")+
  chart_theme+
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

se_background <- waterloo_data %>% 
  dplyr::filter(msoa == waterloo_msoa) %>% 
  dplyr::filter(hms::as_hms(time) >= hms("08:00:00"),
                hms::as_hms(time) <= hms("19:00:00")) %>% 
  dplyr::group_by(date, msoa) %>% 
  dplyr::summarise(seGradeABSum = sum(seGradeABSum),
                   seGradeC1Sum = sum(seGradeC1Sum),
                   seGradeC2Sum = sum(seGradeC2Sum),
                   seGradeDESum = sum(seGradeDESum)) %>% 
  dplyr::mutate(weekday = lubridate::wday(date)) %>% 
  dplyr::filter(between(weekday, 2, 6)) %>% 
  dplyr::ungroup() %>% 
  tidyr::pivot_longer(cols = c(seGradeABSum, seGradeC1Sum, 
                               seGradeC2Sum, seGradeDESum),
                      names_to = "socioeconomic_background",
                      values_to = "sum")

se_baseline <- se_background %>% 
  dplyr::filter(date >= baseline_start & date <= baseline_end) %>% 
  dplyr::select(-date) %>% 
  dplyr::rename(AB_baseline = seGradeABSum,
                C1_baseline = seGradeC1Sum,
                C2_baseline = seGradeC2Sum,
                DE_baseline = seGradeDESum)

se_with_baseline <- se_background %>% 
  dplyr::left_join(se_baseline, by = join_by(msoa, weekday)) %>% 
  dplyr::filter(date >= "2023-03-13") %>% 
  dplyr::mutate(AB_perc = seGradeABSum / AB_baseline,
                C1_perc = seGradeC1Sum / C1_baseline,
                C2_perc = seGradeC2Sum / C2_baseline,
                DE_perc = seGradeDESum / DE_baseline) %>% 
  dplyr::select(date, AB_perc, C1_perc, C2_perc, DE_perc) %>% 
  tidyr::pivot_longer(cols = c(AB_perc, C1_perc, C2_perc, DE_perc),
                      names_to = "socioeconomic_background",
                      values_to = "perc")

ggplot(data = se_with_baseline, aes(x = date,
                                 y = perc,
                                 group = socioeconomic_background,
                                 colour = socioeconomic_background))+
  geom_line()+
  scale_y_continuous(labels = scales::percent,
                     limits = c(0, 1.2))+
  chart_theme+
  geom_hline(yintercept = 1,
             colour = "black",
             linewidth = 1)+
  geom_vline(xintercept = all_strike_date,
             colour = "grey")+
  geom_vline(xintercept = all_bank_hols,
             colour = "grey",
             linetype = "dashed")+
  facet_wrap(~socioeconomic_background,
             scales = "free")

twickenham_by_gender <- waterloo_data %>% 
  dplyr::filter(msoa == twickenham_msoa) %>% 
  dplyr::filter(date == twickenham_rugby) %>% 
  dplyr::mutate(hour = lubridate::hour(time)) %>% 
  dplyr::group_by(date, hour, msoa) %>% 
  dplyr::summarise(maleHourly = sum(maleSum),
                   femaleHourly = sum(femaleSum)) %>% 
  dplyr::mutate(datetime = as.POSIXct(paste(date, hour), format = "%Y-%m-%d %H")) %>% 
  dplyr::ungroup() %>% 
  tidyr::pivot_longer(cols = c(maleHourly, femaleHourly),
                      names_to = "gender",
                      values_to = "count")

nighttime <- data.frame(
  xmin = c("2023-03-11 14:00"),
  xmax = c("2023-03-11 19:00"),
  ymin = -Inf,
  ymax = Inf
) %>% 
  dplyr::mutate(xmin = as.POSIXct(xmin),
                xmax = as.POSIXct(xmax))
  
ggplot(data = twickenham_by_gender, aes(x = datetime,
                                      y = count,
                                      group = gender,
                                      colour = gender))+
  geom_line()+
  geom_rect(data = nighttime,
            aes(xmin = xmin, 
                xmax = xmax, 
                ymin = ymin, 
                ymax = ymax),
            fill = "grey", alpha = 0.3,
            inherit.aes = FALSE)+
  chart_theme+
  scale_x_datetime(name = "",
                   date_labels = "%H:%M")+
  scale_y_continuous(labels = scales::comma,
                     name = "")