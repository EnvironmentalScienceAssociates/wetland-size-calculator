function(input, output, session) {
  
  winterArea <- reactive({
    calc_area(input$flow_winter, input$N_winter, input$rt_winter, "winter")
  })
  
  summerArea <- reactive({
    calc_area(input$flow_summer, input$N_summer, input$rt_summer, "summer")
  })
  
  winterSide <- reactive({
    calc_side(winterArea())
  })
  
  summerSide <- reactive({
    calc_side(summerArea())
  })
  
  polygons <- reactive({
    poly_sfc = st_sfc(list(st_polygon(x = list(calc_coords(winterSide()))), 
                           st_polygon(x = list(calc_coords(summerSide())))), 
                      crs = 4326)
    
    data.frame(season = c("Winter", "Summer"),
               acres = c(round(winterArea()), round(summerArea())),
               season_color = c("#7570b3", "#d95f02")) |> 
      mutate(geometry = poly_sfc, 
             popup = paste("Area: ", acres, " (ac)")) |> 
      st_as_sf()
  })
  
  output$map = renderLeaflet({
    leaflet(options = leafletOptions(attributionControl = FALSE,
                                     zoomControl = TRUE)) |>
      setView(lng = -121.805, lat = 38.22, zoom = 12) |>
      addProviderTiles(providers$Esri.WorldTopoMap, 
                       # https://gis.stackexchange.com/questions/301710/r-leaflet-set-zoom-level-of-tiled-basemap-esri-world-imagery
                       options = providerTileOptions(noWrap = TRUE,
                                                     maxNativeZoom = 18,
                                                     maxZoom = 22)) |> 
      addLegend("topleft", colors = c("#d95f02", "#7570b3"), labels = c("Summer", "Winter"),
                title = "Season")
  })
  
  proxy <- leafletProxy("map")
  
  observe({
    proxy |> 
      clearShapes() |> 
      addPolygons(data = polygons(), 
                  color = ~season_color,
                  label = ~season,
                  popup = ~popup,
                  opacity = 0.7, 
                  fillOpacity = 0.01)
  })
  
}
