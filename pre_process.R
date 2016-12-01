#World Well-being Explorer

#Data pre-processing

#Authors: Tyrone Cragg and Liam Culligan

#Date: November 2016

#Install the required packages for the app
packages_required = c("rgdal", "data.table", "countrycode", "readxl", "dplyr", "dtplyr", "leaflet", "ggplot2",
                      "RColorBrewer", "plotly", "lazyeval", "shiny")
new_packages = packages_required[!(packages_required %in% installed.packages()[,"Package"])]
if(length(new_packages) > 0) {
  install.packages(new_packages)
}

#Load required packages
library(rgdal)
library(data.table)
library(countrycode)
library(readxl)
library(dplyr)
library(dtplyr)
library(ggplot2)

#Download a shapefile of the world provided by Bjorn Sandvik, thematicmapping.org
fileUrl = "http://thematicmapping.org/downloads/TM_WORLD_BORDERS-0.3.zip"
download.file(fileUrl, dest="world_shapefile.zip", mode="wb") 
unzip("world_shapefile.zip")

#Read in the shape file as a Large SpatialPolygonsDataFrame
country_borders = readOGR("TM_WORLD_BORDERS-0.3.shp", layer = "TM_WORLD_BORDERS-0.3", verbose = FALSE)

#Fix the name of the Aland islands (factor)
country_borders$NAME = gsub("Ã…land Islands", "Aland Islands", country_borders$NAME)

#Add continent as defined by the World Bank Development Indicators
country_borders$continent = countrycode(country_borders$ISO3, "iso3c", "continent")
#Add region as defined by the World Bank Development Indicators
country_borders$region = countrycode(country_borders$ISO3, "iso3c", "region")

#Taiwan has not been assigned a continent and region - fix this manually
country_borders$continent[country_borders$NAME == "Taiwan"] = "Asia"
country_borders$region[country_borders$NAME == "Taiwan"] = "Eastern Asia"

#Read in the Economist Intelligence Unit's Global Liveability Rankings for August 2015
#Source: The Herald Sun (http://media.heraldsun.com.au/files/liveability.pdf) - publicly avaialable document
#Manually reproduced this data as a CSV. Chosen not to provide the CSV due to potential licensing issue.
city_data = fread("economist_liveability_2015.csv")

#Clean the column names
names(city_data) = gsub(" ", "_", names(city_data))
names(city_data) = gsub("&", "and", names(city_data))
names(city_data) = tolower(names(city_data))
names(city_data)[!names(city_data) %in% c("country", "city")] =
  paste("liveability", names(city_data)[!names(city_data) %in% c("country", "city")], sep = "_")

#Rename liveability_overall_rating column
setnames(city_data, "liveability_overall_rating", "liveability_score")

#Change the name of Bahrain (city) to Manama
city_data[, city := gsub("Bahrain", "Manama", city)]

#Change the name of Luxembourg (city) to Luxembourg City
city_data[, city := gsub("Luxembourg", "Luxembourg City", city)]

#Download world city longitude/latitude data from simplemaps.com
fileUrl = "http://simplemaps.com/static/demos/resources/world-cities/world_cities.csv"
download.file(fileUrl, destfile = "city_location.csv", mode = 'wb')

#Read in city locations
city_location = fread("city_location.csv", encoding = "UTF-8")

#Need to fix the name of the capital of Kuwait
city_location[, city := gsub("Kuwait", "Kuwait City", city)]
city_location[, city_ascii := gsub("Kuwait", "Kuwait City", city_ascii)]

#Need to fix the name of the capital of Guatemala
city_location[, city := gsub("^Guatemala$", "Guatemala City", city)]
city_location[, city_ascii := gsub("^Guatemala$", "Guatemala City", city_ascii)]

#Need to fix the name of the capital of Luxembourg
city_location[, city := gsub("^Luxembourg$", "Luxembourg City", city)]
city_location[, city_ascii := gsub("^Luxembourg$", "Luxembourg City", city_ascii)]

#Standardise the name of the United States of America
city_location = city_location[, country := gsub("United States of America", "US", country)]

#A city named Suzhou is in 2 Chineese provinces. Remove the city in Anhui province as this is not the city referred to by the Economist
city_location = city_location %>%
  filter(city != "Suzhou" | province != "Anhui")

