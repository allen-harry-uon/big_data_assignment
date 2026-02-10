## Developing dummy data
library(lubridate)
# Setting variables for creating dummy data
n <- 26208
min <- 3000
max <- 30000

set.seed(123)

# Setting date sequence to match the 5 minute intervals of data used
date <- seq(from = as.POSIXct("2023-03-03 00:00:00"), by = "5 min", length.out = 26208)
time <- format(as.POSIXct(date), "%H:%M:%S")

# Generating dummy reason for travel data
residentSum <- round(runif(n, min = min, max = max))
visitorSum <- round(runif(n, min = min, max = max))
workerSum <- round(runif(n, min = min, max = max))
peopleCount <- residentSum + visitorSum +workerSum
# Gernerating dummy gender data
maleSum <- round(runif(n, min = min, max = max))
femaleSum <- round(runif(n, min = min, max = max))
# Generating dummy socioeconomic background data
seGradeC2Sum <- round(runif(n, min = min, max = max))
seGradeC1Sum <- round(runif(n, min = min, max = max))
seGradeDESum <- round(runif(n, min = min, max = max))
seGradeABSum <- round(runif(n, min = min, max = max))
# MSOAs
waterloo_msoa <- "E02006801"
twickenham_msoa <- "E02000794"

dummy_data <- dplyr::tibble(date, time, waterloo_msoa, peopleCount, residentSum,
                            workerSum,  visitorSum, maleSum, femaleSum, seGradeC2Sum, seGradeC1Sum, seGradeDESum, 
                            seGradeABSum) %>% 
  dplyr::mutate(date = as.Date(date)) %>% 
  dplyr::rename(msoa = waterloo_msoa)

readr::write_csv(dummy_data, "Data/crowd_data/dummy_data.csv")

dummy_baseline <- dummy_data %>% 
  dplyr::filter(hms::as_hms(time) >= hms("08:00:00"),
                hms::as_hms(time) <= hms("19:00:00")) %>% 
  dplyr::group_by(date, msoa) %>% 
  dplyr::summarise(peopleCount = sum(peopleCount),
                   residentSum = sum(residentSum),
                   workerSum = sum(workerSum),
                   visitorSum = sum(visitorSum)) %>% 
  dplyr::mutate(weekday = lubridate::wday(date)) %>% 
  # Removing weekend for only work week analysis
  dplyr::filter(between(weekday, 2, 6)) %>% 
  dplyr::ungroup() %>% 
  dplyr::filter(date >= baseline_start & date <= baseline_end) %>% 
  dplyr::select(-date) %>% 
  dplyr::rename(people_count_baseline = peopleCount,
                resident_count_baseline = residentSum,
                worker_count_baseline = workerSum,
                visitor_count_baseline = visitorSum)

readr::write_csv(dummy_baseline, "Data/crowd_data/dummy_baseline.csv")

dummy_baseline_se <- dummy_data %>% 
  dplyr::filter(hms::as_hms(time) >= hms("08:00:00"),
                hms::as_hms(time) <= hms("19:00:00")) %>% 
  dplyr::group_by(date, msoa) %>% 
  dplyr::summarise(seGradeABSum = sum(seGradeABSum),
                   seGradeC1Sum = sum(seGradeC1Sum),
                   seGradeC2Sum = sum(seGradeC2Sum),
                   seGradeDESum = sum(seGradeDESum)) %>% 
  dplyr::mutate(weekday = lubridate::wday(date)) %>% 
  # Removing weekend for only work week analysis
  dplyr::filter(between(weekday, 2, 6)) %>% 
  dplyr::ungroup() %>% 
  dplyr::filter(date >= baseline_start & date <= baseline_end) %>% 
  dplyr::select(-date) %>% 
  dplyr::rename(AB_baseline = seGradeABSum,
                C1_baseline = seGradeC1Sum,
                C2_baseline = seGradeC2Sum,
                DE_baseline = seGradeDESum) %>% 
  dplyr::select(msoa, AB_baseline, C1_baseline, C2_baseline, DE_baseline, weekday)

readr::write_csv(dummy_baseline_se, "Data/crowd_data/dummy_baseline_se.csv")