#### CDPH BREAST CANCER RISK GRAPHICS  ####
## R script that reshapes model prediction score data for visualization
## Fall 2017
## Civis Analytics
## R version 3.4.2

## NOTE: Some variables have been changed to protect proprietary information.


## ----------------------------< Prepare Workspace >------------------------------------
rm(list=ls())

wd <- "/Users/YOU/Desktop/CDPH_breastcancer/" # replace this with your own directory
setwd(wd)

## required packages
packages = c("tidyverse",    # version 1.1.1
             "readr",        # version 1.1.1
             "civis",        # version 1.1.0  -- Civis Analytics package to connect to Civis API
             "rgdal",        # version 1.2-16
             "ggplot2",      # version 2.2.1
             "rgeos",        # version 0.3-26
             "maptools",     # version 0.9-2
             "broom",        # version 0.4.3
             "Hmisc"         # version 4.0-3
)

## function that loads required packages; if not installed, then installs package first
loadPackage <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

## loop through necessary packages and install/load
for(package in packages){
  loadPackage(package)
}

options(civis.default_db = "database",  # Civis Analytics default database
        scipen = 999,
        stringsAsFactors = FALSE)


## -------------------------< STEP 1: Load Data to Determine Tracts of Interest >-------------------------
## read in shape files
## these should be in your working directory in folders with the same names as specified below (i.e. "Boundaries - ...")
shape_tract <- readOGR(paste0(wd, "Boundaries - Census Tracts - 2010/"), layer = "geo_export_900f06ac-8b38-4953-a28d-8377fada8dc1")
shape_ca <- readOGR(paste0(wd, "Boundaries - Community Areas (current)/"), layer = "geo_export_fe7fb01b-03be-45a2-92ca-b4cb52220e88")


## CSV that maps census tracts to the 77 Chicago Community Areas
ca_bridge <- read_csv("tract_to_ca.csv") %>%
  dplyr::rename("id" = TRACT, "ca" = CHGOCA) %>%
  mutate(id = paste0("17031", as.character(id))) %>%
  select(id, ca)

## grab tracts from shape file
chicago_tracts <- data.frame(tract = tract@data$geoid10)

## merge with ca-tract bridge; subset to tracts of interest
ca_tract_bridge <- full_join(chicago_tracts, ca_bridge, by = c("tract" = "id")) %>%
  filter(!is.na(tract))

## write to Civis platform to subset scoring tables
# write_civis(ca_tract_bridge,
#             tablename = "ca_tract_bridge",
#             if_exists = "drop")


## -------------------------< STEP 2: Calculate Weighted Averages for Each Tract Population >-------------------------

## read in data on female population of different Census tracts to calculate weighted averages
## data read in from Civis platform using API
# tract_pop_raw <- read_civis(sql(
#   "SELECT data.tract, 
#   data.population,
#   bridge.ca
#   FROM
#   (
#   SELECT 
#   LEFT(census_block, 11) AS tract,
#   COUNT(*) AS population
#   FROM modeling_data
#   WHERE gender = 'Female'
#   GROUP BY 1
#   ) AS data
#   LEFT JOIN
#   ca_tract_bridge AS bridge
#   ON data.tract = bridge.tract
#   WHERE bridge.tract IS NOT NULL"))

## calculate weighted averages for each Community Area
# tract_pop <- tract_pop_raw %>%
#   group_by(ca) %>%                      # group by community area
#   mutate(ca_pop = sum(population)) %>%  # calculate total number of women in a community area
#   ungroup() %>%
#   mutate(tract_pop_proport = population / ca_pop,  # calculate weights for each tract (# ppl in tract / # ppl in associated community area)
#          tract = as.character(tract))


## write to a CSV
# write_csv(tract_pop, "weight_avg_tract.csv")

## read in weighted averages for Census tract to Community Area
tract_pop <- read_csv(paste0(wd, "weight_avg_tract.csv"), col_types = cols(tract = "c"))


## -------------------------< Munge Scores Output from Geographic-Level Models >-------------------------
## table of model prediction scores for insurance status -- by tract
uninsured_tract <- read_civis(x = "uninsured2017_aggscores") %>%  # read in geographic-level model scores from Civis database through API
  mutate(census_tract = as.character(census_tract))

## table of model prediction scores for insurance status -- by Community Area
uninsured_ca <- uninsured_tract %>%
  left_join(tract_pop[,c("tract", "tract_pop_proport", "ca")], by = c("census_tract" = "tract")) %>%
  mutate(weighted_val = cdph_uninsured * tract_pop_proport) %>%
  group_by(ca) %>%
  dplyr::summarize(weighted_avg = sum(weighted_val))  # calculate proportion uninsured for each community area by taking weighted value of tract proportions


## table of model prediction scores for breast cancer risk status -- by tract
bcrisk_tract <- read_civis(x = "health_care.bcrisk_aggscores") %>%  # retrieved from Civis database through API
  mutate(census_tract = as.character(census_tract))

