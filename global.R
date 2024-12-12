library(shiny)
library(shinyWidgets)
library(bslib)
library(leaflet)
library(dplyr)
library(sf)
library(geosphere)

# assumption in calculations below is that all calculations are for one day;
#   day drops out of any units

# denitrification rates; units: mg/m2
rates = c("winter" = 59.5,
          "fallspring" = 321,
          "summer" = 824.7)

convert_flow <- function(flow){
  # convert MGD to L
  flow * 3.78541178 * 1e6  
}

calc_min_area <- function(flow){
  # convert L to m3
  m3 = convert_flow(flow)/1000
  # find area required to spread water to a depth of 0.2 m
  m2 = m3/0.2
  # convert m2 to acres
  m2/4046.86
}

calc_N_load <- function(flow, N){
  # N units: mg/L
  # return results in mg
  N * convert_flow(flow)
}

calc_load_area <- function(flow, N, rate){
  # assumes 100% efficiency is expected/needed
  load = calc_N_load(flow, N)
  # area in m2
  m2 = load/rate
  # in acres
  m2/4046.86
}

calc_side <- function(area){
  # in meters
  sqrt(area * 4046.86)
}

calc_coords <- function(dist){
  ne_pt = matrix(c(-121.805556, 38.241667), nrow = 1, ncol = 2)
  colnames(ne_pt) = c("lon", "lat")
  nw_pt = destPoint(p = ne_pt, b = 270, d = dist)
  sw_pt = destPoint(p = nw_pt, b = 180, d = dist)
  se_pt = destPoint(p = sw_pt, b = 90, d = dist)
  do.call(rbind, list(ne_pt, nw_pt, sw_pt, se_pt, ne_pt))
}


