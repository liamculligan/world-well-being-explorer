#World Explorer

#Shiny App

#Authors: Tyrone Cragg and Liam Culligan

#Date: November 2016

#Load required packages
library(shiny)
library(data.table)
library(dplyr)
library(dtplyr)
library(leaflet)
library(ggplot2)
library(RColorBrewer)
library(plotly)
library(lazyeval)

#Load required data
load("pre_process.RData")

#Covert Factors
cities_countries$continent = as.factor(cities_countries$continent)
cities_countries$region = as.factor(cities_countries$region)

format_names = function(x, city_country = F) {
  x = tolower(x)
  
  if (city_country == T & grepl("happiness", x) == T) {
    x = paste0(x, "_(Country)")
  }
  if (grepl("happiness_score", x) == F) {
    x = gsub("happiness_", "", x)
  }
  if (city_country == T & grepl("liveability", x) == T) {
    x = paste0(x, "_(City)")
  }
  if (grepl("liveability_score", x) == F) {
    x = gsub("liveability_", "", x)
  }
  
  x = gsub("_", " ", x)
  x = strsplit(x, " ")[[1]]
  x = paste(toupper(substring(x, 1,1)), substring(x, 2), sep="", collapse=" ")
  x = gsub("Gdp", "GDP", x)
  
  return(x)
}

happiness_choices = as.list(names(countries_df)[grepl("happiness", names(countries_df))])
names(happiness_choices) = sapply(happiness_choices, format_names)

liveability_choices = as.list(names(cities_countries)[grepl("liveability", names(cities_countries)) & 
                                                        !grepl("rank", names(cities_countries))])
names(liveability_choices) = sapply(liveability_choices, format_names)

happiness_choices_city_country = as.list(names(countries_df)[grepl("happiness", names(countries_df))])
names(happiness_choices_city_country) = sapply(happiness_choices_city_country, format_names, city_country = T)

liveability_choices_city_country = as.list(names(cities_countries)[grepl("liveability", names(cities_countries)) & 
                                                                     !grepl("rank", names(cities_countries))])
names(liveability_choices_city_country) = sapply(liveability_choices_city_country, format_names, city_country = T)

happiness_liveability_choices = as.list(c(names(cities_countries)[grepl("happiness", names(cities_countries)) &
                                                                    !grepl("rank", names(cities_countries))],
                                          names(cities_countries)[grepl("liveability", names(cities_countries)) &
                                                                    !grepl("rank", names(cities_countries))]))
names(happiness_liveability_choices) = sapply(happiness_liveability_choices, format_names, city_country = T)


#Set theme
themes_data = {
  x = list()
  
  x$colours =
    c(dkgray = rgb(60, 60, 60, max = 255),
      medgray = rgb(210, 210, 210, max = 255),
      ltgray = rgb(240, 240, 240, max = 255),
      red = rgb(255, 39, 0, max = 255),
      blue = rgb(0, 143, 213, max = 255),
      green = rgb(119, 171, 67, max = 255))
  
  x
}

our_theme = theme(
  line = element_line(colour = "black"),
  rect = element_rect(fill = themes_data$colours["ltgray"], linetype = 0, colour = NA),
  text = element_text(colour = themes_data$colours["dkgray"]),
  axis.ticks = element_blank(),
  axis.line = element_blank(),
  legend.background = element_rect(),
  legend.position = "top",
  legend.direction = "horizontal",
  legend.box = "vertical",
  panel.grid = element_line(colour = NULL),
  panel.grid.major =
    element_line(colour = themes_data$colours["medgray"]),
  panel.grid.minor = element_blank(),
  plot.title = element_text(hjust = 0.5, size = 20),
  axis.title = element_text(size = 14),
  plot.margin = unit(c(1, 1, 1, 1), "lines"),
  strip.background = element_rect())

