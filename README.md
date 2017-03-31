# EU Big Data Hackathon

## Overview

This visualiation explores the training that people in different countries and in different occupations have had over the previous year. The visualiation (a Shiny app) was created at the [EU Big Data Hackathon](http://ec.europa.eu/eurostat/cros/content/european-big-data-hackathon_en).

## How do I use this project?

### Requirements/Pre-requisites

The project was built using R Studio version 0.99.451. It requires packages:
- shiny
- ggplot2
- reshape2

### Data

Data from the [Programme for the International Assessment of Adult Competencies](http://www.oecd.org/skills/piaac/) was used. The data has been restructed as shown below:

```
{
  "Esco_Level_1": "Clerical support workers",
  "Esco_Level_2": "Customer services clerks",
  "REGION0": "CZ",
  "Esco_code": 1,
  "Popn": 74168.99,
  "formal": 8.413,
  "non-formal": 62.376,
  "on_job": 56.966
}
```

## Useful links

[EU Big Data Hackathon](http://ec.europa.eu/eurostat/cros/content/european-big-data-hackathon_en)
[Programme for the International Assessment of Adult Competencies](http://www.oecd.org/skills/piaac/)

## Contributors

[Karen Gask](https://github.com/gaskyk), working for the [Office for National Statistics Big Data project](https://www.ons.gov.uk/aboutus/whatwedo/programmesandprojects/theonsbigdataproject)