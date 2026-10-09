################################################################################
# Title: Useful functions
# Author: Denisse Fierro Arcos
# Date last updated: "2026-09-21"
# This notebook calculates area-weighted annual inputs to run FishMIP3b 
# simulations at a regional scale
################################################################################


# Loading libraries -------------------------------------------------------
library(terra)
library(sf)
library(dplyr)
library(stringr)
library(purrr)
source(
  "/g/data/vf71/la6889/isimip3b_data_extraction/scripts/useful_functions.R")

# Setting up --------------------------------------------------------------
base_out <- "/g/data/vf71/fishmip_inputs/ISIMIP3b"
reg_int_name <- "Prydz Bay"

# Calculating mean values within region of interest -----------------------
# Selecting region of interest
fishmip_reg <- read_sf(file.path(
  "/g/data/vf71/shared_resources/FishMIP_regional_models", 
  "FishMIP_regional_models.shp")) |> 
  filter(str_detect(region, reg_int_name))


# Location of area of grid cell files
area_fn <- list.files(
  "/g/data/vf71/shared_resources/grid_cell_vars_ESMs/isimip3b", 
  full.names = TRUE)

out_dir <- file.path(
  base_out, "regional", "download_data", "annual_area_weighted")
if(!dir.exists(out_dir)){
  dir.create(out_dir)
}

area_fn |> 
  map(\(x) crop_var(x, fishmip_reg, folder_out = out_dir))

area_path_list <- list.files(
  out_dir, 
  pattern = str_c("areacello_.*", 
                  str_replace_all(str_to_lower(reg_int_name), " ", "-")), 
  recursive = TRUE, full.names = TRUE)

var_int_list <- list.files(
  file.path(base_out, "global", "download_data", "global_annual_corrected"),
  full.names = TRUE)

var_int_list |> 
  str_subset("gfdl") |> 
  map(\(x) annual_calcs(x, str_subset(area_path_list, "gfdl"), fishmip_reg, 
                        out_dir))

var_int_list |> 
  str_subset("ipsl") |> 
  map(\(x) annual_calcs(x, str_subset(area_path_list, "ipsl"), fishmip_reg, 
                        out_dir))
