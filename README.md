# citytemp

[![shiny-deploy](https://github.com/UBC-MDS/citytemp/actions/workflows/deploy-app.yaml/badge.svg)](https://github.com/UBC-MDS/citytemp/actions/workflows/deploy-app.yaml) [![Test app w/ {renv}](https://github.com/UBC-MDS/citytemp/actions/workflows/testing.yaml/badge.svg)](https://github.com/UBC-MDS/citytemp/actions/workflows/testing.yaml)


Welcome! Thank you for visiting the citytemp project repository.

If you're an avid traveller and you want to be prepared for the weather conditions at your next US destination, our app is for you! 

[Link to the citytemp app](https://eyrexh.shinyapps.io/citytemp/)

To learn more about the app, you can jump to one of the sections below or keep scrolling.

* [Purpose and Motivation](#purpose-and-motivation)
* [Preview and Description](#dashboard-preview-and-description)
* [Installation](#installation)
* [Meet the Team](#meet-the-team)
* [Contributing](#contributing)
* [Support](#support)
* [Code of Conduct](#code-of-conduct)
* [License](#license)

## Purpose and Motivation

Being unprepared for certain weather conditions can make or break a trip. Our motivation with `citytemp` was to create a reliable tool that US travelers can use to make informed decisions on which areas to visit and plan activities accordingly during their travels. Our app uses real historical data to assist travel enthusiasts in understanding weather fluctuations, temperatures, and precipitation levels across various states/cities in the United States and enables them to plan well for their upcoming trips to avoid weather disruptions and unwanted surprises.

## Dashboard Preview and Description

<img src='img/m4demo.gif' width="1000" height="500">

Our dashboard is presents observed temperature and precipitation data from the [weather_forcasts.csv](https://github.com/rfordatascience/tidytuesday/blob/master/data/2022/2022-12-20/weather_forecasts.csv) in tidytuesday. 

The `citytemp` app contains two tabs: 

In the `City Map with Temp/Rain Trends` tab, users specify the range of months of their interest (eg. 1 to 6 for January to June), the city and state of their interest (eg. TX, Austin), and whether they would like to observe temperature levels or precipitation levels. Users also have the option to observe temperature levels in degrees Celsius (ºC) or Fahrenheit (ºF).

Based on these user selections, our app presents the following:

  - Summary metrics including average, minimum, and maximum temperature/precipitation. 
  - A map showing the average temperature or precipitation levels based on the range chosen by the user. City points are coloured from low to high temperature or precipitation levels. 
  - A line plot showing the distribution of low and high observed temperatures and precipitation levels. 

In the `City Ranking by Temp/Rain` tab, users select the US state of their interest, the month they would like to observe data for, and whether they would like to observe high or low temperature/precipitation records. Based on these selections, our app presents bar graphs for the cities in their specified state ranked by highest or lowest average monthly temperature/precipitation.

## Installation

To install `citytemp` locally, you can:

1. Clone this repository.
2. Run the following command in your R console to install the required libraries locally:

```{r}
install.packages(c('dplyr', 'plotly', 'ggplot2', 'leaflet', 'geosphere', 'leaflet.extras', 'sf', 'shinydashboard', 'shinycssloaders'))
```

3. Finally, run the following command to run the app locally!

```{r}
RScript app.R
```

## Meet The Team

The creators of `citytemp` are students of the MDS Program at the University of British Columbia. This project was created for the DSCI 532 (Data Visualization II) course. 

* [Eyre Hong](https://github.com/eyrexh)
* [Renee Kwon](https://github.com/renee-kwon)
* [Sneha Sunil](https://github.com/snesunil)
* [Vincent Ho](https://github.com/vincentho32)

# Contributing

Feedback and suggestions are always welcome! 

Please read [the contributing guidelines](https://github.com/UBC-MDS/citytemp/blob/main/CONTRIBUTING.md)
to get started.

## Support

If you run into trouble, please [check the issue
list](https://github.com/UBC-MDS/citytemp/issues) to see
if your problem has already been reported or to open new issues.

## Code of conduct

In the interest of fostering an open and welcoming environment, we as contributors and maintainers pledge to make participation in our project and our community a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation. Detailed descriptions
of these points can be found in [`CODE_OF_CONDUCT.md`](https://github.com/UBC-MDS/citytemp/blob/main/CODE_OF_CONDUCT.md).

## License
The citytemp Dashboard is licensed under the terms of the MIT license.
