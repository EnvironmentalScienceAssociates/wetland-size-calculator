page_navbar(
  title = "Wetland Size Calculator",
  nav_panel("App",
            div(class = "outer",
                tags$head(includeCSS("styles.css")),
                leafletOutput("map", width = "100%", height = "100%"),
                absolutePanel(
                  id = "controls", fixed = TRUE,
                  draggable = FALSE, top = 60, left = "auto", right = 20, bottom = "auto",
                  width = 350, height = "auto",
                  accordion(
                    accordion_panel(
                      "Summer",
                      sliderInput("flow_summer", "Flow (MGD)", min = 1, max = 100, value = 35),
                      sliderInput("N_summer", "Nitrogen (mg/L)", min = 1, max = 40, value = 10),
                      sliderInput("rt_summer", "Residence Time (days)", min = 1, max = 10, value = 1)
                      # sliderInput("eff_summer", "N Removal Efficiency", min = 0, max = 1, value = 1)
                    ),
                    accordion_panel(
                      "Winter",
                      sliderInput("flow_winter", "Flow (MGD)", min = 1, max = 100, value = 35),
                      sliderInput("N_winter", "Nitrogen (mg/L)", min = 1, max = 40, value = 10),
                      sliderInput("rt_winter", "Residence Time (days)", min = 1, max = 10, value = 1)
                      # sliderInput("eff_winter", "N Removal Efficiency", min = 0, max = 1, value = 1)
                    )
                  )
                )
            )
  )
)