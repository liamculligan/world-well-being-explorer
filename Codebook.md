# Introduction
The aim of this project is to provide an open-source, user-friendly Shiny App to explore well-being throughout the world. Well-being at country-level is assessed using the concept
of happiness which is a measure by which social progress across countries can be compared. At city level, well-being is assessed using the concept of liveability, which is a measure by which the  living conditions of cities 
across the world can be compared. <br><br>

# Source Data
* The shapefile to produce the interactive map is provided by [Bjorn Sandvik](http://thematicmapping.org/downloads/TM_WORLD_BORDERS-0.3.zip) <br>
* The coordinates of cities were obtained from [Simplemaps](http://simplemaps.com/static/demos/resources/world-cities/world_cities.csv) <br>
* The 2016 World Happiness Report data was obtained from their [official website](http://worldhappiness.report/wp-content/uploads/sites/2/2016/03/Online-data-for-chapter-2-whr-2016.xlsx) <br>
* The Economist Intelligence Unit's Global Liveability Ranking for 2015 was obtained from [the Herald Sun](http://media.heraldsun.com.au/files/liveability.pdf)

# Modifications Made
Modifications made to the data are documented in the script `pre_process.R`. An overview of the changes made are as follows: <br>
* The variables "Whisker-high" and "Whisker-low" in the Happiness Report data are removed as the confidence intervals are not required for the Shiny app <br>
* Variable names have been standardised to allow for regular expression matching within `app.R` <br>
* City and country names have been standardised across the various data sets. This allows for the creation of common city-country keys so that cities and their countries can be matched <br>
* The following countries are not available in the shapefile and their happiness indicators are therefore not considered:
	* North Cyprus, Kosovo, Somaliland region, Palestinian Territories, South Sudan <br>
* Continents and regions, as defined by the World Bank Development Indicators, have been determined using the R package 'countrycode' <br>
* A rank for each variable considered has been calculated

#Variables

## Happiness
Simply put, six key variables, which have been broadly found in literature to be important in explaining differences in life evaluations at a national level, are used to calculate
the happiness score for a city on a scale of 0 to 10: <br>

| Variable                     | Description                                                                                                                                                                                                                                                                                                                                                 |
|------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| GDP per Capita               | The natural logarithm of Gross Domestic Product per Capita is measured in terms of Purchasing Power Parity adjusted to constant 2011 international dollars, according to the World Development Indicators released by the World Bank in December 2015.                                                                                                      |
| Social Support               | The national average response to the Gallup World Poll (GWP) question "If you were in trouble, do you have relatives or friends you can count on to help you whenever you need them, or not?”                                                                                                                                                              |
| Healthy Life Expectancy      | The time series of healthy life expectancy at birth constructed from data from the World Health Organisation and the World Development Indicators. First, ratios of healthy life expectancy to life expectancy in 2012 are determined using both sources. Then, the country-specific ratios are applied to other years to generate healthy life expectancy. |
| Freedom to Make Life Choices | The national average of binary responses to the GWP question “Are you satisfied or dissatisfied with your freedom to choose what you do with your life?”                                                                                                                                                                                                    |
| Generosity                   | The residual of regressing the national average of GWP responses to the question, “Have you donated money to a charity in the past month?” on GDP per capita.                                                                                                                                                                                               |
| Perceptions of Corruption    | The average of binary responses to two GWP questions: <br> 1) “Is corruption widespread throughout the,government or not” <br> 2) “Is corruption widespread within businesses or not?” <br> If data for government corruption is missing, the perception of business corruption is used as the overall corruption-perception measure.                                  |

## Liveability
The liveability score for a city is calculated using category weights, which themselves are divided into equally weighted subcategories to ensure that the score covers as many
indicators as possible. Indicators are scored as acceptable, tolerable, uncomfortable, undesirable or intolerable. These are then weighted to produce a rating, where 100 means that 
liveability in a city is ideal and 1 means that it is intolerable.
For qualitative variables, an “Economist Intelligence Unit rating” (EIU rating) is awarded based on the judgment of in–house expert country analysts and a field correspondent 
based in each city. For quantitative variables, a rating is calculated based on the relative performance of a location using external data sources.

### Liveability Score

| Category                  | Weight (%) |
|---------------------------|------------|
| Stability                 | 25         |
| Healthcare                | 20         |
| Culture and Environment   | 25         |
| Education                 | 10         |
| Infrastructure            | 20         |

### Category: Stability
| Indicator                       | Source     |
|---------------------------------|------------|
| Prevalence of petty crime       | EIU rating |
| Prevalence of violent crime     | EIU rating |
| Threat of terror                | EIU rating |
| Threat of military conflict     | EIU rating |
| Threat of civil unrest/conflict | EIU rating |

### Category: Healthcare
| Indicator                              | Source                      |
|----------------------------------------|-----------------------------|
| Availability of private healthcare     | EIU rating                  |
| Quality of private healthcare          | EIU rating                  |
| Availability of public healthcare      | EIU rating                  |
| Quality of public healthcare           | EIU rating                  |
| Availability of over-the-counter drugs | EIU rating                  |
| General healthcare indicators          | Adopted from the World Bank |

### Category: Culture and Environment
| Indicator                           | Source                                    |
|-------------------------------------|-------------------------------------------|
| Humidity/temperature rating         | Adapted from average weather conditions   |
| Discomfort of climate to travellers | EIU rating                                |
| Level of corruption                 | Adapted from Transparency International   |
| Social or religious restrictions    | EIU rating                                |
| Level of censorship                 | EIU rating                                |
| Sporting availability               | EIU field rating of 3 sport indicators    |
| Cultural availability               | EIU field rating of 4 cultural indicators |
| Food and drink                      | EIU field rating of 4 cultural indicators |
| Consumer goods and services         | EIU rating of product availability        |

### Category: Education
| Indicator                         | Source                      |
|-----------------------------------|-----------------------------|
| Availability of private education | EIU rating                  |
| Quality of private education      | EIU rating                  |
| Public education indicators       | Adapted from the World Bank |

### Category: Infrastructure
| Indicator                            | Source     |
|--------------------------------------|------------|
| Quality of road network              | EIU rating |
| Quality of public transport          | EIU rating |
| Quality of international links       | EIU rating |
| Availability of good quality housing | EIU rating |
| Quality of energy provision          | EIU rating |
| Quality of water provision           | EIU rating |
| Quality of telecommunications        | EIU rating |
