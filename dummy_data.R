n <- 26208
min <- 3000
max <- 30000

set.seed(123)

date <- seq(from = as.POSIXct("2024-01-01 00:00:00"), by = "5 min", length.out = 26208)

residentSum <- round(runif(n, min = min, max = max))

visitorSum <- round(runif(n, min = min, max = max))

workerSum <- round(runif(n, min = min, max = max))

peopleCount <- residentSum + visitorSum +workerSum

msoa <- "E02006801"

dummy_data <- dplyr::tibble(date, peopleCount, msoa, 
                            residentSum, visitorSum, workerSum) %>% 
  dplyr::mutate(time = strftime(date, format="%H:%M:%S"),
                date = as.Date(date)) %>% 
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

dummy_baseline <- dummy_data %>% 
  dplyr::filter(date >= "2024-01-01" & date <= "2024-01-07") %>% 
  dplyr::select(-date) %>% 
  dplyr::rename(people_count_baseline = peopleCount,
                resident_count_baseline = residentSum,
                worker_count_baseline = workerSum,
                visitor_count_baseline = visitorSum)

dummy_data_with_baseline <- dummy_data %>% 
  dplyr::left_join(dummy_baseline, by = join_by(weekday, msoa)) %>% 
  dplyr::filter(date >= "2024-01-07") %>% 
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