#Build the UI
ui = fluidPage(
  
  theme = "bootstrap.css",
  
  uiOutput(outputId = "styles"),
  
  conditionalPanel(condition="$('html').hasClass('shiny-busy') | $('#leafletMap').hasClass('recalculating') |
                   (!$('#leafletMap').hasClass('leaflet-container'))",
                   tags$div("Loading...", id="loadmessage")),
  
  navbarPage(title = "World Explorer", id = "tabs",
             tabPanel(title = "Map", mainPanel(leafletOutput(outputId = "leafletMap"), width = 12)),
             tabPanel(title = "Plots", 
                      conditionalPanel("input.plotInput == 'Scatter Plot'", 
                                       mainPanel(plotlyOutput(outputId = "scatterPlot"), width = 9)),
                      conditionalPanel("input.plotInput == 'City Rankings' && input.orderInput == 'Descending'", 
                                       mainPanel(plotOutput(outputId = "cityRankingPlotDesc"), width = 9)),
                      conditionalPanel("input.plotInput == 'City Rankings' && input.orderInput == 'Ascending'", 
                                       mainPanel(plotOutput(outputId = "cityRankingPlotAsc"), width = 9)),
                      conditionalPanel("input.plotInput == 'Country Rankings' && input.orderInput == 'Descending'", 
                                       mainPanel(plotOutput(outputId = "countryRankingPlotDesc"), width = 9)),
                      conditionalPanel("input.plotInput == 'Country Rankings' && input.orderInput == 'Ascending'", 
                                       mainPanel(plotOutput(outputId = "countryRankingPlotAsc"), width = 9))
             )
  ),
  
  conditionalPanel(
    "input.tabs == 'Map' && (!$('html').hasClass('shiny-busy')) && (!$('#leafletMap').hasClass('recalculating')) &&
    $('#leafletMap').hasClass('leaflet-container')",
    
    absolutePanel(
      id = "userOptions",
      top = "80px", right = "20px",
      width = "20%",
      draggable = T,
      
      HTML('<a data-toggle="collapse" data-target="#demo">Collapse</a>'),
      
      titlePanel("Map Options"),
      
      tags$div(
        id = 'demo',
        class="collapse in",
        
        selectInput(inputId = "mapCountryMetricInput", label = "Country Happiness Input",
                    choices = happiness_choices,
                    selected = "happiness_score", multiple = F),
        
        selectInput(inputId = "mapCityMetricInput", label = "City Liveability Input",
                    choices = liveability_choices,
                    selected = "liveability_score", multiple = F)
        
      )
    )
  ),
  
  conditionalPanel(
    "input.tabs == 'Plots'",
    fixedPanel(
      id = "userOptionsPlot",
      top = "50px", right = "20px",
      width = "20%",
      
      titlePanel("Plot Options"),
      
      radioButtons(inputId = "plotInput", label = "Plot Type", choices = c("Country Rankings", "City Rankings", "Scatter Plot"),
                   selected = "Scatter Plot", inline = T),
      
      conditionalPanel("input.plotInput == 'Country Rankings'",                 
                       selectInput(inputId = "countryMetricInput", label = "Country Happiness Metric",
                                   choices = happiness_choices,
                                   selected = "happiness_score", multiple = F)),
      
      conditionalPanel("input.plotInput == 'City Rankings'",
                       selectInput(inputId = "cityMetricInput", label = "City Liveability Metric",
                                   choices = liveability_choices,
                                   selected = "liveability_score", multiple = F)),
      
      conditionalPanel("input.plotInput == 'City Rankings' | input.plotInput == 'Country Rankings'",
                       
                       radioButtons(inputId = "orderInput", label = "Order", choices = c("Descending", "Ascending"),
                                    selected = "Descending", inline = T)),
      
      conditionalPanel("input.plotInput == 'Country Rankings'",                 
                       radioButtons(inputId = "countrySpecificInput", label = "Select Specific Countries?",
                                    choices = c("Yes", "No"),
                                    selected = "No", inline = T)),
      
      conditionalPanel("input.plotInput == 'City Rankings'",                 
                       radioButtons(inputId = "citySpecificInput", label = "Select Specific Cities?",
                                    choices = c("Yes", "No"),
                                    selected = "No", inline = T)),
      
      conditionalPanel("input.plotInput == 'Country Rankings' && input.countrySpecificInput == 'Yes'",                 
                       selectInput(inputId = "countrySpecificListInput", label = "Countries",
                                   choices = sort(unique(countries_df$name)),
                                   selected = c("South Africa", "Algeria"), multiple = T)),
      
      conditionalPanel("input.plotInput == 'City Rankings' && input.citySpecificInput == 'Yes'",                 
                       selectInput(inputId = "citySpecificListInput", label = "Cities",
                                   choices = sort(unique(cities_countries$city_country)),
                                   selected = c("Johannesburg, South Africa", "Algiers, Algeria"), multiple = T)),
      
      conditionalPanel("(input.plotInput == 'City Rankings' && input.citySpecificInput == 'No') |
                       (input.plotInput == 'Country Rankings' && input.countrySpecificInput == 'No')",
                       
                       checkboxGroupInput(inputId = "continentInput", label = "Continents", choices = levels(cities_countries$continent),
                                          selected = levels(cities_countries$continent), inline = T)),
      
      conditionalPanel("input.plotInput == 'Country Rankings' && input.countrySpecificInput == 'No'",
                       uiOutput(outputId = "countryLimitOutput")),
      
      conditionalPanel("input.plotInput == 'City Rankings' && input.citySpecificInput == 'No'",
                       uiOutput(outputId = "cityLimitOutput")),
      
      conditionalPanel("input.plotInput == 'Scatter Plot'",                 
                       selectInput(inputId = "xAxisInput", label = "x-Axis Value",
                                   choices = happiness_liveability_choices,
                                   selected = "happiness_score", multiple = F),
                       
                       selectInput(inputId = "yAxisInput", label = "y-Axis Value",
                                   choices = happiness_liveability_choices,
                                   selected = "liveability_score", multiple = F))
      
    )
  )
  )

