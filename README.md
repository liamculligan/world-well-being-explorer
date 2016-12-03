# World Well-being Explorer
Shiny App: An open-source, user-friendly interface to explore well-being throughout the world <br>
[www.worldwellbeingexplorer.com](www.worldwellbeingexplorer.com){:target="_blank"}

## Introduction
The aim of this project to provide an open-source, user-friendly Shiny App to explore well-being throughout the world. Well-being at country-level is assessed using the concept
of happiness which is a measure by which social progress across countries can be compared. This data is sourced from the [2016 World Happiness Report](http://worldhappiness.report/)
produced by the United Nations Sustainable Development Solutions Network. At city level, well-being is assessed using the concept of liveability, which is a measure by which the 
living conditions of cities across the world can be compared. This data is sourced from the [Global Liveability Ranking 2015](http://www.eiu.com/liveability2015) produced by
the Economist Economic Intelligence Unit.

## Collaborators
This project is a collaboration between [Tyrone Cragg]() and [Liam Culligan](https://www.linkedin.com/in/liam-culligan-81156b11b?trk=hp-identity-name).

## Execution
1. Create a working directory for the project 
2. Download all files in the repository and place in the working directory
3. Download the Economist Intelligence Unit's Global Liveability Rankings for August 2015 available at [The Herald Sun](http://media.heraldsun.com.au/files/liveability.pdf). <br>
*This data has not been provided in this repository due to potential licensing issues*
4. Run the script `pre_process.R` to download the other data required and pre-process the data obtained
5. Run the script `app.R` to launch the Shiny App locally

## Requirements
* R 3+
* Shiny 0.10.2 +

## TO DO
Work in progress
