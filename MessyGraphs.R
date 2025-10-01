library(quantmod)
library(ggplot2)
library(scales)
library(dplyr)
library(lubridate)

# Tickers (Yahoo symbols)
wti_ticker <- "CL=F"
brent_ticker <- "BZ=F"

# Date range (all of 2024)
start_date <- as.Date("2024-01-01")
end_date <- as.Date("2024-12-31")

# Download historical data
getSymbols(wti_ticker, src = "yahoo", from = start_date, to = end_date, auto.assign = TRUE)
getSymbols(brent_ticker, src = "yahoo", from = start_date, to = end_date, auto.assign = TRUE)

# Extract closing prices
wti <- Cl(get(wti_ticker))
brent <- Cl(get(brent_ticker))

# Combine into one data frame / xts
prices <- na.omit(merge(wti, brent))
colnames(prices) <- c("WTI", "Brent")

# Convert to tidy data.frame for ggplot
df <- data.frame(
  date = index(prices),
  coredata(prices)
) %>%
  pivot_longer(cols = c("WTI", "Brent"),
               names_to = "Contract",
               values_to = "Price")

# Plot with ggplot (overlay)
p <- ggplot(df, aes(x = date, y = Price, color = Contract)) +
  geom_line(size = 1) +
  scale_color_manual(values = c(WTI = "steelblue", Brent = "darkorange")) +
  labs(title = "WTI vs Brent Futures — 2024",
       subtitle = "Daily closing prices (USD) for year 2024",
       x = "Date",
       y = "Price (USD)",
       color = "Contract") +
  theme_minimal() +
  theme(legend.position = "top")

# Print the plot

disasters <- read_csv("~/Documents/GitHub/ENVS_Seniorthesis/data/tx_disaster_raw.csv")



disasters <- disasters %>%
  mutate(
    Begin.Date = as.Date(`Begin Date`, format = "%B %d, %Y"),
    End.Date   = as.Date(`End Date`, format = "%B %d, %Y")
  ) %>%
  filter(year(Begin.Date) == 2024)  # only 2024 disasters


p <- ggplot(df, aes(x = date, y = Price, color = Contract)) +
  geom_line(size = 1) +
  scale_color_manual(values = c(WTI = "steelblue", Brent = "darkorange")) +
  labs(title = "WTI vs Brent Futures with 2024 Texas Weather Disasters",
       subtitle = "Daily closing prices (USD) with annotated disaster events",
       x = "Date",
       y = "Price (USD)") +
  theme_minimal() +
  theme(legend.position = "top")

# ---- Add Disaster Annotations ----
# Vertical dashed lines at disaster start dates
p <- p +
  geom_point(data = disasters,
             aes(x = Begin.Date,
                 y = Price),          # need to align disaster date to price
             inherit.aes = FALSE,
             color = "red", size = 3, shape = 21, fill = "red", alpha = 0.8)


plot(p)



disasters <- disasters %>%
  mutate(Begin.Date = as.Date(Begin.Date, format = "%B %d, %Y"))

# Merge (left join) so each price observation has a disaster flag/label
df_joined <- df %>%
  left_join(disasters, by = c("date" = "Begin.Date"))

# Now df_joined has Event, Type, etc. attached where the dates match

# Plot: lines + highlight dots where disaster events exist
p <- ggplot(df_joined, aes(x = date, y = Price, color = Contract)) +
  geom_line(size = 1) +
  geom_point(data = df_joined %>% filter(!is.na(Event)), 
             aes(x = date, y = Price), 
             shape = 21, fill = "red", size = 3, color = "black") +
  scale_color_manual(values = c(WTI = "steelblue", Brent = "darkorange")) +
  labs(title = "WTI vs Brent Futures with Texas Weather Disasters (2024)",
       subtitle = "Red dots mark disaster start dates",
       x = "Date",
       y = "Price (USD)") +
  theme_minimal() +
  theme(legend.position = "top") + theme_minimal()

print(p)


disasters <- disasters %>%
  mutate(
    Begin.Date = as.Date(Begin.Date, format = "%B %d, %Y"),
    End.Date   = as.Date(End.Date, format = "%B %d, %Y")
  ) %>%
  filter(year(Begin.Date) == 2024)

# ---- Oil Prices Data ----
# Assuming your tidy price data is already in `df`
# Columns: date, Contract (WTI/Brent), Price

