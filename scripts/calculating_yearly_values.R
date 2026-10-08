################################################################################
# Title: Calculating yearly (gridded) values
# Author: Denisse Fierro Arcos
# Date last updated: "2026-09-21"
# Calculating annual gridded means for variables of interest needed to run 
# FishMIP3a simulations 
################################################################################


# Loading libraries -------------------------------------------------------
library(stringr)
library(purrr)
library(rcdo)
cdo_use("system")
source(
  "/g/data/vf71/la6889/isimip3b_data_extraction/scripts/useful_functions.R")

# Setting up --------------------------------------------------------------
base_out <- "/g/data/vf71/fishmip_inputs/ISIMIP3b/global/download_data"

path_out <- file.path(base_out, "global_annual")
if(!dir.exists(path_out)){
  dir.create(path_out)
}

# Location of data to be processed
input_dir <- "/g/data/vf71/fishmip_inputs/ISIMIP3b/global"

input_files <- list.files(input_dir, 
                          "thetao_|phydiat_|phydiaz_|phypico_|zmeso_|zmicro_", 
                          recursive = TRUE, full.names = TRUE) |> 
  str_subset("download_data", negate = T) |> 
  str_subset("60arcmin")


# Calculating global yearly means -----------------------------------------
input_files |> 
  lapply(function(x) 
    cdo_yearmean(x, ofile = file.path(
      path_out, str_replace(basename(x), "_monthly_", "_mean-year_"))) |> 
      cdo_execute())


# Tidying up outputs above ------------------------------------------------
nc_files <- list.files(path_out, full.names = TRUE)

folder_out <- file.path(base_out, "global_annual_corrected")
if(!dir.exists(folder_out)){
  dir.create(folder_out)
}

# Applying function to all files
nc_files |> 
  map(\(x) tidy_nc(x, folder_out))