#Build the Outputs
server = function(input, output) {
  
  #Using reactive() allows these reactive variables to be saved to memory. Computationally more efficient.
  
  mapCountryMetric = reactive({
    input$mapCountryMetricInput
  })
  
  mapCityMetric = reactive({
    input$mapCityMetricInput
  })
  
  countryMetric = reactive({
    input$countryMetricInput
  })
  
  cityMetric = reactive({
    input$cityMetricInput
  })
  
  #Reactive variable that controls which continents are selected
  continentSelected = reactive({
    input$continentInput
  })
  
  #Reactive variable that controls leaflet annotation by country
  countryRankText = reactive({
    ifelse(!is.na(countries[[mapCountryMetric()]]),
           paste0("<b>", countries[['NAME']], "</b><br>", format_names(mapCountryMetric()), ": ", round(countries[[mapCountryMetric()]],2),
                  "<br>Rank: ", countries[[paste0(mapCountryMetric(), "_rank")]], "/", 
                  max(countries[[paste0(mapCountryMetric(), "_rank")]], na.rm = T)),
           paste0("<b>", countries[['NAME']], "</b><br>", "No Data"))
  })
  
  observe({print(countryRankText)})
  
  #Reactive variable that controls leaflet annotation by city
  cityRankText = reactive({
    paste0("<b>", cities_countries[['city']], "</b><br>", format_names(mapCityMetric()), ": ",
           round(cities_countries[[mapCityMetric()]],2),
           "<br>Rank: ", cities_countries[[paste0(mapCityMetric(), "_rank")]], "/", 
           max(cities_countries[[paste0(mapCityMetric(), "_rank")]], na.rm = T))
  })
  
  observe({print(cityRankText)})
  
  #Reactive variable that controls whether country plots are coloured/filled by continent or region
  countryColourVar = reactive({
    if (countrySpecific() == "No") {
      if (length(continentSelected()) > 1) {
        "continent"
      } else {
        "region"
      }
    } else {
      if (length(unique(filtered_country()$continent)) > 1) {
        "continent"
      } else {
        "region"
      }
    } 
  })
  
  #Reactive variable that controls whether city plots are coloured/filled by continent or region
  cityColourVar = reactive({
    if (citySpecific() == "No") {
      if (length(continentSelected()) > 1) {
        "continent"
      } else {
        "region"
      }
    } else {
      if (length(unique(filtered_city()$continent)) > 1) {
        "continent"
      } else {
        "region"
      }
    } 
  })
  
  #Order
  orderVar = reactive({
    if (input$orderInput == "Descending") {
      "desc"
    } else {
      "asc"
    }
  })
  
  #Reactive variable to control whether specific countries are selected
  countrySpecific = reactive({
    input$countrySpecificInput
  })
  
  #Reactive variable to select specific countries
  countrySpecificList = reactive({
    input$countrySpecificListInput
  })
  
  #Filtering data based on the number of continents or regions required
  pre_filtered_country = reactive({
    if (countrySpecific() == "No") {
      countries_df %>%
        filter(continent %in% continentSelected())
    } else {
      countries_df %>%
        filter(name %in% countrySpecificList())
    }
  })
  
  #Reactive variable to control the number of countries selected
  countryLimit = reactive({
    if (is.null(input$countryLimitInput)) {
      30
    } else {
      input$countryLimitInput
    }
  })
  
  output$styles = renderUI({ 
    
    if (countryLimit() <= 30) {
      height = 100
    } else {
      height = 100 + (3*(countryLimit() - 30))
    }
    
    tags$style(paste0("#countryRankingPlotDesc {
                      height:calc(", height, "vh - 80px) !important;
                      width:100% !important;
                      padding:20px; }"))
    
})
  
  output$countryLimitOutput = renderUI({ 
    sliderInput(inputId = "countryLimitInput", label = "Number of Countries",
                min = 5, max = nrow(pre_filtered_country()), value = 30, step = 1, round = T)
  })
  
  #Filter based on the value of countryLimit and the order selected
  filtered_country = reactive({
    #Filter the data for the case where a user has not selected specific countries
    if (countrySpecific() == "No") {
      if (orderVar() == "desc") {
        
        pre_filtered_country() %>%
          arrange_(lazyeval::interp(~desc(var), var = as.name(countryMetric()))) %>%
          head(countryLimit())
        
      } else {
        
        pre_filtered_country() %>%
          arrange_(lazyeval::interp(~(var), var = as.name(countryMetric()))) %>%
          head(countryLimit())
      }
    } else {
      #Filter the data for the case where a user has selected specific countries
      if (orderVar() == "desc") {
        
        pre_filtered_country() %>%
          arrange_(lazyeval::interp(~desc(var), var = as.name(countryMetric())))
        
      } else {
        
        pre_filtered_country() %>%
          arrange_(lazyeval::interp(~(var), var = as.name(countryMetric()))) 
      }
    }
  })
  
  #Reactive variable to control whether specific cities are selected
  citySpecific = reactive({
    input$citySpecificInput
  })
  
  #Reactive variable to select specific cities
  citySpecificList = reactive({
    input$citySpecificListInput
  })
  
  observe({print(citySpecific())})
  observe({print(citySpecificList())})
  
  #Filtering city data based on the number of continents or regions required
  pre_filtered_city = reactive({
    if (citySpecific() == "No") {
      cities_countries %>%
        filter(continent %in% continentSelected())
    } else {
      cities_countries %>%
        filter(city_country %in% citySpecificList())
    }
  })
  
  #Reactive variable to control the number of cities selected
  cityLimit = reactive({
    if (is.null(input$cityLimitInput)) {
      30
    } else {
      input$cityLimitInput
    }
  })
  
  output$cityLimitOutput = renderUI({ 
    sliderInput(inputId = "cityLimitInput", label = "Number of Cities",
                min = 5, max = nrow(pre_filtered_city()), value = 30, step = 1, round = T)
  })
  
  #Filter based on the value of cityLimit and the order selected
  filtered_city = reactive({
    #Filter the data for the case where a user has not selected specific cities
    if (citySpecific() == "No") {
      if (orderVar() == "desc") {
        
        pre_filtered_city() %>%
          arrange_(lazyeval::interp(~desc(var), var = as.name(cityMetric()))) %>%
          head(cityLimit())
        
      } else {
        
        pre_filtered_city() %>%
          arrange_(lazyeval::interp(~(var), var = as.name(cityMetric()))) %>%
          head(cityLimit())
      }
    } else {
      #Filter the data for the case where a user has selected specific cities
      if (orderVar() == "desc") {
        
        pre_filtered_city() %>%
          arrange_(lazyeval::interp(~desc(var), var = as.name(cityMetric())))
        
      } else {
        
        pre_filtered_city() %>%
          arrange_(lazyeval::interp(~(var), var = as.name(cityMetric()))) 
      }
    }
  })
  
  #Reactive variables for x-Axis values and y-Axis values on the scatter plot
  xAxis = reactive({
    input$xAxisInput
  })
  
  yAxis = reactive({
    input$yAxisInput
  })
  
  scatterLines = reactive({
    input$xAxisInput
  })
  
  #Reactive variables for x-Axis label and y-Axis label on the scatter plot
  xAxisLabel = reactive({
    xAxis()
  })
  
  yAxisLabel = reactive({
    yAxis()
  })
  
  #Create a new data frame to annotate the hline and vline on the scatter plot
  scatterLines = reactive({
    data.frame(x = c(mean(cities_countries[[xAxis()]], na.rm=T), min(cities_countries[[xAxis()]], na.rm=T)),
               y = c(min(cities_countries[[yAxis()]], na.rm=T), mean(cities_countries[[yAxis()]], na.rm=T)))
  })
  
  #Reactive variable for plotly annotation
  plotAnnotate = reactive({
    if (grepl("happiness", xAxis()) & grepl("happiness", yAxis())) {
      "country"
    } else {
      "city_country"
    }
  })
  
  observe({print(plotAnnotate())})
  
  #Add custom legend for circles
  addLegendCustom = function(map, position = "topright", title = "", colors, labels, sizes, opacity = 0.5){
    colorAdditions = paste0(colors, "; width:", sizes, "px; height:", sizes, "px")
    labelAdditions = paste0("<div style='display:inline-block; border-radius:50% !important; height:", sizes, "px; margin-top:4px; line-height:", sizes, "px;'>", labels, "</div>")
    
    return(addLegend(map, position = position, title = title, colors = colorAdditions, labels = labelAdditions, opacity = opacity, className = "info legend leaflet-control leafletLegendCircles"))
  }
  
  #Map Output
  output$leafletMap = renderLeaflet({
    
    leaflet(countries) %>%
      
      # addProviderTiles("MtbMap", options=tileOptions(minZoom=2, maxZoom=9)) %>%
      
      setView(0, 0, zoom=2) %>%
      
      setMaxBounds(220, 85, -220, -63) %>%
      
      addLegend("bottomleft", pal = colorNumeric(c("darkred", "orangered", "orange", "yellow", "yellowgreen", "green"), 
                                                 countries[[mapCountryMetric()]]), values = ~countries[[mapCountryMetric()]],
                title = format_names(mapCountryMetric()), labFormat = labelFormat(suffix = ""), opacity = 0.8, na.label = "No Data") %>%
      
      addPolygons(weight = 1,
                  color = "#000",
                  opacity = 0.2,
                  fillOpacity = 1,
                  fillColor = ~colorNumeric(c("darkred", "orangered", "orange", "yellow", "yellowgreen", "green"), 
                                            countries$countries[[mapCountryMetric()]])(countries[[mapCountryMetric()]]),
                  
                  popup=~countryRankText(),
                  
                  label=~paste0(NAME, ": ", round(countries[[mapCountryMetric()]],2)),
                  labelOptions= labelOptions(direction = 'auto'),
                  
                  highlightOptions = highlightOptions(
                    color='#000000', opacity = 1, weight = 1, fillOpacity = 1,
                    bringToFront = F, sendToBack = T)) %>%
      
      addCircles(data = cities_countries, lng = ~lng, lat = ~lat, weight = 1, radius = ~(cities_countries[[mapCityMetric()]]) * 1000, 
                 color = "black",
                 fillColor = "black",
                 opacity = 0,
                 fillOpacity = 0.5,
                 
                 popup=~cityRankText(),
                 
                 # label=~paste0(city, ": ", round(overall_rating,2)),
                 # labelOptions= labelOptions(direction = 'auto', noHide = T, textOnly = FALSE,
                 #                    style=list(
                 #                      'color'='black',
                 #                      'font-family'= 'serif',
                 #                      'font-style'= 'normal',
                 #                      'box-shadow' = '3px 3px rgba(0,0,0,0.25)',
                 #                      'font-size' = '12px',
                 #                      'border-color' = 'rgba(0,0,0,0.5)')),
                 
                 highlightOptions = highlightOptions(
                   color='#000000', fillOpacity = 1,
                   bringToFront = T, sendToBack = F)
      ) %>%
      
      addLegendCustom(position = "bottomleft", title = format_names(mapCityMetric()), opacity = 0.7,
                      colors = c("black", "black", "black"),
                      labels = c(round(min(cities_countries[[mapCityMetric()]], na.rm=T), 0),
                                 round(mean(cities_countries[[mapCityMetric()]], na.rm=T), 0),
                                 round(max(cities_countries[[mapCityMetric()]], na.rm=T), 0)),
                      sizes = c(10, 15, 20))
    
  })
  
  # output$scatterPlot = renderPlotly({
  #   ggplotly(ggplot(cities_countries, aes_string(x = input$countryMetricInput, y = input$cityMetricInput)) +
  #              geom_point())
  # })
  
  
  output$scatterPlot = renderPlotly({
    ggplotly(
      ggplot(na.omit(cities_countries), aes_string(x = xAxis(), y = yAxis(), col = "continent")) +
        geom_point(alpha = 0.8, size = 2, aes_string(text = plotAnnotate())) +
        geom_vline(xintercept = mean(cities_countries[[xAxis()]], na.rm = T), colour = "black",  linetype = "longdash", alpha = 0.5) +
        # geom_text(aes(mean(cities_countries$happiness_score, na.rm = T), min(cities_countries$liveability_overall_rating, na.rm = T),
        #               label = "average of\n x var", hjust = -0.1,  vjust = "inward", size = 9, colour = "black")) +
        geom_hline(yintercept = mean(cities_countries[[yAxis()]], na.rm = T), colour = "black", linetype = "longdash", alpha = 0.5) +
        # geom_text(aes(min(cities_countries$happiness_score, na.rm = T), mean(cities_countries$liveability_overall_rating, na.rm = T),
        #               label = "average of \ny var", vjust = -0.25,  hjust = "inward")) +
        our_theme +
        labs(list(x = format_names(xAxisLabel(), city_country = T), y = format_names(yAxisLabel(), city_country = T),
                  title = paste(format_names(yAxis()), "Against", format_names(xAxis()), sep = " "))) +
        scale_colour_brewer(name = "", palette = "Set1"),
      tooltip = "text") %>% 
      
      layout(legend = list(orientation = "h", xanchor = "center", yanchor = "top", x = 0.5, y = -0.3),
             xaxis = list(fixedrange = T, titlefont = list(size = 14)),
             yaxis = list(fixedrange = T, titlefont = list(size = 14)),
             titlefont = list(size = 18)) %>%
      
      config(displayModeBar = F, showTips = F, sendData = F)
    
    
  })
  
  output$countryRankingPlotDesc = renderPlot({
    ggplot(filtered_country(), aes_string(paste0("reorder(", "name", ",", countryMetric(), ")"), countryMetric(), fill = countryColourVar())) +
      geom_bar(stat = "identity") +
      coord_flip() +
      our_theme +
      labs(list(x = "Country", y = format_names(countryMetric()), title = paste(format_names(countryMetric()), "by Country", sep = " "))) +
      scale_fill_discrete(name = format_names(countryColourVar()))
  })
  
  output$countryRankingPlotAsc = renderPlot({
    ggplot(filtered_country(), aes_string(paste0("reorder(", "name", ",-", countryMetric(), ")"), countryMetric(), fill = countryColourVar())) +
      geom_bar(stat = "identity") +
      coord_flip() +
      our_theme +
      labs(list(x = "Country", y = format_names(countryMetric()), title = paste(format_names(countryMetric()), "by Country", sep = " "))) +
      scale_fill_discrete(name = format_names(countryColourVar()))
  })
  
  output$cityRankingPlotDesc = renderPlot({
    ggplot(filtered_city(), aes_string(paste0("reorder(", "city", "," ,cityMetric(), ")"), cityMetric(), fill = cityColourVar())) +
      geom_bar(stat = "identity") +
      coord_flip() +
      our_theme +
      labs(list(x = "City", y = format_names(cityMetric()), title = paste(format_names(cityMetric()), "by City", sep = " "))) +
      scale_fill_discrete(name = format_names(cityColourVar()))
  })
  
  output$cityRankingPlotAsc = renderPlot({
    ggplot(filtered_city(), aes_string(paste0("reorder(", "city", ",-", cityMetric(), ")"), cityMetric(), fill = cityColourVar())) +
      geom_bar(stat = "identity") +
      coord_flip() +
      our_theme +
      labs(list(x = "City", y = format_names(cityMetric()), title = paste(format_names(cityMetric()), "by City", sep = " "))) +
      scale_fill_discrete(name = format_names(cityColourVar()))
  })
  
  }

shinyApp(ui = ui, server = server)