## table of model prediction scores for breast cancer risk status -- by Community Area
bcrisk_ca <- bcrisk_tract %>%
  left_join(tract_pop[,c("tract", "tract_pop_proport", "ca")], by = c("census_tract" = "tract")) %>%
  mutate(weighted_val = bc_risk_2cat * tract_pop_proport) %>%
  group_by(ca) %>%
  dplyr::summarize(weighted_avg = sum(weighted_val))  # calculate proportion uninsured for each community area by taking weighted value of tract proportions


## merge tract-level data
all_df_tract <- select(uninsured_tract, c("tract" = census_tract, "uninsured2017" = cdph_uninsured)) %>%
  left_join(select(bcrisk_tract, c("tract" = census_tract, "bc_risk" = bc_risk_2cat))) %>%
  group_by(tract) %>%
  dplyr::summarise(avgp_bcrisk = bc_risk*100,
                   avgp_uninsured = uninsured2017*100,
                   avgp_both = (bc_risk*uninsured2017)*100,                                      # probability of A and B = P(A)*P(B)
                   avgp_either = ((bc_risk + uninsured2017) - (bc_risk*uninsured2017))*100) %>%  # probability of A or B = P(A) + P(B) - (P(A)*P(B))
  ungroup()


## merge Community Area-level data
all_df_ca <- select(uninsured_ca, c(ca, "uninsured2017" = weighted_avg)) %>%
  left_join(select(bcrisk_ca, c(ca, "bc_risk" = weighted_avg))) %>%
  group_by(ca) %>%
  dplyr::summarise(avgp_bcrisk = bc_risk*100,
                   avgp_uninsured = uninsured2017*100,
                   avgp_both = (bc_risk*uninsured2017)*100,                                      # probability of A and B = P(A)*P(B)
                   avgp_either = ((bc_risk + uninsured2017) - (bc_risk*uninsured2017))*100) %>%  # probability of A or B = P(A) + P(B) - (P(A)*P(B))
  ungroup() %>%
  mutate(ca = as.character(ca))  # change data type for joining to shape files



## -------------------------< Join to Shape Files for Plotting on Map >-------------------------
## merge shape files to reshaped and aggregated model prediction data
tract <- merge(shape_tract, all_df_tract, by.x = "geoid10", by.y = "tract")
ca <- merge(shape_ca, all_df_ca, by.x = "area_num_1", by.y = "ca")


## -------------------------< Rough Validation of Results >-------------------------

## we roughly validate the results of our breast cancer risk model by comparing our estimates to breast cancer incidence rates for Chicago community areas
## we expect that our estimates are higher than the incidence rates, as we are predicting risk of breast cancer rather than incidence
##we'll calculate the RMSE, as well as the correlation between our predictions and the true incidence rates


## load community area breast cancer incidence rate data
## this dataset is publicly available at: http://www.idph.state.il.us/cancer/statistics.htm 
community_area_bcincidence <- read_fwf(
  file = "CA0514.dat",
  skip = 0,
  fwf_widths(c(2, 1, 2, 1, 1, 1, 1, 1, 1)))
colnames(community_area_bcincidence) <- c("community_area", "diagnosis_yr", "cancer_site", "age_at_diag",
                  "sex", "race", "stage_of_disease_at_diag", "hispanic", "geocode")

## calculate breast cancer incidence for each community area
ca_calc <- community_area_bcincidence %>%
  filter(diagnosis_yr == 5 & sex == 2) %>%
  mutate(breast_cancer = ifelse(cancer_site == 3 | cancer_site == 7, 1, 0)) %>%
  group_by(community_area) %>%
  dplyr::summarise(bc_incidence = sum(breast_cancer)) %>% 
  ungroup() %>%
  arrange(community_area) %>%
  mutate(value = community_area)


## grab population of women for each community area
ca_pop <- tract_pop %>%
  select(ca, ca_pop) %>%
  distinct()

## validate models
validate_all_ca <- select(ca_calc, c("ca" = community_area, "bc_true" = bc_incidence)) %>%
  left_join(select(bcrisk_ca, c(ca, "model_proport" = weighted_avg)), by = "ca") %>%
  left_join(ca_pop, by = "ca") %>%
  mutate(model_incidence = model_proport*ca_pop,                   # calculate predicted number of women at-risk of breast cancer
         agg_model_diff = (model_incidence - bc_true),             # calculate difference between predicted number of at-risk women and true incidence
         rmse_agg = sqrt((mean(agg_model_diff, na.rm = TRUE))^2))  # calculate RMSE

cor(validate_all_ca$model_incidence, validate_all_ca$bc_true)  # check correlation between true and predicted values

## rough validation results
# RMSE: 2563.848
# correlation: 0.9418231


## -------------------------< Save Data for Shiny App >-------------------------
## remove all objects except for merged shape files for mapping
rm(list= ls()[!(ls() %in% c('ca','tract'))])  

## save image in working directory
save.image("cdph_mapping.Rdata")            