#Create variable to merge on - combine city and country so that cities with the same name in different countries are not matched later
city_data[, city_country := tolower(paste(city, country, sep = ", "))]
city_location[, city_country := tolower(paste(city_ascii, country, sep = ", "))]

#Find city names that do not match
setdiff(city_data$city_country, city_location$city_country)

#Edit the names of city_country in city_location so that they match
city_location[, city_country := gsub("kobenhavn", "copenhagen", city_country)]
city_location[, city_country := gsub("montréal", "montreal", city_country)]
city_location[, city_country := gsub("hong kong s\\.a\\.r\\.", "hong kong", city_country)]
city_location[, city_country := gsub("st\\.", "st", city_country)]
city_location[, city_country := gsub(",d\\.c\\.", "dc", city_country)]
city_location[, city_country := gsub("washington, d.c., us", "washington dc, us", city_country)]
city_location[, city_country := gsub("united kingdom", "uk", city_country)]
city_location[, city_country := gsub("czech republic", "czech rep", city_country)]
city_location[, city_country := gsub("united arab emirates", "uae", city_country)]
city_location[, city_country := gsub("tel aviv-yafo", "tel aviv", city_country)]

#Some names in city_country should rather be edited
city_data[, city_country := gsub("nouméa", "noumea", city_country)]
city_data[, city_country := gsub("côte d'ivoire", "ivory coast", city_country)]
city_data[, city_country := gsub("png$", "papua new guinea", city_country)]

#Check that all names match now
setdiff(city_data$city_country, city_location$city_country)

#Al Khobar is missing - do not have its coordinates
#Add Al Khobar to city_location - data obtained from http://e-amana.gov.sa/
row = data.table("Al Khobar", "Al Khobar", 26.2172, 50.1971, 941358, "Saudi Arabia", "SA", "SAU", "Ash Sharqiyah", "al khobar, saudi arabia")
names(row) = names(city_location)
city_location = rbind(city_location, row)

#Remove unneccesary columns from city_location
city_location[, ':=' (city = NULL,
                      city_ascii = NULL,
                      country = NULL,
                      pop = NULL,
                      iso2 = NULL,
                      iso3 = NULL,
                      province = NULL)]

#Set appropriate keys prior to joining
setkey(city_data, city_country)
setkey(city_location, city_country)

#Left outer join city_data on city_location
cities = city_location[city_data]

#Download the 2016 World Happiness Report
fileUrl = "http://worldhappiness.report/wp-content/uploads/sites/2/2016/03/Online-data-for-chapter-2-whr-2016.xlsx"
download.file(fileUrl, dest="world_happiness_report.xlsx", mode="wb") 

#Read in the required Excel sheet of the World Happiness Report
country_happiness = read_excel("world_happiness_report.xlsx", sheet = "Figure2.2")

#Remove last two columns
country_happiness[, (ncol(country_happiness) -1): ncol(country_happiness)] = NULL

#Clean column names
#Remove everything before and including ": "
names(country_happiness) = gsub(".*: ", "", names(country_happiness))

#Replace - in column names with _
names(country_happiness) = gsub("-", "_", names(country_happiness))

#Replace whitespace with _
names(country_happiness) = gsub(" ", "_", names(country_happiness))

#Convert names to lowercase
names(country_happiness) = tolower(names(country_happiness))

#Remove the columns Whisker_high and Whisker_low
country_happiness$whisker_high = NULL
country_happiness$whisker_low = NULL

#Prepend happiness_ to relevant columns
names(country_happiness)[!names(country_happiness) %in% c("country", "happiness_score")] =
  paste("happiness", names(country_happiness)[!names(country_happiness) %in% c("country", "happiness_score")], sep = "_")

#Find which countries in country_happiness don't match those in country_borders
setdiff(country_happiness$country, country_borders$NAME)

