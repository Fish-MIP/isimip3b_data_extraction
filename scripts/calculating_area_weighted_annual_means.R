################################################################################
# Title: Useful functions
# Author: Denisse Fierro Arcos
# Date last updated: "2026-09-21"
# This notebook contains a collection of functions developed to extract marine
# ecosystem model (MEM) outputs running FishMIP3a simulations using a mask 
# containing spatial boundaries of a region of interest
################################################################################


# Loading libraries -------------------------------------------------------
library(terra)
library(sf)
library(dplyr)
library(stringr)
library(tidyr)
library(ncdf4)
library(rcdo)
cdo_use("system")


# Setting up --------------------------------------------------------------
base_out <- "/g/data/vf71/fishmip_inputs/ISIMIP3b"


# Calculating mean values within region of interest -----------------------
# Selecting region of interest
fishmip_reg <- read_sf(file.path(
  "/g/data/vf71/shared_resources/FishMIP_regional_models", 
  "FishMIP_regional_models.shp")) |> 
  filter(str_detect(region, "Eastern Scotian"))


# Location of area of grid cell files
area_fn <- list.files(
  "/g/data/vf71/shared_resources/grid_cell_vars_ESMs/isimip3b", 
  pattern = "gfdl", full.names = TRUE)

out_dir <- file.path(base_out, "regional", "download_data", 
                     "annual_area_weighted")
if(!dir.exists(out_dir)){
  dir.create(out_dir)
}

crop_var(area_fn, fishmip_reg, folder_out = out_dir)

area_path_list <- list.files(out_dir, pattern = "areacello", recursive = TRUE,
                             full.names = TRUE)

var_int_list <- list.files(
  file.path(base_out, "regional", "download_data", "global_annual_corrected"),
  pattern = "^gfdl", full.names = TRUE)

var_int_list |> 
  map(\(x) annual_calcs(x, area_path_list, fishmip_reg, out_dir))

