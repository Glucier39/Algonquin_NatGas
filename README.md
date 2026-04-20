# Estimating Consumer Savings from Pipeline Access in New England

**Author:** Geddy Lucier
**Institution:** University of Pennsylvania, Department of Earth and Environmental Science
**Thesis Advisor:** Dr. Jane Dmochowski
**Degree:** B.A. in Environmental Studies
**Completion:** May 2026

📄 **Full thesis:** [Senior_Thesis_1.pdf](Senior_Thesis_1.pdf)

---

## Abstract

Despite sitting less than 500 miles from the Marcellus Shale, the most productive shale basin in the United States, Boston consistently pays among the highest natural gas prices in the contiguous U.S. This premium reflects not upstream supply costs, but a structural pipeline disconnect driven by repeated expansion failures and dependence on expensive LNG imports during peak demand. Using Chicago Citygate as a counterfactual hub, this study estimates Boston's average potential savings over 2020–2025. Utilizing a multivariate linear regression and controlling for comparable supply and demand conditions, we find Boston could save approximately **$3.09/MMBtu** with sufficient pipeline infrastructure. Extensions find that regional renewable growth has not meaningfully reduced natural gas demand, and that consumer savings from unconstrained pipeline access would substantially exceed projected carbon costs, raising important questions about the net welfare effects of New England's current permitting regime.

---

## Background

The Marcellus Shale is a major Devonian-age natural-gas formation across Pennsylvania, West Virginia, Ohio, and New York. Enabled by horizontal drilling and hydraulic fracturing, it has become one of the most productive and cost-advantaged natural-gas regions in the United States. Despite this upstream abundance, downstream consumers in New England remain structurally disconnected from low-cost Marcellus gas due to interstate pipeline limitations and state-level environmental permitting regimes.

### Regional Constraints

- **Clean Water Act §401 Permit Denials (New York State DEC):** Constitution Pipeline, Northeast Energy Direct (NED), Access Northeast, and Northern Access Pipeline were all denied required water-quality certifications, preventing Marcellus gas from physically reaching New England.
- **Limited Interconnections to the National Pipeline Grid:** New England has few entry points (Tennessee Gas, Algonquin, Iroquois), while Chicago has multiple high-capacity connections.

### State-Level Constraints (Massachusetts)

- **ENGIE Gas & LNG v. Department of Public Utilities (2016):** Prohibits electric ratepayers from funding new pipeline capacity, eliminating the primary financing mechanism for major gas infrastructure projects.
- **Global Warming Solutions Act (GWSA, 2008; updated 2021):** Mandates steep emissions reductions and net-zero by 2050, causing regulators to treat long-lived gas infrastructure as inconsistent with state climate targets.
- **DPU "Future of Gas" Proceeding (2020–2024):** Concluded that Massachusetts gas utilities must transition away from fossil gas, creating regulatory uncertainty and discouraging new pipeline development.
- **Clean Energy and Climate Plan (2025/2030):** Further limits expansion of gas-related infrastructure by prioritizing electrification and emissions reductions.

---

## Research Objective

This thesis empirically quantifies the **environmental policy price premium** faced by Boston relative to an unconstrained upstream counterfactual. The central research question is: under comparable market conditions, how much could Boston save with adequate pipeline infrastructure?

---

## Data

The analysis draws on daily observations spanning December 2019 through December 2025, merging price, weather, electricity demand, and renewable generation data across Boston and Chicago.

| Variable | Source | Frequency | Notes |
|---|---|---|---|
| Natural gas spot prices (Algonquin Citygate, Chicago Citygate) | Bloomberg Terminal | Daily | Business-day pipeline nomination calendar |
| Temperature (HDD, CDD) | Iowa Environmental Mesonet ASOS via `riem` R package | Daily | Stations: BED (Boston-area), KORD (Chicago) |
| Regional electricity demand | EIA API v2 (Form EIA-930) | Daily | Sub-BA codes: 4008 (ISO-NE), CE (ComEd/MISO) |
| Renewable generation by fuel type | EIA API v2 daily fuel-type endpoint | Daily | RTOs: ISNE, PJM (wind + solar + hydro + battery) |
| RGGI CO₂ allowance prices | RGGI Q3 2025 Secondary Market Report (Potomac Economics) | Quarterly | Carbon cost benchmark |

A structural break in the Algonquin price series is documented: following ICE's 2016 introduction of the Non-G Citygates location, trading activity migrated away from the original AGT Citygates index, leaving shoulder-season gaps in the Bloomberg series. Because missing observations cluster in low-constraint periods, the estimated premium represents a conservative lower bound.

---

## Methodology

The central specification is a pooled-panel OLS regression:

$$P_{it} = \beta_0 + \beta_1 \text{Chicago}_i + \beta_2 \text{HDD}_{it} + \beta_3 \text{CDD}_{it} + \beta_4 \text{Elec}_{it} + \beta_5 \text{Renew}_{it} + \varepsilon_{it}$$

where $P_{it}$ is the daily spot price at hub $i$ on day $t$, and $\text{Chicago}_i$ is a binary indicator. The coefficient $\beta_1$ captures the average price difference between hubs after conditioning on weather-driven demand, regional electricity load, and renewable generation share, and is interpreted as the infrastructure premium borne by Boston consumers.

