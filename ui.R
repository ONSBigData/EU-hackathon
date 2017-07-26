library(shiny)
library(scatterD3)
library(leaflet)

# Define UI using tabs 
shinyUI(fluidPage(
  tabsetPanel(id = 'tabs', type = 'pills', 
              # first tab contains map (leaflet) and its controls 
              tabPanel("Map overview for specific Occupation", value = 'activemap', 
                       bootstrapPage( tags$style(type = "text/css", "html, body {width:100%;height:100%}"), 
                                      leafletOutput("map", width = '100%', height = '900'), 
                                      absolutePanel(top = 50, right = 20, 
                                                    style = "padding: .8px; background: rgba(255, 255, 255, 0.8);", 
                                                    radioButtons("maplayer", label = "Select map layer:", inline = T, 
                                                                 choices = list("OSM" = 1, "Satellite (Esri)" = 2, "Positron" = 3), 
                                                                 selected = 3), 
                                                    radioButtons("tab1_nuts_level", label = "Regional level", 
                                                                 choices = list("NUTS level 1" =  1, "NUTS level 2" =  2), 
                                                                 selected = 1, inline = F), 
                                                    radioButtons("tab1_occup_level", label = "Occupation details", 
                                                                 choices = list("ESCO level 1" = 1, "ESCO level 2" =  2, "ESCO level 3" =  3), 
                                                                 selected = 1, inline = F), 
                                                    selectInput('tab1_occup_choice', label = "Select occupation", choices = c('All'), selected = 'All', multiple = FALSE, 
                                                                selectize = TRUE, width = NULL, size = NULL), 
                                                    radioButtons("tab1_datatypes", label = "Data source", 
                                                                 choices = list("Demand (CEDEFOP&EURES, per/pop)" = 1, "Supply (EURES&PIAAC, per/pop)" =  2, "Mismatch (Supply-demand, per/pop)" =  3), 
                                                                 selected = 3, inline = F)
                                      ))), 
              # second tab will display a figure (demand vs supply) for a chosen region
              tabPanel("Occupation supply-demand for specific Region", value = 'slopegraph', 
                       sidebarLayout(position = 'left', 
                                     sidebarPanel( width = 2,    
                                                   radioButtons("tab2_nuts_level", label = "Regional level", 
                                                                choices = list("Country_level" = 0, "NUTS level 1" =  1, "NUTS level 2" =  2), 
                                                                selected = 1, inline = F), 
                                                   radioButtons("tab2_occup_level", label = "Occupation details", 
                                                                choices = list("ESCO level 1" = 1, "ESCO level 2" =  2, "ESCO level 3" =  3), 
                                                                selected = 1, inline = F), 
                                                   textOutput("tab2_sampleAbout1"),   
                                                   br(), 
                                                   selectInput('tab2_nuts_choice', label = "Select region", choices = c('All'), selected = 'All', multiple = FALSE, 
                                                               selectize = TRUE, width = NULL, size = NULL)
                                     ), 
                                     mainPanel(width = 8, scatterD3Output("scatterPlot", height = "700px"))
                       )), 
              # third tab contain analysis of the training (in barcharts)
              tabPanel("Percentage of workers who have done training in past year, by occupation and country", value = 'karen', 
                       selectInput("select", label = "Select occupation group", 
                                   choices = list("Clerical support workers" = 1, 
                                                  "Craft and related trades workers" = 2, 
                                                  "Elementary occupations" = 3, 
                                                  "Managers" = 4, 
                                                  "Plant and machine operators, and assemblers" = 5, 
                                                  "Professionals" = 6, 
                                                  "Service and sales workers" = 7, 
                                                  "Skilled agricultural, forestry and fishery workers" = 8, 
                                                  "Technicians and associate professionals" = 9), 
                                   selected = "Managers"), 
                       
                       # Show a plot of the generated distribution
                       mainPanel(
                         plotOutput("barplot")
                       )), 
              # last panel includes describtion etc
              tabPanel("Description & disclaimer", value = 'karen', 
                       h3(textOutput("mockinfo")), 
                       h3("Comparing demand and supply of skills across the countries and regions of Europe"), 
                       h4("Description:"), 
                       textOutput("description"), 
                       h4("Datasets used:"), 
                       textOutput("datasets"), 
                       h4("Development tools and packages used (commercial or open source):"), 
                       textOutput("tools")  
              )
  )))