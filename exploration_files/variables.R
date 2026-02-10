## Setting variables so they're not hard coded
library(purrr)
library(sf)

# MSOA shape codes to filter by (as if reading entire dataset from BigQuery)
msoa_codes <- c("E02006801", "E02000794")
all_msoa <- toString(sQuote(msoa_codes, q = F))

waterloo_msoa <- "E02006801"
twickenham_msoa <- "E02000794"

# Reading shapefiles for mapping
msoa_shapefile <- sf::read_sf("Data/map/Middle_layer_Super_Output_Areas_(December_2021)_Boundaries_EW_BFE_(V8)_and_RUC.shp")
selected_shapes <- msoa_shapefile %>% 
  dplyr::filter(MSOA21CD %in% msoa_codes)

# Baseline dates
baseline_start <- "2023-03-06"
baseline_end <- "2023-03-12"

# Strike dates
strike_date_1 <- "2023-03-15"
strike_date_2 <- "2023-03-16"
strike_date_3 <- "2023-03-18"
strike_date_4 <- "2023-05-12"
strike_date_5 <- "2023-05-13"
strike_date_6 <- "2023-03-30"
strike_date_7 <- "2023-04-01"

all_strike_date <- c(strike_date_1,strike_date_2, strike_date_3,
                     strike_date_4, strike_date_5, strike_date_6,
                     strike_date_7) %>% 
  purrr::map_vec(as.Date)

# Bank holidays
bank_hol_date_1 <- "2023-05-01"
bank_hol_date_2 <- "2023-05-08"
bank_hol_date_3 <- "2023-05-29"

all_bank_hols <- c(bank_hol_date_1, bank_hol_date_2, bank_hol_date_3) %>% 
  purrr::map_vec(as.Date)

# Event dates
twickenham_rugby <- "2023-03-11"

# Chart colour palette
palette <- c("#004D3B", # Corporate Green
             "#3C9F8B", # Transit Green
             "#001A70", # Navy Blue
             "#339BD5", # Sky Blue
             "#4C2C92", # Violet
             "#D65AFC", # Lilac
             "#8A003E", # Cherry
             "#FF479A", # Pink
             "#969810", # Country Green
             "#D5811A", # Coastal Line
             "#FE5500") # Traffic Tanago

chart_theme <- ggplot2::theme(panel.background = ggplot2::element_rect(fill = "white"),
                              panel.grid.major.y = ggplot2::element_line(colour = "grey", linewidth = 0.1),
                              strip.background = ggplot2::element_rect(fill = "white"),
                              axis.line.x = ggplot2::element_line(colour = "black", linewidth = 1),
                              axis.line.y = ggplot2::element_line(colour = "black", linewidth = 1))