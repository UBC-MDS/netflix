library(shiny)
library(ggplot2)
library(dplyr)
library(plotly)
library(leaflet)
library(geosphere)
library(leaflet.extras)
library(sf)
library(shinydashboard)
library(shinycssloaders)

weather <- read.csv("data/processed/weather_pro.csv")
cities <- read.csv("data/processed/cities.csv")

# Change numeric month from number to name only for bar plots
weather_bar <- weather
weather_bar$month <- month.name[weather_bar$month]

# Define UI
ui <- dashboardPage(
  
  dashboardHeader(title = "Weather Dashboard"),
  
  dashboardSidebar(tags$style(".left-side, .main-sidebar { width: 235px }"),
    sidebarMenu(
      id = "tabs",
      menuItem(
        "City Map with Temp/Rain Trends", 
        tabName = "temp_precip_trends", 
        icon = icon("line-chart")
      ),
      menuItem(
        "City Ranking by Temp/Rain", 
        tabName = "city_ranking", 
        icon = icon("bar-chart")
      )
    )
  ),
  
  dashboardBody(
    tabItems(
      tabItem(
        tabName = "temp_precip_trends",
        fluidRow(
          column(
            width = 3,
            # Add slider input for selecting range of months
            sliderInput(
              "month_range",
              "Select Month Range:",
              min = 1,
              max = 12,
              value = c(1, 12)
            ),
            # Add dropdown menu input for selecting state
            selectInput(
              "state",
              "Select State:",
              choices = unique(weather$state)
            ),
            # Add dropdown menu input for selecting city
            selectInput(
              "city",
              "Select City:",
              choices = NULL
            ),
            # Add radio button input for selecting temperature or precipitation
            radioButtons(
              "data_type",
              "Select Type:",
              choices = c("Temperature", "Precipitation"),
              selected = "Temperature"
            ),
            # Add radio button input for selecting temperature metric
            radioButtons(
              "temp_metric",
              "Select Temperature metric:",
              choices = c("Celsius", "Fahrenheit"),
              selected = "Celsius"
            )
          ),
          column(
            width = 9,
            # Added a row for summary statistics
            fluidRow(
              tags$head(
              tags$link(
                rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Avant+Garde&display=swap")
            ),
            column(width = 12,
                   tags$h2(class = "text-center", style = "font-size: 20px; font-weight: bold; font-family: 'Avant Garde', sans-serif;",
                           textOutput("summaryTitle")
                   )
            )),
            fluidRow(
              valueBoxOutput("avgBox"),
              valueBoxOutput("maxBox"),
              valueBoxOutput("minBox")
            ),
            # Add main panel with plot output
            shinycssloaders::withSpinner(
              leafletOutput("map", 
                            height = "285px",
                            width = "100%")
            ),
            column(width = 12,
                   tags$h2(class = "text-center", 
                           style = "font-size: 20px; font-weight: bold; font-family: 'Avant Garde', sans-serif;",
                           textOutput("linetitle")
                   )
            ),
            shinycssloaders::withSpinner(
            plotOutput("line_plot",
                       height = "175px",
                       width = "100%"))
            
          )
        )
      ),
      
      tabItem(
        tabName = "city_ranking",
        fluidRow(
          column(
            width = 2,
            selectInput(
              "statename",
              "Select a state:",
              choices = unique(weather_bar$state)
            ),
            selectInput(
              "highlow",
              "Select highest or lowest temperature:",
              choices = c("Highest" = "high", "Lowest" = "low")
            ),
            selectInput(
              "month",
              "Select a month:",
              choices = unique(weather_bar$month)
            ),
            radioButtons(
              "temp_unit", 
              "Select Temperature metric:",
              choices = c("Celsius", "Fahrenheit"), selected = "Celsius")
          ),
          column(
            width = 10,
            column(width = 12,
                   tags$h2(class = "text-center", style = "font-size: 17px; font-weight: bold; font-family: 'Avant Garde', sans-serif;",
                           textOutput("bar_temptitle")
                   )
            ),
            tags$hr(),
            shinycssloaders::withSpinner(
            plotOutput("temp_barplot",
                       height = "280px",
                       width = "100%")),
            column(width = 12,
                   tags$h2(class = "text-center", style = "font-size: 17px; font-weight: bold; font-family: 'Avant Garde', sans-serif;",
                           textOutput("bar_prectitle")
                   )
            ),
            shinycssloaders::withSpinner(
            plotOutput("rain_barplot",
                       height = "280px",
                       width = "100%"))
          )
        )
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
   output$summaryTitle <- renderText({
     paste("Summary Statistics for", input$city, ",", input$state)
  })
   
   output$linetitle <- renderText({
     if (input$data_type == "Temperature") {
       paste("Average Temperature Distribution for", input$city, ",", input$state)}
     else {paste("Average Precipitation Distribution for", input$city, ",", input$state)}})
   
   output$bar_temptitle <- renderText({
     if (input$temp_unit == "Celsius") {
       ifelse(input$highlow == "high",
            paste("Cities in", input$statename, "by Highest Average Temperature in", input$month, "(°C)"),
            paste("Cities in", input$statename, "by Lowest Average Temperature in", input$month, "(°C)"))}
     else {
       ifelse(input$highlow == "high",
              paste("Cities in", input$statename, "by Highest Average Temperature in", input$month, "(°F)"),
              paste("Cities in", input$statename, "by Lowest Average Temperature in", input$month, "(°F)"))}
     })
   
   output$bar_prectitle <- renderText({
     paste("Cities in", input$statename, "by Average Precipitation in", input$month, "(Inches)")})
   
  # Update city and state input based on map clicks
  observeEvent(input$map_marker_click, {
    updateSelectInput(session, "city", selected = input$map_marker_click$id)
    updateSelectInput(session,
                      "state",
                      selected = cities$state[cities$city == input$map_marker_click$id])
  })
  
  # Update city input possible values based on selected state
  observe({
    updateSelectInput(session,
                      "city",
                      choices = unique(weather$city[weather$state == input$state]))
  })
  

  # --------------------------------------Map plot start here------------------------------------
  
  map_data_color <- reactive({
    weather %>%
      filter(month >= input$month_range[1], month <= input$month_range[length(input$month_range)]) %>%
      group_by(city) %>%
      summarize(
        avg_temp_ft = round(mean(temp_f, na.rm =TRUE), 2),
        avg_temp_cs = round(mean(temp_c, na.rm =TRUE), 2),
        avg_prec = round(mean(precip, na.rm =TRUE), 2),
      )
  })
  
  # Create leaflet map
  output$map <- renderLeaflet({
    leaflet(cities) |>
      addTiles() |>
      addCircleMarkers(
        ~ lon,
        ~ lat,
        popup = paste0(
          "<B>City: </B>",
          cities$city,
          "<br>",
          "<B>State: </B>",
          cities$state,
          "<br>",
          "<B>Elevation: </B>",
          cities$elevation,
          " m<br>",
          "<B>Distance to Coast: </B>",
          cities$distance_to_coast,
          " mi<br>"
        ),
        layerId = cities$city,
        label = cities$city,
        color = 
          if (input$data_type == "Temperature") {
            if (input$temp_metric == "Fahrenheit") {
              if_else(map_data_color()$avg_temp_ft <= 40, "#FEF001", 
                      if_else(map_data_color()$avg_temp_ft <= 60, "#FD9A01", 
                              if_else(map_data_color()$avg_temp_ft <= 80, "#FD6104", "#F00505")))
            }
            else{
              {
                if_else(map_data_color()$avg_temp_cs <= 4, "#grey", 
                        if_else(map_data_color()$avg_temp_cs <= 15, "#f57f7f", 
                                if_else(map_data_color()$avg_temp_cs <= 27, "#f26716", "#fc0000")))
              }
            }
          }
        else {
          if_else(map_data_color()$avg_prec <= 0.05, "#BCD2E8", 
                  if_else(map_data_color()$avg_prec <= 0.15, "#73A5C6", 
                          if_else(map_data_color()$avg_prec <= 0.25, "#2E5984", "#1E3F66")))
        },
        radius = 5,
        stroke = FALSE,
        fillOpacity = 0.5
      ) %>%
      addLegend(title =
                  if (input$data_type == "Temperature") {
                    if (input$temp_metric == "Fahrenheit") {
                      "Heatmap for Average Temperature"}
                    else {
                      "Heatmap for Average Temperature"
                    }
                  }
                else{"Heatmap for Average Precipitation"}
                ,
                colors =
                  if (input$data_type == "Temperature") {
                    c("#fc0000", "#f26716", "#f57f7f", "grey")}
                else{c("#1E3F66", "#2E5984", "#73A5C6", "#BCD2E8")}
                ,
                labels = 
                  if (input$data_type == "Temperature"){
                    if (input$temp_metric == "Fahrenheit") {
                      c("80°F or higher", "60°F - 80°F",  "40°F - 60°F", "40°F or less")}
                    else {
                      c("27°C or higher", "15°C - 27°C", "4°C - 15°C", "4°C or less")}}
                else {c("more than 0.25 inches", "0.15 - 0.25 inches", "0.05 - 0.15 inches", "less than 0.05 inches")}
      ) %>%
      setView(-100, 40, zoom = 3)
  })
  
  
# --------------------------------------Line plot start here------------------------------------
  
  
  # Filter data based on user inputs
  line_data <- reactive({
    weather %>% filter(month >= input$month_range[1], month <= input$month_range[length(input$month_range)]) %>%
      filter(state == input$state, city == input$city) %>%
      group_by(month, high_or_low) %>%
      summarise(
        temp_f = mean(temp_f, na.rm = TRUE),
        temp_c = mean(temp_c, na.rm = TRUE),
        precip = mean(precip, na.rm = TRUE)
      )
  })

  # Create line plot based on filtered data and user data type input

  
  output$line_plot <- renderPlot({
    if (input$data_type == "Temperature") {
      if (input$temp_metric == "Fahrenheit") {
      ggplot(line_data(), aes(x = month, y = temp_f, col = high_or_low)) +
        geom_point() +
        geom_line(size = 1) +
        theme_classic() +
        scale_x_continuous(breaks = seq(1, 12, by = 1)) +
        labs(x = "Month", y = "Temperature (°F)", color = "High/Low") +
        theme(
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_rect(fill = "transparent",colour = NA),
          plot.background = element_rect(fill = "transparent",colour = NA),
          axis.text = element_text(size=12, face="bold", family="AvantGarde"),
          axis.title = element_text(size=12, face="bold", family="AvantGarde"),
          plot.title = element_text(size=20, face="bold", family="AvantGarde", hjust = 0.5),
          legend.text=element_text(size=12, face="bold", family="AvantGarde"), 
          legend.title=element_blank()) 
    }
    else {
      ggplot(line_data(),
             aes(x = month, y = temp_c, col = high_or_low)) +
        geom_point() +
        geom_line(size = 1) +
        theme_classic() +
        scale_x_continuous(breaks = seq(1, 12, by = 1)) +
        labs(x = "Month", y = "Temperature (°C)", color = "High/Low") +
      theme(
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_rect(fill = "transparent",colour = NA),
          plot.background = element_rect(fill = "transparent",colour = NA),
          axis.text = element_text(size=12, face="bold", family="AvantGarde"),
          axis.title = element_text(size=12, face="bold", family="AvantGarde"),
          plot.title = element_text(size=20, face="bold", family="AvantGarde", hjust = 0.5),
          legend.text=element_text(size=12, face="bold", family="AvantGarde"), 
          legend.title=element_blank()) 
    }
      }
    else{
      ggplot(line_data(), aes(x = month, y = precip)) +
        geom_point(color = "violetred") +
        geom_line(color = "lightblue", size = 1) +
        theme_classic() +
        scale_x_continuous(breaks = seq(1, 12, by = 1)) +
        labs(x = "Month", y = "Precipitation (Inches)") +
        theme(
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_rect(fill = "transparent",colour = NA),
          plot.background = element_rect(fill = "transparent",colour = NA),
          axis.text = element_text(size=12, face="bold", family="AvantGarde"),
          axis.title = element_text(size=12, face="bold", family="AvantGarde"),
          plot.title = element_text(size=20, face="bold", family="AvantGarde", hjust = 0.5), 
          legend.text=element_text(size=12, face="bold", family="AvantGarde"))
      }
  }, bg="transparent" )
  
  
  
  # --------------------------------------City Ranking Tab start here------------------------------------
  
  
  # Filter data based on user input, and calculate avg temp and rain
  bar_data <- reactive({
    weather_bar %>% filter(state == input$statename &
                             high_or_low == input$highlow &
                             month == input$month ) %>%
      group_by(city) %>% summarize(
        avg_temp = ifelse(input$temp_unit == "Celsius",
                          mean((temp_f - 32) * 5/9, na.rm = TRUE),
                          mean(temp_f, na.rm = TRUE)),
        avg_rain = mean(precip, na.rm = TRUE)
      )
  })

  # Create bar chart of cities by temperature
  
  output$temp_barplot <- renderPlot({
    
    num_bars <- nrow(bar_data())
    bartext_size <- 5.5 - log10(num_bars)
    label_size <- 15 - log10(num_bars)
    ggplot(bar_data(), aes(x = avg_temp, y = reorder(city, avg_temp),fill= avg_temp)) +
      geom_bar(stat = "identity") + scale_fill_gradient(low="grey", high="red") +
      geom_text(aes(label = paste0(sprintf("%.2f", avg_temp))),
                hjust = -0.1, size = bartext_size, color = "black", fontface="bold") +
      scale_x_continuous(expand = c(0, 0, 0, 3)) +
      labs(
        y = "City"
      ) +
      guides(fill = FALSE) +
      theme(
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "transparent",colour = NA),
        plot.background = element_rect(fill = "transparent",colour = NA),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        plot.title = element_text(size=20, face="bold", family="AvantGarde", hjust = 0.5),
        axis.text.y = element_text(size = label_size, face="bold", family="AvantGarde"),
        axis.ticks.x = element_blank(),
        axis.text.x = element_blank(),
      ) 
  },  bg="transparent")
  
  # Create bar chart of cities by precipitation
  output$rain_barplot <- renderPlot({
    num_bars <- nrow(bar_data())
    bartext_size <- 5.5 - log10(num_bars)
    label_size <- 15 - log10(num_bars)
    ggplot(bar_data(), aes(x = avg_rain, y = reorder(city, avg_rain), fill = avg_rain)) +
      geom_bar(stat = "identity") + scale_fill_gradient(low="lightblue", high="darkblue") +
      geom_text(aes(label = sprintf("%.4f", avg_rain)), 
                hjust = -0.1,  size = bartext_size, color = "black", fontface="bold") +
      scale_x_continuous(expand = c(0, 0, 0, 0.09)) +
      labs(
        y = "City"
      )+
      guides(fill = FALSE)+
      theme(
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "transparent",colour = NA),
        plot.background = element_rect(fill = "transparent",colour = NA),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        plot.title = element_text(size=20, face="bold", family="AvantGarde", hjust = 0.5),
        axis.text.y = element_text(size = label_size, face="bold", family="AvantGarde"),
        axis.ticks.x = element_blank(),
        axis.text.x = element_blank(),
      ) 
  },  bg="transparent")
  
  # --------------------------------------summary statistics box start here------------------------------------
  
  # data processing for summary statistics
  stat_data <- reactive({
    weather %>% filter(city == input$city ) %>%
      filter(month >= input$month_range[1], month <= input$month_range[length(input$month_range)]) %>%
      group_by(city) %>% 
      summarize(
        avg_temp_ft = round(mean(temp_f, na.rm =TRUE), 2),
        min_temp_ft = min(temp_f, na.rm =TRUE),
        max_temp_ft = max(temp_f, na.rm =TRUE),
        avg_temp_cs = round(mean(temp_c, na.rm =TRUE), 2),
        min_temp_cs = min(temp_c, na.rm =TRUE),
        max_temp_cs = max(temp_c, na.rm =TRUE),
        avg_prec = round(mean(precip, na.rm =TRUE), 2),
        min_prec= min(precip, na.rm =TRUE),
        max_prec = max(precip, na.rm =TRUE)
      )
  })
  
  # create max summary statistic box
  output$maxBox <- renderValueBox({
    if (input$data_type == "Temperature") {
      if (input$temp_metric == "Fahrenheit") {
        valueBox(
          paste0(stat_data()$max_temp_ft, "°F"), "MAX", icon = icon("fa-light fa-sun"),
          color = "red")
      }
      else {
         {
           valueBox(
          paste0(stat_data()$max_temp_cs, "°C"), "MAX", icon = icon("fa-light fa-sun"),
          color = "red"
         
      )
      }
      }
    }
    else{
      valueBox(
        paste0(stat_data()$max_prec, " in."), "MAX", icon = icon("fa-regular fa-cloud-sun-rain"),
        color = "red")
    }
  })
  
  # create min summary statistic box
  output$minBox <- renderValueBox({
    if (input$data_type == "Temperature") {
      if (input$temp_metric == "Fahrenheit") {
      valueBox(
        paste0(stat_data()$min_temp_ft, "°F"), "MIN", icon = icon("fa-light fa-sun"),
        color = "blue"
      )
      }
      else{
        valueBox(
          paste0(stat_data()$min_temp_cs, "°C"), "MIN", icon = icon("fa-light fa-sun"),
          color = "blue"
        )
      }
    }
    else{
      valueBox(
        paste0(stat_data()$min_prec, " in."), "MIN", icon = icon("fa-regular fa-cloud-sun-rain"),
        color = "blue")
    }
  })
  
  # create avg summary statistic box
  output$avgBox <- renderValueBox({
    if (input$data_type == "Temperature") {
      if (input$temp_metric == "Fahrenheit") {
      valueBox(
        paste0(stat_data()$avg_temp_ft, "°F"), "AVG", icon = icon("fa-light fa-sun"),
        color = "green"
      )
      }
      else
      {
        valueBox(
          paste0(stat_data()$avg_temp_cs, "°C"), "AVG", icon = icon("fa-light fa-sun"),
          color = "green"
        )
      }
    }
    else{
      valueBox(
        paste0(stat_data()$avg_prec, " in."), "AVG", icon = icon("fa-regular fa-cloud-sun-rain"),
        color = "green")
    }
  })
  
  
}

# Run app
shinyApp(ui, server)

