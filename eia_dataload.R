####################################################
# Pull Daily Regional Fuel Mix - ISNE and PJM
# Targeted pull for exact price observation dates
####################################################
library(tidyverse)
library(httr)
library(jsonlite)

eia_api_key <- "UhdZNEINPQj9mdr8f6wOS5KQliGFaOlZYOOMBZdD"

# Target dates from price data
target_dates <- sort(unique(prices$Date))
message("Pulling mix data for ", length(target_dates), " target dates")

# Split into 15-day chunks
chunk_size  <- 15
date_chunks <- split(target_dates, ceiling(seq_along(target_dates) / chunk_size))

# Loop through each chunk
all_mix <- map_df(seq_along(date_chunks), function(i) {
  
  chunk <- date_chunks[[i]]
  start <- min(chunk)
  end   <- max(chunk)
  message("Downloading chunk ", i, "/", length(date_chunks), 
          ": ", start, " to ", end)
  
  url <- paste0(
    "https://api.eia.gov/v2/electricity/rto/daily-fuel-type-data/data/",
    "?api_key=", eia_api_key,
    "&frequency=daily&data[0]=value",
    "&facets[respondent][]=ISNE&facets[respondent][]=PJM",
    "&facets[timezone][]=Eastern",
    "&start=", start, "&end=", end,
    "&length=5000"
  )
  
  r <- fromJSON(content(GET(url), "text", encoding = "UTF-8"))
  n <- nrow(r$response$data)
  message("  Got ", n, " rows")
  
  if(n == 5000) warning("Chunk ", i, " hit limit - needs splitting!")
  
  Sys.sleep(0.5)
  return(r$response$data)
})

# Clean fuel type names and aggregate
mix_load_full <- all_mix %>%
  mutate(`type-name` = case_when(
    `type-name` %in% c("Battery", "Battery storage", "Solar Battery",
                       "Solar with integrated battery storage") ~ "Battery storage",
    `type-name` %in% c("Pumped storage", "Pumped Storage")     ~ "Pumped storage",
    TRUE ~ `type-name`
  )) %>%
  mutate(date = as.Date(period)) %>%
  filter(date %in% target_dates) %>%
  group_by(date, respondent, `type-name`) %>%
  summarise(daily_mwh = sum(as.numeric(value), na.rm = TRUE), .groups = "drop")

# Verify
mix_load_full %>%
  mutate(year = year(date)) %>%
  group_by(year, respondent) %>%
  summarise(n_dates = n_distinct(date), .groups = "drop") %>%
  print(n = 30)

message("Total unique dates: ",  n_distinct(mix_load_full$date))
message("Target dates matched: ", sum(unique(mix_load_full$date) %in% target_dates),
        " of ", length(target_dates))
message("Date range: ", paste(range(mix_load_full$date), collapse = " to "))

write_csv(mix_load_full,
          "~/Documents/GitHub/Algonquin_NatGas/data/region_fuelmix_targeted.csv")

message("Done!")