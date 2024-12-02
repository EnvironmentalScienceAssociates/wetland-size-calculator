library(shiny)
library(shinyWidgets)
library(bslib)
library(leaflet)
library(dplyr)
library(sf)
library(geosphere)

calc_area <- function(flow, N, rt, eff, season = c("winter", "summer")){
  x = if (season == "summer") 824.7 else 59.5
  # in acres
  (((((flow * 3785.41178*1000) * N)/x)/4046.86)/rt) * eff
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
