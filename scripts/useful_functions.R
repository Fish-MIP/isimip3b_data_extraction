################################################################################
# Title: Useful functions
# Author: Denisse Fierro Arcos
# Date last updated: "2026-09-21"
# This notebook contains a collection of functions developed to extract marine
# ecosystem model (MEM) inputs to run FishMIP3b simulations using a mask 
# containing spatial boundaries of a region of interest
################################################################################


# Loading libraries -------------------------------------------------------
library(terra)
library(sf)
library(ncdf4)
library(dplyr)
library(stringr)
library(tidyr)
library(data.table)

# Function to tidy up files produced by CDO - annual means
tidy_nc <- function(file_path, folder_out){
  base_fn <- basename(file_path)
  
  # Get variable name of interest
  if(str_detect(base_fn, "ssp")){
    varname <- str_extract(base_fn, "ssp\\d{3}_(.*)_60a", group = 1)
  }else if(str_detect(base_fn, "hist")){
    varname <- str_extract(base_fn, "historical_(.*)_60a", group = 1)
  }
  start_year <- str_extract(base_fn, "-year_(\\d{4})_", group = 1)
  end_year <- str_extract(base_fn, "_(\\d{4}).nc", group = 1)
  
  # Load netCDF file
  da <- nc_open(file_path)
  var_int <- ncvar_get(da, varname)
  yeardim <- ncdim_def("year", "years", as.integer(start_year:end_year))
  
  # Get general metadata
  global_atts <- ncatt_get(da, 0)
  
  if(str_subset(names(da$dim), "lev") > 0){
    depth_name <- str_subset(names(da$dim), "lev")
    if(depth_name != "lev"){
      da$dim[[depth_name]]$name <- "lev"
    }
    
    # Update metadata for variable of interest
    var_update <- ncvar_def(varname, units = da$var[[varname]]$units,
                            list(da$dim$lon, da$dim$lat, da$dim[[depth_name]], 
                                 yeardim), 
                            missval = da$var[[varname]]$missval, 
                            longname = da$var[[varname]]$longname)
  }else{
    # Update metadata for variable of interest
    var_update <- ncvar_def(varname, units = da$var[[varname]]$units,
                            list(da$dim$lon, da$dim$lat, yeardim), 
                            missval = da$var[[varname]]$missval, 
                            longname = da$var[[varname]]$longname)
  }
  nc_close(da)
  
  #Create new file
  da_out <- nc_create(file.path(folder_out, base_fn), list(var_update))
  
  #Assign metadata
  for(i in 1:length(global_atts)){
    ncatt_put(da_out, 0, names(global_atts[i]), global_atts[[i]])
  }
  
  ncvar_put(da_out, varname, var_int)
  nc_close(da_out)
}


# Cropping variables of interest using shapefile
crop_var <- function(var_int_path, mask_shp, folder_out = NULL){
  var_nc <- rast(var_int_path)
  reg_name <- unique(mask_shp$region)
  var_cropped <- crop(var_nc, mask_shp, mask = TRUE, touches = TRUE)
  
  if(is.null(folder_out)){
    return(var_cropped)
  }else{
    tidy_reg <- str_replace_all(str_to_lower(reg_name), " ", "-")
    out_path <- file.path(folder_out, tidy_reg)
    if(!dir.exists(out_path)){
      dir.create(out_path)
    }
    fout <- file.path(
      out_path,
      basename(var_int_path) |> 
        str_replace("_global_", str_c("_", tidy_reg, "_")))
    
    writeCDF(var_cropped, fout, varname = varnames(var_nc), 
             longname = longnames(var_nc), unit = units(var_nc), 
             overwrite = TRUE)
  }
}


# Calculating yearly area-weighted means for biomass variables
annual_calcs <- function(var_int_path, area_path_list, mask_shp, folder_out){
  
  reg_name <- str_replace_all(str_to_lower(unique(mask_shp$region)), " ", "-")
  
  var_fn <- str_replace(
    str_replace(basename(var_int_path), ".nc", ".csv"),
    "_global_", str_c("_", reg_name, "_"))
  
  fout <- file.path(folder_out, reg_name)
  if(!dir.exists(fout)){
    dir.create(fout)
  }
  
  fout <- file.path(fout, var_fn)
  
  var_nc <- crop_var(var_int_path, mask_shp)
  
  mask <- rast(area_path_list)
  tot_area <- global(mask, "sum", na.rm = TRUE)$sum
  
  if(str_detect(names(var_nc)[1], "lev")){
    tcalcs <- data.frame(
      year = as.integer(str_extract(names(var_nc), "year=(\\d{4})", group = 1)),
      depth = as.numeric(str_extract(names(var_nc), "lev=(.*)_", group = 1)),
      vals = global(var_nc, "mean", na.rm = TRUE, weights = mask)$weighted_mean)
  }else{
    tcalcs <- data.frame(
      year = as.integer(str_extract(names(var_nc), "year=(\\d{4})", group = 1)),
      vals = global(var_nc, "mean", na.rm = TRUE, weights = mask)$weighted_mean) 
  }
  
  var_units <- unique(units(var_nc))
  
  tcalcs <- tcalcs |> 
    mutate(region = unique(mask_shp$region), .before = year) |> 
    mutate(res = str_extract(var_fn, "_(\\d{2}arcmin)_", group = 1),
           esm_name = str_extract(var_fn, "(.*)_r\\d{1}", group = 1),
           scenario = str_extract(var_fn, "ssp\\d{3}"),
           short_name = varnames(var_nc),
           long_name = longnames(var_nc),
           units = var_units,
           total_area = tot_area,
           area_units = units(mask))
  
  fwrite(tcalcs, fout, na = NA)
}