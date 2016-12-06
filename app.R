#World Well-being Explorer

#An open-source, user-friendly Shiny App to explore well-being throughout the world

#Authors: Tyrone Cragg and Liam Culligan

#Date: November 2016

#Install the required packages for the app
packages_required = c("shiny", "data.table", "dplyr", "dtplyr", "leaflet", "ggplot2", "RColorBrewer",
                      "plotly", "lazyeval")
new_packages = packages_required[!(packages_required %in% installed.packages()[,"Package"])]
if(length(new_packages) > 0) {
  install.packages(new_packages)
}

#Leaflet version 1.0.2 is required. As of 3 December 2016, this version is not on CRAN,
#so install development version from Github
if (packageVersion("leaflet") < '1.0.2') {
  install.packages("devtools")
  library(devtools)
  devtools::install_github("rstudio/leaflet")
}

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

#Build the UI
ui = fluidPage(
  
  #Plot using canvas rather than SVG when available
  tags$head(
    tags$script("L_PREFER_CANVAS = true;")
  ),
  
  #Load custom CSS theme
  theme = "bootstrap.css",
  
  #Favicon
  list(tags$head(HTML('<link rel="icon", href="images/logo.png", type="image/png" />'))),
  
  #App description
  list(tags$head(HTML('<meta name="description" content="Interactive maps and plots to explore well-being around the world."/>'))),
  
  #Add logo, source code and share buttons
  HTML('<div class="navLogo">
          <div>
            <img src="images/logo.png" height="30" border="0" />
          </div>
       </div>
        <div class="navExtra">
          <div>
            Source Code:
          </div>
          <a href="https://github.com/liamculligan/world-well-being-explorer", target="_blank">
            <img src="images/github.png" height="30" border="0" />
          </a>
          <div>
            Share:
          </div>
          <a href="http://www.linkedin.com/shareArticle?mini=true&url=http://www.worldwellbeingexplorer.com/", target="_blank">
            <img src="images/linkedin.png" height="30" border="0" />
          </a>
          <a href="http://twitter.com/share?url=http://www.worldwellbeingexplorer.com/&text=Explore world happiness and city liveability with the World Well-being Explorer:", target="_blank">
            <img src="images/twitter.png" height="30" border="0" />
          </a>
          <a href="http://www.facebook.com/sharer.php?u=http://www.worldwellbeingexplorer.com/", target="_blank">
            <img src="images/facebook.png" height="30" border="0" />
          </a>
       </div>'),
  
  #Source javascript for Google Anaytics
  tags$head(includeScript("google-analytics.js")),
  
  #If anything is loading, add loading overlay and icon
  conditionalPanel(condition="$('html').hasClass('shiny-busy') | $('#leafletMap').hasClass('recalculating') |
                   (!$('#leafletMap').hasClass('leaflet-container'))",
                   
                   HTML('<div id="loadingContainer"><div id="loading">
                      		<div class="cssload-cssload-loader-line-wrap-wrap">
                      			<div class="cssload-loader-line-wrap"></div>
                      		</div>
                      		<div class="cssload-cssload-loader-line-wrap-wrap">
                      			<div class="cssload-loader-line-wrap"></div>
                      		</div>
                      		<div class="cssload-cssload-loader-line-wrap-wrap">
                      			<div class="cssload-loader-line-wrap"></div>
                      		</div>
                      		<div class="cssload-cssload-loader-line-wrap-wrap">
                      			<div class="cssload-loader-line-wrap"></div>
                      		</div>
                      		<div class="cssload-cssload-loader-line-wrap-wrap">
                      			<div class="cssload-loader-line-wrap"></div>
                      		</div>
                        </div></div>')
  ),
  
  #If map is loading, disable navigation buttons
  conditionalPanel(condition="$('#leafletMap').hasClass('recalculating') |
                   (!$('#leafletMap').hasClass('leaflet-container'))",
                   HTML('<div id="loadingNav">
                          <div class="navbar-header">
                            <span class="navbar-brand">World Well-being Explorer</span>
                          </div>
                        </div>')
  ),
  
  #Navigation bar
  navbarPage(title = "World Well-being Explorer", id = "tabs",
             tabPanel(title = "Interactive Map", mainPanel(leafletOutput(outputId = "leafletMap"), width = 12)),
             tabPanel(title = "Plots", 
                      
                      conditionalPanel("input.plotInput == 'Scatter Plot'", 
                                       mainPanel(plotlyOutput(outputId = "scatterPlot"), width = 9)),
                      
                      conditionalPanel("input.plotInput == 'Country Rankings' && input.orderInput == 'Descending'", 
                                       mainPanel(uiOutput(outputId = "countryRankingPlotDesc"), width = 9)),
                      
                      conditionalPanel("input.plotInput == 'Country Rankings' && input.orderInput == 'Ascending'", 
                                       mainPanel(uiOutput(outputId = "countryRankingPlotAsc"), width = 9)),
                      
                      conditionalPanel("input.plotInput == 'City Rankings' && input.orderInput == 'Descending'", 
                                       mainPanel(uiOutput(outputId = "cityRankingPlotDesc"), width = 9)),
                      
                      conditionalPanel("input.plotInput == 'City Rankings' && input.orderInput == 'Ascending'", 
                                       mainPanel(uiOutput(outputId = "cityRankingPlotAsc"), width = 9))
                      
             ),
             tabPanel(title = "About", mainPanel(includeHTML("about.html"), width = 12))
  ),
  
  #If Map tab is selected and loading is complete
  conditionalPanel(
    "input.tabs == 'Interactive Map' && (!$('html').hasClass('shiny-busy')) && (!$('#leafletMap').hasClass('recalculating')) &&
    $('#leafletMap').hasClass('leaflet-container')",
    
    absolutePanel(
      id = "userOptions",
      top = "80px", right = "20px",
      width = "250px",
      draggable = T,
      
      # HTML('<a data-toggle="collapse" data-target="#demo">Collapse</a>'),
      
      titlePanel("Map Options"),
      
      tags$div(
        id = 'demo',
        class="collapse in",
        selectInput(inputId = "mapCountryMetricInput", label = "Country Happiness Input",
                    choices = happiness_choices,
                    selected = "happiness_score", multiple = F),
        helpText("Click on a country for more info"),
        uiOutput(outputId = "mapCityMetricOutput"),
        helpText("Click on a city for more info")
        
      )
    )
  ),
  
  #If Plots tab is selected and loading is complete
  conditionalPanel(
    "input.tabs == 'Plots' && (!$('#leafletMap').hasClass('recalculating')) &&
    $('#leafletMap').hasClass('leaflet-container')",
    fixedPanel(
      id = "userOptionsPlot",
      top = "50px", right = "20px",
      width = "20%",
      
      titlePanel("Plot Options"),
      
      #A user can select 1 of the 3 choices
      radioButtons(inputId = "plotInput", label = "Plot Type", choices = c("Country Rankings", "City Rankings", "Scatter Plot"),
                   selected = "Country Rankings", inline = T),
      
      #If a user has selected 'Country Rankings' display the appropriate variables in a dropdown menu
      conditionalPanel("input.plotInput == 'Country Rankings'",                 
                       selectInput(inputId = "countryMetricInput", label = "Country Happiness Metric",
                                   choices = happiness_choices,
                                   selected = "happiness_score", multiple = F)),
      
      #If a user has selected 'City Rankings' display the appropriate variables in a dropdown menu
      conditionalPanel("input.plotInput == 'City Rankings'",
                       selectInput(inputId = "cityMetricInput", label = "City Liveability Metric",
                                   choices = liveability_choices,
                                   selected = "liveability_score", multiple = F)),
      
      #If a user has selected either 'Country Rankings' or 'City Rankings' display the plot in the selected order
      conditionalPanel("input.plotInput == 'City Rankings' | input.plotInput == 'Country Rankings'",
                       radioButtons(inputId = "orderInput", label = "Order", choices = c("Descending", "Ascending"),
                                    selected = "Descending", inline = T)),
      
      #A user can select the option to only select specific countries in the bar plot
      conditionalPanel("input.plotInput == 'Country Rankings'",                 
                       radioButtons(inputId = "countrySpecificInput", label = "Select Specific Countries?",
                                    choices = c("Yes", "No"),
                                    selected = "No", inline = T)),
      
      #A user can select the option to only select specific cities in the bar plot
      conditionalPanel("input.plotInput == 'City Rankings'",                 
                       radioButtons(inputId = "citySpecificInput", label = "Select Specific Cities?",
                                    choices = c("Yes", "No"),
                                    selected = "No", inline = T)),
      
      #If a user has chosen to select specific countries, an option appears prompting the user to select countries
      conditionalPanel("input.plotInput == 'Country Rankings' && input.countrySpecificInput == 'Yes'",                 
                       selectInput(inputId = "countrySpecificListInput", label = "Countries",
                                   choices = sort(unique(countries_df$name)),
                                   selected = c("Argentina", "Chile", "South Africa", "Spain", "United States"), multiple = T)),
      
      #If a user has chosen to select specific cities, an option appears prompting the user to select cities
      conditionalPanel("input.plotInput == 'City Rankings' && input.citySpecificInput == 'Yes'",                 
                       selectInput(inputId = "citySpecificListInput", label = "Cities",
                                   choices = sort(unique(cities_countries$city_country)),
                                   selected = c("Buenos Aires, Argentina", "Johannesburg, South Africa", 
                                                "Madrid, Spain", "New York, United States", "Santiago, Chile"), multiple = T)),
      
      #If a user does not request specific cities or countries, either cities or countries can be selected based on their continent
      conditionalPanel("(input.plotInput == 'City Rankings' && input.citySpecificInput == 'No') |
                       (input.plotInput == 'Country Rankings' && input.countrySpecificInput == 'No')",
                       checkboxGroupInput(inputId = "continentInput", label = "Continents", choices = levels(cities_countries$continent),
                                          selected = levels(cities_countries$continent), inline = T)),
      
      #If a user has selected 'Country Rankings' for general countries, display a dynamic slidebar for which the maximum varies based on 
      #the number of countries available
      conditionalPanel("input.plotInput == 'Country Rankings' && input.countrySpecificInput == 'No'",
                       uiOutput(outputId = "countryLimitOutput")),
      
      #If a user has selected 'City Rankings' for general cities, display a dynamic slidebar for which the maximum varies based on 
      #the number of cities available
      conditionalPanel("input.plotInput == 'City Rankings' && input.citySpecificInput == 'No'",
                       uiOutput(outputId = "cityLimitOutput")),
      
      #If a user has selected 'Scatter Plot' display the options to be plotted on the x-Axis and the y-Axis
      conditionalPanel("input.plotInput == 'Scatter Plot'",                 
                       selectInput(inputId = "xAxisInput", label = "x-Axis Value",
                                   choices = happiness_liveability_choices,
                                   selected = "happiness_score", multiple = F),
                       selectInput(inputId = "yAxisInput", label = "y-Axis Value",
                                   choices = happiness_liveability_choices,
                                   selected = "liveability_score", multiple = F))
      
    )
  ),
  
  #Get screen height from Javascript function
  tags$script(jsScreenHeight)
)

#Build the Outputs
server = function(input, output, session) {
  
  #Using reactive() allows these reactive variables to be saved to memory. Computationally more efficient.

  #Reactive variable to control the height of country plots based on window height
  countryWindowHeight = reactive({
    if (countryLimit() <= 30) {
      paste0(input$windowHeightInput-50, "px")
    } else {
      paste0(input$windowHeightInput-50 + (30*(countryLimit() - 30)), "px")
    }
  })
  
  #Reactive variable to control the height of city plots based on window height
  cityWindowHeight = reactive({
    if (cityLimit() <= 30) {
      paste0(input$windowHeightInput - 50, "px")
    } else {
      paste0(input$windowHeightInput-50 + (30*(cityLimit() - 30)), "px")
    }
  })
  
  #Render city liveability select input
  output$mapCityMetricOutput = renderUI({
    selectInput(inputId = "mapCityMetricInput", label = "City Liveability Input",
                choices = liveability_choices,
                selected = "liveability_score", multiple = F)
  })
  
  #Reactive variable to control the country variable of interest for the map
  mapCountryMetric = reactive({
    if (is.null(input$mapCountryMetricInput)) {
      "happiness_score"
    } else {
      input$mapCountryMetricInput
    }
  })
  
  #Reactive variable to control the city variable of interest for the map
  mapCityMetric = reactive({
    if (is.null(input$mapCityMetricInput)) {
      "liveability_score"
    } else {
      input$mapCityMetricInput
    }
  })
  
  #Reactive variable to control the country variable of interest for bar plots
  countryMetric = reactive({
    input$countryMetricInput
  })
  
  #Reactive variable to control the city variable of interest for bar plots
  cityMetric = reactive({
    input$cityMetricInput
  })
  
  #Reactive variable to control which continents are selected
  continentSelected = reactive({
    input$continentInput
  })
  
  #Reactive variable to control leaflet annotation by country
  countryRankText = reactive({
    ifelse(!is.na(countries[[mapCountryMetric()]]),
           paste0("<b>", countries[['NAME']], "</b><br>", format_names(mapCountryMetric()), ": ", round(countries[[mapCountryMetric()]],2),
                  "<br>Rank: ", countries[[paste0(mapCountryMetric(), "_rank")]], "/", 
                  max(countries[[paste0(mapCountryMetric(), "_rank")]], na.rm = T)),
           paste0("<b>", countries[['NAME']], "</b><br>", "No Data"))
  })
  
  #Reactive variable to control leaflet annotation by city
  cityRankText = reactive({
    paste0("<b>", cities_countries[['city']], "</b><br>", format_names(mapCityMetric()), ": ",
           round(cities_countries[[mapCityMetric()]],2),
           "<br>Rank: ", cities_countries[[paste0(mapCityMetric(), "_rank")]], "/", 
           max(cities_countries[[paste0(mapCityMetric(), "_rank")]], na.rm = T))
  })
  
  #Reactive variable to control whether country plots are coloured/filled by continent or region
  countryColourVar = reactive({
    if (length(unique(filtered_country()$continent)) > 1) {
      "continent"
    } else {
      "region"
    }
  })
  
  #Reactive variable to control whether city plots are coloured/filled by continent or region
  cityColourVar = reactive({
    if (length(unique(filtered_city()$continent)) > 1) {
      "continent"
    } else {
      "region"
    }
  })
  
  #Reactive variable to control whether bar plots are displayed in ascending or descending order
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
  
  #Filter data based on the number of continents or regions required
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
      20
    } else {
      input$countryLimitInput
    }
  })
  
  #Dynamic UI element that controls the maximum number of countries that can be selected (based on the continents selected)
  output$countryLimitOutput = renderUI({ 
    sliderInput(inputId = "countryLimitInput", label = "Number of Countries",
                min = 5, max = nrow(pre_filtered_country()), value = isolate(countryLimit()), step = 1, round = T)
  })
  
  #Filter data based on the value of countryLimit and the order selected
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
  
  #Filter city data based on the number of continents or regions required
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
      20
    } else {
      input$cityLimitInput
    }
  })
  
  #Dynamic UI element that controls the maximum number of cities that can be selected (based on the continents selected)
  output$cityLimitOutput = renderUI({ 
    sliderInput(inputId = "cityLimitInput", label = "Number of Cities",
                min = 5, max = nrow(pre_filtered_city()), value = isolate(cityLimit()), step = 1, round = T)
  })
  
  #Filter data based on the value of cityLimit and the order selected
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
  
  #Reactive variable to control the x-Axis variable of the scatter plot
  xAxis = reactive({
    input$xAxisInput
  })
  
  #Reactive variable to control the y-Axis variable of the scatter plot
  yAxis = reactive({
    input$yAxisInput
  })
  
  #Create a new data frame to annotate the hline and vline on the scatter plot
  scatterLines = reactive({
    data.frame(name = c(format_names(xAxis()), format_names(yAxis())),
               x = c(mean(cities_countries[[xAxis()]], na.rm=T), min(cities_countries[[xAxis()]], na.rm=T)),
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
  
  #Add custom legend for circles
  addLegendCustom = function(map, position = "topright", title = "", colors, labels, sizes, layerId = NULL, opacity = 0.5){
    colorAdditions = paste0(colors, "; width:", sizes, "px; height:", sizes, "px")
    labelAdditions = paste0("<div style='display:inline-block; border-radius:50% !important; height:", sizes, "px; margin-top:4px; line-height:", sizes, "px;'>", labels, "</div>")
    
    return(addLegend(map, position = position, title = title, colors = colorAdditions, labels = labelAdditions, layerId = layerId, opacity = opacity, className = "info legend leaflet-control leafletLegendCircles"))
  }
  
  ###
  #Begin plots
  ###
  
  #Interactive Map
  output$leafletMap = renderLeaflet({
    
    leaflet(countries, options = list(maxZoom = 7)) %>%
      
      # addProviderTiles("MtbMap", options=tileOptions(minZoom=2, maxZoom=9)) %>%
      
      setView(0, 0, zoom = 2) %>%
      
      setMaxBounds(230, 95, -230, -73) %>%
      
      addPolygons(weight = 1,
                  color = "#000",
                  opacity = 0.2,
                  fillOpacity = 1,
                  fillColor = ~colorNumeric(c("darkred", "orangered", "orange", "yellow", "yellowgreen", "green"),
                                            countries$countries[[mapCountryMetric()]])(countries[[mapCountryMetric()]]),
                  popup=~countryRankText(),
                  label=~paste0(NAME),
                  labelOptions= labelOptions(direction = 'auto', className='leaflet-label-addition'),
                  
                  highlightOptions = highlightOptions(
                    color='#000000', opacity = 1, weight = 1, fillOpacity = 1,
                    bringToFront = F, sendToBack = T)) %>%
      
      addLegend("bottomleft", pal = colorNumeric(c("darkred", "orangered", "orange", "yellow", "yellowgreen", "green"),
                                                 countries[[mapCountryMetric()]]), values = ~countries[[mapCountryMetric()]],
                title = format_names(mapCountryMetric()), labFormat = labelFormat(suffix = ""), opacity = 0.8, na.label = "No Data")
    
  })
  
  #Add event for country metric change to replot circles on top of polygons
  observeEvent(mapCountryMetric(), {
    leafletProxy("leafletMap", session, deferUntilFlush = T) %>%
      
      clearGroup(group = "circles") %>%
      
      removeControl(layerId = "circleLegend") %>%
      
      addCircles(data = cities_countries, lng = ~lng, lat = ~lat, weight = 1, radius = ~(cities_countries[[mapCityMetric()]]) * 1000, 
                 color = "black",
                 fillColor = "black",
                 opacity = 0,
                 fillOpacity = 0.5,
                 popup=~cityRankText(),
                 label=~paste0(city_country),
                 labelOptions= labelOptions(direction = 'auto', className='leaflet-label-addition'),
                 highlightOptions = highlightOptions(
                   color='#000000', fillOpacity = 1,
                   bringToFront = T, sendToBack = F), 
                 group = "circles") %>%
      
      addLegendCustom(position = "bottomleft", title = format_names(mapCityMetric()), opacity = 0.7,
                      colors = c("black", "black", "black"),
                      labels = c(round(min(cities_countries[[mapCityMetric()]], na.rm=T), 0),
                                 round(mean(cities_countries[[mapCityMetric()]], na.rm=T), 0),
                                 round(max(cities_countries[[mapCityMetric()]], na.rm=T), 0)),
                      sizes = c(10, 15, 20),
                      layerId = "circleLegend")
  })
  
  #Add event for city metric change to replot circles
  observeEvent(mapCityMetric(), {
    
    leafletProxy("leafletMap", session, deferUntilFlush = T) %>%
      
      clearGroup(group = "circles") %>%
      
      removeControl(layerId = "circleLegend") %>%
      
      addCircles(data = cities_countries, lng = ~lng, lat = ~lat, weight = 1, radius = ~(cities_countries[[mapCityMetric()]]) * 1000, 
                 color = "black",
                 fillColor = "black",
                 opacity = 0,
                 fillOpacity = 0.5,
                 popup=~cityRankText(),
                 label=~paste0(city_country),
                 labelOptions= labelOptions(direction = 'auto', className='leaflet-label-addition'),
                 highlightOptions = highlightOptions(
                   color='#000000', fillOpacity = 1,
                   bringToFront = T, sendToBack = F), 
                 group = "circles") %>%
      
      addLegendCustom(position = "bottomleft", title = format_names(mapCityMetric()), opacity = 0.7,
                      colors = c("black", "black", "black"),
                      labels = c(round(min(cities_countries[[mapCityMetric()]], na.rm=T), 0),
                                 round(mean(cities_countries[[mapCityMetric()]], na.rm=T), 0),
                                 round(max(cities_countries[[mapCityMetric()]], na.rm=T), 0)),
                      sizes = c(10, 15, 20),
                      layerId = "circleLegend")
  })
  
  #Render the bar plot ranking for country when descending order is selected
   output$countryRankingPlotDesc = renderUI({
    plotOutput("countryRankingPlotDescContents", height = countryWindowHeight(), width = "100%")
  })
  output$countryRankingPlotDescContents = renderPlot({
    ggplot(filtered_country(), aes_string(paste0("reorder(", "name", ",", countryMetric(), ")"), countryMetric(), fill = countryColourVar())) +
      geom_bar(stat = "identity") +
      coord_flip() +
      ggplot_theme +
      labs(list(x = "Country", y = format_names(countryMetric()), title = paste(format_names(countryMetric()), "by Country", sep = " "))) +
      scale_fill_discrete(name = format_names(countryColourVar()))
  })
  
  #Render the bar plot ranking for country when ascending order is selected
  output$countryRankingPlotAsc = renderUI({
    plotOutput("countryRankingPlotAscContents", height = countryWindowHeight(), width = "100%")
  })
  output$countryRankingPlotAscContents = renderPlot({
    ggplot(filtered_country(), aes_string(paste0("reorder(", "name", ",-", countryMetric(), ")"), countryMetric(), fill = countryColourVar())) +
      geom_bar(stat = "identity") +
      coord_flip() +
      ggplot_theme +
      labs(list(x = "Country", y = format_names(countryMetric()), title = paste(format_names(countryMetric()), "by Country", sep = " "))) +
      scale_fill_discrete(name = format_names(countryColourVar()))
  })
  
  #Render the bar plot ranking for city when descending order is selected
  output$cityRankingPlotDesc = renderUI({
    plotOutput("cityRankingPlotDescContents", height = cityWindowHeight(), width = "100%")
  })
  output$cityRankingPlotDescContents = renderPlot({
    ggplot(filtered_city(), aes_string(paste0("reorder(", "city", "," ,cityMetric(), ")"), cityMetric(), fill = cityColourVar())) +
      geom_bar(stat = "identity") +
      coord_flip() +
      ggplot_theme +
      labs(list(x = "City", y = format_names(cityMetric()), title = paste(format_names(cityMetric()), "by City", sep = " "))) +
      scale_fill_discrete(name = format_names(cityColourVar()))
  })
  
  #Render the bar plot ranking for city when ascending order is selected
  output$cityRankingPlotAsc = renderUI({
    plotOutput("cityRankingPlotAscContents", width = "100%", height = cityWindowHeight())
  })
  output$cityRankingPlotAscContents = renderPlot({
    ggplot(filtered_city(), aes_string(paste0("reorder(", "city", ",-", cityMetric(), ")"), cityMetric(), fill = cityColourVar())) +
      geom_bar(stat = "identity") +
      coord_flip() +
      ggplot_theme +
      labs(list(x = "City", y = format_names(cityMetric()), title = paste(format_names(cityMetric()), "by City", sep = " "))) +
      scale_fill_discrete(name = format_names(cityColourVar()))
  })
  
  #Render the scatter plot
  set.seed(44)
  output$scatterPlot = renderPlotly({
    ggplotly(
      ggplot(na.omit(cities_countries), aes_string(x = xAxis(), y = yAxis())) +
        geom_jitter(height = 0.1, width = 0.1, alpha = 0.8, size = 2, aes_string(text = plotAnnotate(), col = "continent")) +
        geom_vline(xintercept = mean(cities_countries[[xAxis()]], na.rm = T), colour = "black",  linetype = "longdash", alpha = 0.5) +
        geom_hline(yintercept = mean(cities_countries[[yAxis()]], na.rm = T), colour = "black", linetype = "longdash", alpha = 0.5) +
        ggplot_theme +
        labs(list(x = format_names(xAxis(), city_country = T), y = format_names(yAxis(), city_country = T),
                  title = paste(format_names(yAxis()), "Against", format_names(xAxis()), sep = " "))) +
        scale_colour_brewer(name = "", palette = "Set1") +
        geom_point(data = scatterLines(), aes(x = x, y = y, text = paste("Average", name)), alpha = 0, size = 10),
      tooltip = "text") %>%
      
      #Custom legend
      layout(legend = list(orientation = "h", xanchor = "center", yanchor = "top", x = 0.5, y = -0.3),
             xaxis = list(fixedrange = T, titlefont = list(size = 16), tickfont = list(size = 14)),
             yaxis = list(fixedrange = T, titlefont = list(size = 16), tickfont = list(size = 14)),
             titlefont = list(size = 18)) %>%
      
      #Remove mode bar
      config(displayModeBar = F, showTips = F, sendData = F)
    
  })
}

shinyApp(ui = ui, server = server)