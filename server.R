function(input, output, session) {
  
  winterMinArea <- reactive({
    calc_min_area(input$flow_winter)
  })
  
  summerMinArea <- reactive({
    calc_min_area(input$flow_summer)
  })
  
  fallspringMinArea <- reactive({
    calc_min_area(input$flow_fallspring)
  })
  
  winterLoadArea <- reactive({
    calc_load_area(input$flow_winter, input$N_winter, rates[["winter"]])
  })
  
  summerLoadArea <- reactive({
    calc_load_area(input$flow_summer, input$N_summer, rates[["summer"]])
  })
  
  fallspringLoadArea <- reactive({
    calc_load_area(input$flow_fallspring, input$N_fallspring, rates[["fallspring"]])
  })
  
  observe({
    max_summer = floor(summerLoadArea()/summerMinArea())
    if (max_summer > 5) max_summer = 5
    updateSliderInput(session, "rt_summer", max = max_summer)
    
    max_fallspring = floor(fallspringLoadArea()/fallspringMinArea())
    if (max_fallspring > 5) max_fallspring = 5
    updateSliderInput(session, "rt_fallspring", max = max_fallspring)
    
    max_winter = floor(winterLoadArea()/winterMinArea())
    if (max_winter > 5) max_winter = 5
    updateSliderInput(session, "rt_winter", max = max_winter)
  })
  
  winterLoadAreaAdj <- reactive({
    calc_load_area(input$flow_winter, input$N_winter, rates[["winter"]])/input$rt_winter
  })
  
  summerLoadAreaAdj <- reactive({
    calc_load_area(input$flow_summer, input$N_summer, rates[["summer"]])/input$rt_summer
  })
  
  fallspringLoadAreaAdj <- reactive({
    calc_load_area(input$flow_fallspring, input$N_fallspring, rates[["fallspring"]])/input$rt_fallspring
  })
  
  observe({
    min_winter = round(winterMinArea()/winterLoadAreaAdj(), 2)
    if (min_winter > 1) min_winter = 1
    updateSliderInput(session, "eff_winter", min = min_winter)
    
    min_summer = round(summerMinArea()/summerLoadAreaAdj(), 2)
    if (min_summer > 1) min_summer = 1
    updateSliderInput(session, "eff_summer", min = min_summer)
    
    min_fallspring = round(fallspringMinArea()/fallspringLoadAreaAdj(), 2)
    if (min_fallspring > 1) min_fallspring = 1
    updateSliderInput(session, "eff_fallspring", min = min_fallspring)
  })
  
  winterArea <- reactive({
    winterLoadAreaAdj() * input$eff_winter
  })
  
  summerArea <- reactive({
    summerLoadAreaAdj() * input$eff_summer
  })
  
  fallspringArea <- reactive({
    fallspringLoadAreaAdj() * input$eff_fallspring
  })
  
  winterSide <- reactive({
    calc_side(winterArea())
  })
  
  summerSide <- reactive({
    calc_side(summerArea())
  })
  
  fallspringSide <- reactive({
    calc_side(fallspringArea())
  })
  
  output$winterText <- renderText({
    paste("Area: ", round(winterArea()), " (ac)")
  })
  
  output$summerText <- renderText({
    paste("Area: ", round(summerArea()), " (ac)")
  })
  
  output$fallspringText <- renderText({
    paste("Area: ", round(fallspringArea()), " (ac)")
  })
  
  polygons <- reactive({
    poly_sfc = st_sfc(list(st_polygon(x = list(calc_coords(winterSide()))),
                           st_polygon(x = list(calc_coords(fallspringSide()))),
                           st_polygon(x = list(calc_coords(summerSide())))), 
                      crs = 4326)
    
    data.frame(season = c("Winter", "Fall/Spring", "Summer"),
               acres = c(round(winterArea()), 
                         round(fallspringArea()),
                         round(summerArea())),
               season_color = c("#7570b3", "#1b9e77", "#d95f02")) |> 
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
      addLegend("topleft", colors = c("#d95f02", "#1b9e77", "#7570b3"), labels = c("Summer", "Fall/Spring", "Winter"),
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
