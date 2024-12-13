function(input, output, session) {
  
  winterMinArea <- reactive({
    calc_min_area(input$flow_winter)
  })
  
  summerMinArea <- reactive({
    calc_min_area(input$flow_summer)
  })
  
  fallMinArea <- reactive({
    calc_min_area(input$flow_fall)
  })
  
  winterLoadArea <- reactive({
    calc_load_area(input$flow_winter, input$N_winter, rates[["winter"]])
  })
  
  summerLoadArea <- reactive({
    calc_load_area(input$flow_summer, input$N_summer, rates[["summer"]])
  })
  
  fallLoadArea <- reactive({
    calc_load_area(input$flow_fall, input$N_fall, rates[["fall"]])
  })
  
  observe({
    max_summer = floor(summerLoadArea()/summerMinArea())
    if (max_summer > 5) max_summer = 5
    updateSliderInput(session, "rt_summer", max = max_summer)
    
    max_fall = floor(fallLoadArea()/fallMinArea())
    if (max_fall > 5) max_fall = 5
    updateSliderInput(session, "rt_fall", max = max_fall)
    
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
  
  fallLoadAreaAdj <- reactive({
    calc_load_area(input$flow_fall, input$N_fall, rates[["fall"]])/input$rt_fall
  })
  
  observe({
    min_winter = round(winterMinArea()/winterLoadAreaAdj(), 2)
    if (min_winter > 1) min_winter = 1
    updateSliderInput(session, "eff_winter", min = min_winter)
    
    min_summer = round(summerMinArea()/summerLoadAreaAdj(), 2)
    if (min_summer > 1) min_summer = 1
    updateSliderInput(session, "eff_summer", min = min_summer)
    
    min_fall = round(fallMinArea()/fallLoadAreaAdj(), 2)
    if (min_fall > 1) min_fall = 1
    updateSliderInput(session, "eff_fall", min = min_fall)
  })
  
  winterArea <- reactive({
    winterLoadAreaAdj() * input$eff_winter
  })
  
  summerArea <- reactive({
    summerLoadAreaAdj() * input$eff_summer
  })
  
  fallArea <- reactive({
    fallLoadAreaAdj() * input$eff_fall
  })
  
  winterSide <- reactive({
    calc_side(winterArea())
  })
  
  summerSide <- reactive({
    calc_side(summerArea())
  })
  
  fallSide <- reactive({
    calc_side(fallArea())
  })
  
  output$plot <- renderPlotly({
    tmp = data.frame(Season = names(season_colors),
                     Area = round(c(winterArea(), fallArea(), summerArea()))) |> 
      mutate(Season = factor(Season, levels = rev(names(season_colors))))
    
    p = ggplot(tmp) +
      geom_col(aes(x = Season, y = Area, fill = Season, 
                   text = paste0("Season: ", Season, "<br>", "Area: ", Area, " (ac)"))) +
      labs(y = "Area (ac)") +
      scale_fill_manual(values = season_colors) +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p, tooltip = "text")
  })
  
  polygons <- reactive({
    poly_sfc = st_sfc(list(st_polygon(x = list(calc_coords(winterSide()))),
                           st_polygon(x = list(calc_coords(fallSide()))),
                           st_polygon(x = list(calc_coords(summerSide())))), 
                      crs = 4326)
    
    data.frame(season = names(season_colors),
               # these need to be in the same order as the season colors and the poly_sfc
               acres = c(round(winterArea()), 
                         round(fallArea()),
                         round(summerArea())),
               season_color = unname(season_colors)) |> 
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
      addLegend("topleft", 
                colors = rev(unname(season_colors)), 
                labels = rev(names(season_colors)),
                title = "Season")
  })
  
  proxy <- leafletProxy("map")
  
  observe({
    proxy |> 
      clearShapes() |> 
      addPolygons(data = polygons(), 
                  color = ~season_color,
                  opacity = 0.7, 
                  fillOpacity = 0.01)
  })
  
}