#Change names in country_border
country_borders$NAME = gsub("Republic of Moldova", "Moldova", country_borders$NAME)
country_borders$NAME = gsub("Korea, Democratic People's Republic of", "North Korea", country_borders$NAME)
country_borders$NAME = gsub("Korea, Republic of", "South Korea", country_borders$NAME)
country_borders$NAME = gsub("Libyan Arab Jamahiriya", "Libya", country_borders$NAME)
country_borders$NAME = gsub("The former Yugoslav Republic of Macedonia", "Macedonia", country_borders$NAME)
country_borders$NAME = gsub("Viet Nam", "Vietnam", country_borders$NAME)
country_borders$NAME = gsub("Lao People's Democratic Republic", "Laos", country_borders$NAME)
country_borders$NAME = gsub("Iran \\(Islamic Republic of\\)", "Iran", country_borders$NAME)
country_borders$NAME = gsub("Burma", "Myanmar", country_borders$NAME)
country_borders$NAME = gsub("^Congo$", "Republic of the Congo", country_borders$NAME)
country_borders$NAME = gsub("Cote d'Ivoire", "Ivory Coast", country_borders$NAME)
country_borders$NAME = gsub("United Republic of Tanzania", "Tanzania", country_borders$NAME)
country_borders$NAME = gsub("Syrian Arab Republic", "Syria", country_borders$NAME)

#Change names in country_happiness
country_happiness$country = gsub("Congo \\(Brazzaville\\)", "Republic of the Congo", country_happiness$country)
country_happiness$country = gsub("Congo \\(Kinshasa\\)", "Democratic Republic of the Congo", country_happiness$country)

#The following countries are not available in the shapefile and will not be considered:
#North Cyprus, Kosovo, Somaliland region, Palestinian Territories, South Sudan 
setdiff(country_happiness$country, country_borders$NAME)

#Left outer join country_borders on city_location which creatse a Large SpatialPolygonsDataFrame
countries = merge(country_borders, country_happiness, by.x = "NAME", by.y = "country", all.x = T, all.y = F)

#Save another version of countries, countries_df - ggplot2 requires a data frame (not a Large SpatialPolygonsDataFrame)
countries_df = na.omit(data.frame(name = countries$NAME, continent = countries$continent, region = countries$region,
                                  happiness_score = countries$happiness_score,
                                  happiness_gdp_per_capita = countries$happiness_gdp_per_capita, 
                                  happiness_social_support = countries$happiness_social_support, 
                                  happiness_healthy_life_expectancy = countries$happiness_healthy_life_expectancy, 
                                  happiness_freedom_to_make_life_choices = countries$happiness_freedom_to_make_life_choices, 
                                  happiness_generosity = countries$happiness_generosity,
                                  happiness_perceptions_of_corruption = countries$happiness_perceptions_of_corruption))

#Update country names in cities to create common key
cities[, country := gsub("^US$", "United States", country)]
cities[, country := gsub("^UK$", "United Kingdom", country)]
cities[, country := gsub("Czech Rep", "Czech Republic", country)]
cities[, country := gsub("^UAE$", "United Arab Emirates", country)]
cities[, country := gsub("^Brunei$", "Brunei Darussalam", country)]
cities[, country := gsub("Côte d'Ivoire", "Ivory Coast", country)]
cities[, country := gsub("^PNG$", "Papua New Guinea", country)]

#Merge cities and countries to create a combined data set
cities_countries = merge(cities, countries, by.x = "country", by.y = "NAME", all.x = F, all.y = F)

#Remove unnecessary columns
cities_countries$city_country = 
  cities_countries$FIPS = cities_countries$ISO2 = cities_countries$ISO3 = cities_countries$UN = 
  cities_countries$AREA = cities_countries$POP2005 = cities_countries$REGION = cities_countries$SUBREGION = 
  cities_countries$LON = cities_countries$LAT = NULL 

#Add city_country variable to cities_countries
cities_countries$city_country = paste(cities_countries$city, cities_countries$country, sep = ", ")

#Rename liveabilty_rank so that it has the same style as other variables - needed for regular expression matching in the Shiny App
setnames(cities_countries, "liveability_rank", "liveability_score_rank")

#Create new variables that rank the various liveability variables
cities_countries[, liveability_stability_rank := rank(1/liveability_stability, ties.method = "min")]

cities_countries[, liveability_healthcare_rank := rank(1/liveability_healthcare, ties.method = "min")]

cities_countries[, liveability_culture_and_environment_rank := rank(1/liveability_culture_and_environment, ties.method = "min")]

cities_countries[, liveability_education_rank := rank(1/liveability_education, ties.method = "min")]