A secondary binomial logistic specification models the probability that the Algonquin hub generates a daily price index, used to test whether renewable penetration has begun to structurally suppress natural gas market activity.

Key assumptions and limitations — including comparability of Chicago as a counterfactual, omitted variable bias, serial correlation, structural breaks during 2020–2022, and the linearity assumption of OLS — are discussed in full in Section 4.5 of the thesis.

---

## Results

### Primary Regression

| Variable | Coefficient | Std. Error |
|---|---|---|
| **Chicago (vs. Boston)** | **−3.086*** | (0.879) |
| Heating Degree Days | 0.038*** | (0.007) |
| Electricity Demand (MW) | 0.00001** | (0.00000) |
| Cooling Degree Days | 0.009 | (0.035) |
| Renewable Share (%) | −0.051** | (0.023) |
| Constant | 3.553*** | (0.373) |

*N = 2,223; R² = 0.048; Sample: Dec 2019 – Dec 2025. Standard errors in parentheses. \*\*\* p<0.01, \*\* p<0.05.*

**Central finding:** After controlling for weather, electricity demand, and renewable generation, Chicago Citygate prices are on average **$3.09/MMBtu lower** than Algonquin Citygate prices. At Boston's estimated per-capita consumption of 63 MMBtu annually, this implies roughly **$194 in annual welfare losses per person**.

### Extension 1 — Renewable Suppression of Gas Demand

A logistic regression on Algonquin trading-day formation finds renewable generation has a statistically significant but economically modest effect on market activity at current penetration levels (ISO-NE renewable share averages 12%, ranging 3.76–29.27%). The pipeline premium is unlikely to self-correct through renewable growth in the near term.

### Extension 2 — Welfare vs. Carbon Cost

Using the RGGI Q3 2025 clearing price of **$22.25/short ton CO₂** as a market-based carbon benchmark:

- Per-person annual consumer savings from unconstrained pipeline access: **~$195**
- Per-person annual carbon cost of corresponding gas consumption: **~$74**
- **Net welfare benefit: ~$121/person/year**
- Break-even RGGI price: **$58.46/ton** — more than double any historically observed RGGI clearing price.

At any carbon price RGGI has actually traded at, consumer welfare losses from the pipeline premium substantially exceed the carbon cost of the additional gas that would be consumed.

---

## Repository Structure

```
Algonquin_NatGas/
├── Senior_Thesis_1.pdf              # Full thesis document
├── README.md                        # This file
│
├── 01_Cleaning.Rmd                  # Price data cleaning pipeline
├── 02_RegressionData.Rmd            # Regression pipeline (weather, elec, prices)
├── Prices_EDA.Rmd                   # Exploratory analysis of hub prices
├── PricingData.Rmd                  # EIA pricing data pulls
├── Pipeline_Mapping.Rmd             # Spatial pipeline maps (Boston vs. Chicago)
│
├── eia_dataload.R                   # EIA API loader (electricity demand)
├── API.ipynb                        # API testing (EIA, Yahoo, Bloomberg)
├── gridstatus_test.ipynb            # gridstatus.io testing
├── disaster_graphing.ipynb          # Intraday price analysis during weather events
│
├── gas_prices.csv                   # Raw Bloomberg price export
├── preliminary_results.html         # Stargazer regression output
└── data/                            # (local) Processed datasets + geospatial inputs
```

### Reproducibility Notes

- **R dependencies:** `tidyverse`, `lubridate`, `riem`, `stargazer`, `sf`, `cowplot`, `maps`, `ggspatial`
- **Python dependencies:** `requests`, `pandas`, `alpha_vantage`, `yfinance`
- **API keys required:** EIA API key (set via `.Renviron` as `EIA_API_KEY`); Bloomberg Terminal access required for raw price data
- Run order: `01_Cleaning.Rmd` → `eia_dataload.R` → `02_RegressionData.Rmd`

---

## Key References

- Frei, A. & Furchtgott-Roth, D. (2025). *Hydraulic Fracturing and Economic Outcomes: A Study of Marcellus Shale Counties.* Heritage Foundation SR317.
- ISO New England et al. (2016). *Proposed Tariff Revisions to Change the Source of Natural Gas Prices.* FERC Docket ER17-319.
- Mu, X. (2007). "Weather, Storage, and Natural Gas Price Dynamics." *Energy Economics* 29(1): 46–63.
- Potomac Economics (2025). *Report on the Secondary Market for RGGI CO₂ Allowances: Q3 2025.*
- U.S. Bureau of Labor Statistics (2024). *Average Energy Prices, Boston-Cambridge-Newton.*
- U.S. Energy Information Administration (2022, 2023, 2024). Various reports on Appalachian production, pricing hubs, and pipeline infrastructure.
- Wasser, M. (2025). "Why a New Gas Pipeline into New England May (or May Not) Lower Energy Bills." *WBUR News.*

Full bibliography available in [Senior_Thesis_1.pdf](Senior_Thesis_1.pdf).

---

## Citation

If referencing this work, please cite:

> Lucier, G. (2026). *500 Miles from Cheap Gas: Estimating Consumer Savings from Pipeline Access in New England.* B.A. Thesis, University of Pennsylvania, Department of Earth and Environmental Science.