# ---- Plot ----
p <- ggplot() +
  # Highlight disaster spans with shaded rectangles
  geom_rect(data = disasters,
            aes(xmin = Begin.Date, xmax = End.Date,
                ymin = -Inf, ymax = Inf, fill = Type),
            inherit.aes = FALSE, alpha = 0.15) +
  
  # Add WTI and Brent lines
  geom_line(data = df, aes(x = date, y = Price, color = Contract), size = 1) +
  
  # Add dots at disaster *begin* dates
  geom_point(data = df %>% filter(date %in% disasters$Begin.Date),
             aes(x = date, y = Price, color = Contract),
             size = 3, shape = 21, fill = "red") +
  
  # Color scheme for WTI/Brent
  scale_color_manual(values = c(WTI = "steelblue", Brent = "darkorange")) +
  
  # Optional: set custom fills for disaster types
  scale_fill_manual(values = c(
    "Tropical Cyclone" = "red",
    "Severe Storm" = "purple",
    "Winter Storm" = "lightblue",
    "Flood" = "darkgreen",
    "Drought" = "goldenrod",
    "Wildfire" = "brown"
  )) +
  
  labs(
    title = "WTI vs Brent Futures with Texas Weather Disasters (2024)",
    subtitle = "Blue = WTI, Orange = Brent. Shaded spans show disaster periods; red dots = start dates.",
    x = "Date",
    y = "Price (USD)",
    color = "Contract",
    fill = "Disaster Type"
  ) +
  theme_minimal() +
  theme(legend.position = "top")



library(dplyr)
library(ggplot2)
library(lubridate)

# Assume df = oil price data with cols: date, Contract, Price
# Pivot wider so we can compute min/max between WTI & Brent
df_wide <- df %>%
  tidyr::pivot_wider(names_from = Contract, values_from = Price) %>%
  mutate(min_price = pmin(WTI, Brent, na.rm = TRUE),
         max_price = pmax(WTI, Brent, na.rm = TRUE))

# Expand each disaster span into daily rows so we can join with df_wide
disaster_expanded <- disasters %>%
  rowwise() %>%
  do(data.frame(date = seq(.$Begin.Date, .$End.Date, by = "day"),
                Type = .$Type,
                Event = .$Event)) %>%
  ungroup()

# Merge with price data
highlight_df <- df_wide %>%
  left_join(disaster_expanded, by = "date") %>%
  filter(!is.na(Type))   # keep only days inside disasters

# ---- Plot ----
p <- ggplot() +
  # Shaded area between WTI and Brent during disasters
  geom_ribbon(data = highlight_df,
              aes(x = date, ymin = min_price, ymax = max_price, fill = Type),
              alpha = 0.2) +
  
  # WTI & Brent lines
  geom_line(data = df, aes(x = date, y = Price, color = Contract), size = 1) +
  
  # Dots at disaster *begin* dates
  geom_point(data = df %>% filter(date %in% disasters$Begin.Date),
             aes(x = date, y = Price, color = Contract),
             size = 3, shape = 21, fill = "white", stroke = 1.2) +
  
  # Colors
  scale_color_manual(values = c(WTI = "steelblue", Brent = "darkorange")) +
  scale_fill_manual(values = c(
    "Tropical Cyclone" = "blue",  # light orange
    "Severe Storm"     = "cyan",  # soft blue
    "Winter Storm"     = "#BCBDDC",  # lavender
    "Flood"            = "#A1D99B",  # pale green
    "Drought"          = "tomato3",  # light yellow
    "Wildfire"         = "red2"   # salmon pink
  ))+
  
  labs(
    title = "WTI vs Brent Futures with Texas Weather Disasters (2024)",
    subtitle = "Shaded spans show disaster periods between Brent & WTI prices.",
    x = "Date",
    y = "Price (USD)",
    color = "Contract",
    fill = "Disaster Type"
  ) +
  theme_bw() +
  theme(legend.position = "top")

print(p)
# Show the plot

library(ggplot2)
library(dplyr)

# Use the same joined dataset with disaster spans expanded (highlight_df from earlier)

# Facet by Type (disaster category)
p_facet <- ggplot() +
  # Shaded spans between Brent & WTI
  geom_ribbon(data = highlight_df,
              aes(x = date, ymin = min_price, ymax = max_price, fill = Type),
              alpha = 0.2) +
  
  # WTI & Brent lines
  geom_line(data = df, aes(x = date, y = Price, color = Contract), size = 1) +
  
  # Start date dots
  geom_point(data = df %>% filter(date %in% disasters$Begin.Date),
             aes(x = date, y = Price, color = Contract),
             size = 2.5, shape = 21, fill = "red") +
  
  # End date dots
  geom_point(data = df %>% filter(date %in% disasters$End.Date),
             aes(x = date, y = Price, color = Contract),
             size = 2.5, shape = 21, fill = "white", stroke = 1) +
  
  # Color scheme
  scale_color_manual(values = c(WTI = "steelblue", Brent = "darkorange")) +
  scale_fill_manual(values = c(
    "Tropical Cyclone" = "blue",  # light orange
    "Severe Storm"     = "cyan",  # soft blue
    "Winter Storm"     = "green",  # lavender
    "Flood"            = "#A1D99B",  # pale green
    "Drought"          = "tomato3",  # light yellow
    "Wildfire"         = "red2"   # salmon pink
  )) +
  
  labs(
    title = "WTI vs Brent Futures Faceted by Disaster Type (2024)",
    subtitle = "Each panel highlights Texas weather disasters of a specific type.",
    x = "Date",
    y = "Price (USD)",
    color = "Contract",
    fill = "Disaster Type"
  ) +
  theme_minimal() +
  theme(legend.position = "top") +
  facet_wrap(~Type, scales = "free_y")