cities_countries[, liveability_infrastructure_rank := rank(1/liveability_infrastructure, ties.method = "min")]


#Create new variables that rank the various happiness variables
countries$happiness_score_rank = rank(1/countries$happiness_score, ties.method = "min")
countries$happiness_score_rank  = ifelse(is.na(countries$happiness_score), NA, countries$happiness_score_rank)

countries$happiness_gdp_per_capita_rank = rank(1/countries$happiness_gdp_per_capita, ties.method = "min")
countries$happiness_gdp_per_capita_rank  = ifelse(is.na(countries$happiness_gdp_per_capita), NA, countries$happiness_gdp_per_capita_rank)

countries$happiness_social_support_rank = rank(1/countries$happiness_social_support, ties.method = "min")
countries$happiness_social_support_rank  = ifelse(is.na(countries$happiness_social_support), NA, countries$happiness_social_support_rank)

countries$happiness_healthy_life_expectancy_rank = rank(1/countries$happiness_healthy_life_expectancy, ties.method = "min")
countries$happiness_healthy_life_expectancy_rank  = ifelse(is.na(countries$happiness_healthy_life_expectancy),
                                                           NA, countries$happiness_healthy_life_expectancy_rank)

countries$happiness_freedom_to_make_life_choices_rank = rank(1/countries$happiness_freedom_to_make_life_choices, ties.method = "min")
countries$happiness_freedom_to_make_life_choices_rank  = ifelse(is.na(countries$happiness_freedom_to_make_life_choices),
                                                                NA, countries$happiness_freedom_to_make_life_choices_rank)

countries$happiness_generosity_rank = rank(1/countries$happiness_generosity, ties.method = "min")
countries$happiness_generosity_rank  = ifelse(is.na(countries$happiness_generosity), NA, countries$happiness_generosity_rank)

countries$happiness_perceptions_of_corruption_rank = rank(1/countries$happiness_perceptions_of_corruption, ties.method = "min")
countries$happiness_perceptions_of_corruption_rank  = ifelse(is.na(countries$happiness_perceptions_of_corruption),
                                                             NA, countries$happiness_perceptions_of_corruption_rank)


###

#Convert continent and region to factors
cities_countries$continent = as.factor(cities_countries$continent)
cities_countries$region = as.factor(cities_countries$region)

#Function to tidy variable names and make them presentable in the UI
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

#Dropdown list options for country metrics
happiness_choices = as.list(names(countries_df)[grepl("happiness", names(countries_df))])
names(happiness_choices) = sapply(happiness_choices, format_names)

#Dropdown list options for city metrics
liveability_choices = as.list(names(cities_countries)[grepl("liveability", names(cities_countries)) & 
                                                        !grepl("rank", names(cities_countries))])
names(liveability_choices) = sapply(liveability_choices, format_names)

#Dropdown list options for country metrics (formatted)
happiness_choices_city_country = as.list(names(countries_df)[grepl("happiness", names(countries_df))])
names(happiness_choices_city_country) = sapply(happiness_choices_city_country, format_names, city_country = T)

#Dropdown list options for city metrics (formatted)
liveability_choices_city_country = as.list(names(cities_countries)[grepl("liveability", names(cities_countries)) & 
                                                                     !grepl("rank", names(cities_countries))])
names(liveability_choices_city_country) = sapply(liveability_choices_city_country, format_names, city_country = T)

#Dropdown list options for combined metrics
happiness_liveability_choices = as.list(c(names(cities_countries)[grepl("happiness", names(cities_countries)) &
                                                                    !grepl("rank", names(cities_countries))],
                                          names(cities_countries)[grepl("liveability", names(cities_countries)) &
                                                                    !grepl("rank", names(cities_countries))]))
names(happiness_liveability_choices) = sapply(happiness_liveability_choices, format_names, city_country = T)

#Set theme for ggplot2
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
ggplot_theme = theme(
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
  strip.background = element_rect()
)

#Save the required R Objects as RData
save(list = c("cities_countries", "countries", "countries_df", "happiness_choices", "happiness_choices_city_country",
              "happiness_liveability_choices", "liveability_choices", "liveability_choices_city_country",
              "themes_data", "ggplot_theme", "format_names"), file = "pre_process.RData")