print(p_facet)





library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)

# ---- Prep Data ----
# df has columns: date, Contract (WTI/Brent), Price
df_wide <- df %>%
  pivot_wider(names_from = Contract, values_from = Price) %>%
  arrange(date) %>%
  mutate(spread = Brent - WTI,
         spread_sign = sign(spread),
         crossing = spread_sign != lag(spread_sign))

# ---- Filter disasters ----
disasters_filtered <- disasters %>%
  filter(Type %in% c("Tropical Cyclone", "Severe Storm")) %>%
  mutate(Begin.Date = as.Date(Begin.Date),
         End.Date   = as.Date(End.Date))

# ---- Build crossing periods ----
crossing_dates <- df_wide %>% filter(crossing == TRUE) %>% pull(date)

# Create a dataset of highlight windows:
highlight <- expand.grid(crossing_date = crossing_dates,
                         disaster_id = 1:nrow(disasters_filtered)) %>%
  left_join(disasters_filtered %>% mutate(disaster_id = row_number()), by="disaster_id") %>%
  filter(crossing_date >= Begin.Date & crossing_date <= End.Date)

# ---- Plot ----
p <- ggplot(df_wide, aes(x = date)) +
  # Disaster-specific shading around crossing points
  geom_vline(data = highlight, aes(xintercept = crossing_date, color = Type),
             linetype = "dashed", alpha = 0.7) +
  
  geom_line(aes(y = WTI, color = "WTI"), size = 1) +
  geom_line(aes(y = Brent, color = "Brent"), size = 1) +
  
  scale_color_manual(values = c("WTI" = "steelblue", "Brent" = "darkorange",
                                "Tropical Cyclone" = "#FF7F0E",
                                "Severe Storm" = "#1F77B4")) +
  
  labs(title = "WTI vs Brent with Crossings During Texas Tropical Cyclones & Severe Storms (2024)",
       subtitle = "Dashed lines mark crossing points during disaster windows",
       x = "Date", y = "Price (USD)", color = "Legend") +
  theme_minimal() +
  theme(legend.position = "top")

print(p)


library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)

# Assume df has: date, Contract, Price
df_wide <- df %>%
  tidyr::pivot_wider(names_from = Contract, values_from = Price) %>%
  arrange(date) %>%
  mutate(min_price = pmin(WTI, Brent, na.rm = TRUE),
         max_price = pmax(WTI, Brent, na.rm = TRUE))

# Filter to only Severe Storms + Tropical Cyclones
disasters_filtered <- disasters %>%
  filter(Type %in% c("Severe Storm", "Tropical Cyclone")) %>%
  mutate(Begin.Date = as.Date(Begin.Date),
         End.Date   = as.Date(End.Date))

# Expand disasters into daily rows for shading
disaster_expanded <- disasters_filtered %>%
  rowwise() %>%
  do(data.frame(date = seq(.$Begin.Date, .$End.Date, by = "day"),
                Type = .$Type,
                Event = .$Event)) %>%
  ungroup()

# Join with df_wide so we know Brent/WTI values on those dates
highlight_df <- df_wide %>%
  left_join(disaster_expanded, by = "date") %>%
  filter(!is.na(Type))

# ---- Plot ----
p <- ggplot() +
  # Shaded ribbons ONLY during disaster spans
  geom_ribbon(data = highlight_df,
              aes(x = date, ymin = min_price, ymax = max_price, fill = Type),
              alpha = 0.25) +
  
  # WTI & Brent lines
  geom_line(data = df, aes(x = date, y = Price, color = Contract), size = 1) +
  
  # Start date dots
  geom_point(data = df %>% filter(date %in% disasters_filtered$Begin.Date),
             aes(x = date, y = Price, color = Contract),
             size = 3, shape = 21, fill = "red") +
  
  # End date dots
  geom_point(data = df %>% filter(date %in% disasters_filtered$End.Date),
             aes(x = date, y = Price, color = Contract),
             size = 3, shape = 21, fill = "white", stroke = 1.2) +
  
  scale_color_manual(values = c(WTI = "steelblue", Brent = "darkorange")) +
  scale_fill_manual(values = c(
    "Severe Storm"     = "#9ECAE1",   # light blue
    "Tropical Cyclone" = "#FDAE6B"    # orange-pink
  )) +
  
  labs(title = "WTI vs Brent Futures with Texas Tropical Cyclones & Severe Storms (2024)",
       subtitle = "Shaded spans mark disaster periods, bounded between Brent & WTI prices.",
       x = "Date", y = "Price (USD)",
       color = "Contract", fill = "Disaster Type") +
  theme_minimal() +
  theme(legend.position = "top")

print(p)




