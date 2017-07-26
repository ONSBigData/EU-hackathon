# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

# for package versions, see the session info attached to the end of this script
library(shiny)
library(dplyr)
library(ggplot2)
library(geojsonio)
library(leaflet)
library(RColorBrewer)
library(scatterD3)
library(htmltools)
library(reshape2)

##################################
## Read in data (using synthetic data already saved in R format)
MOCK <- T
if (MOCK) load("hack02-synthetic.RData") # else ...

##################################
## Define list of possible values for regions and occupations
REGIONS <- list('0' = c('All', sort(unique(aggr$REGION0))), '1' = c('All', sort(unique(aggr$REGION1))), '2' = c('All', sort(unique(aggr$REGION2))))
ESCO <- list('1' = c('All', sort(setdiff(unique(aggr$Esco_Level_1), c('Not specified', 'NULL')))), 
             '2' = c('All', sort(setdiff(unique(aggr$Esco_Level_2), c('Not specified', 'NULL')))), 
             '3' = c('All', sort(setdiff(unique(aggr$Esco_Level_3), c('Not specified', 'NULL')))))

##################################
shinyServer(function(input, output, session) {

  observe({ 
    # update the occupation according to user choice
    x <- ESCO[[input$tab1_occup_level]]
    updateSelectInput(session, 'tab1_occup_choice', 
                      choices = x, selected = 'All')
  })
  
  observe({ 
    # update the region according to user choice
    x <- REGIONS[[input$tab2_nuts_level]]
    updateSelectInput(session, 'tab2_nuts_choice', 
                      choices = x, 
                      selected = 'All')
  })
  
  output$map <- renderLeaflet({
    # Initialize leaflet with aspects of the map that won't need to change dynamically 
    leaflet() %>% 
      setView(lng = 8.5, lat = 51.5, zoom = 5) %>% 
      #addTiles() %>% 
      addProviderTiles('CartoDB.Positron') 
  })
  
  observe({
    # update the map according to user choices 
    # choose the right level of regional and occupational classification
    reg <- if (input$tab1_nuts_level == '2') 2 else 1
    shape <- if (reg == 2) shape_lvl2 else shape_lvl1
    occ <- as.numeric(input$tab1_occup_level) 
    occu  <- input$tab1_occup_choice
    data <-  aggr[, c(reg+1, occ+3, 7:9) ] %>% ungroup()
    names(data) <-  c('REGION', 'ESCO', 'ft_count', 'jv_count', 'cv_count')
    # choose the correct variable to display (i.e. supply, demand or diff) and scale if necessary
    if (occu != 'All') data <- data %>% filter(`ESCO` ==  occu)
    data <- data %>% group_by(REGION) %>% summarise(ft_count = sum(ft_count), jv_count = sum(jv_count), cv_count = sum(cv_count) ) 
    if (input$tab1_datatypes == 1) data <- data %>% mutate(value = (2*jv_count+ft_count)*10) 
    else if (input$tab1_datatypes == 2) data <- data %>% mutate(value = cv_count*200) 
    else data <- data %>% mutate(value = (10*cv_count-2*jv_count-ft_count)*10) 
    #print(head(data))
    # add the chosen variable to shape file (to be used for color of the choropleth)
    shape@data <- left_join(shape@data, data, by = c('NUTS_ID' = 'REGION'))
    shape@data$value[is.na(shape@data$value)&(substr(shape@data$NUTS_ID, 1, 2) %in% c('CZ', 'IE', 'DE', 'IT', 'UK'))] <- 0
    shape@data$value <- shape@data$value/shape@data$population
    #print(head(shape@data %>% filter(substr(NUTS_ID, 1, 2) %in% c('CZ', 'IE', 'DE', 'IT', 'UK'))))
    
    # adjust colour scheme
    if (input$tab1_datatypes == 1)
    pal <- colorBin("YlOrRd", domain = shape@data$value, bins = 7)
    else if (input$tab1_datatypes == 2) 
      pal <- colorBin("Blues", domain = shape@data$value, bins = 7)
      else pal <- colorBin("RdYlBu", domain = union(shape@data$value, -shape@data$value), bins = 7)
    
    # display new choropleth
    leafletProxy("map") %>% clearShapes() %>% 
      addPolygons(data = shape, 
        fillColor = ~pal(value),    
        weight = 2, 
        opacity = 1, 
        color = "white", 
        dashArray = "3", 
        fillOpacity = 0.7, 
        label = ~htmlEscape(NUTS_ID), 
    highlight = highlightOptions(
      weight = 5, 
      color = "#666", 
      dashArray = "", 
      fillOpacity = 0.7, 
      bringToFront = TRUE), 
    # label = labels, 
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"), 
      textsize = "15px", 
      direction = "auto")) %>% 
    clearControls() %>%
    addLegend( pal = pal, values =  shape@data$value, opacity = 0.7, title = NULL, 
              position = "bottomright")
  })
  
  observe({
    # adjust the underlying map according to user's choice
    mapstr <- c('', "Esri.WorldImagery", 'CartoDB.Positron')[as.numeric(input$maplayer)]
    if (mapstr == '')
      leafletProxy("map") %>%  clearTiles() %>% 
      addTiles()
    else 
      leafletProxy("map") %>%  clearTiles() %>% 
      addProviderTiles(mapstr)
  })
  
  output$scatterPlot <- renderScatterD3({
    # scatterplot of demand vs supply for a chosen region
    reg <- as.numeric (input$tab2_nuts_level)
    occ <- as.numeric(input$tab2_occup_level) 
    region  <- input$tab2_nuts_choice
    data <-  aggr[, c(reg+1, occ+3, 7:9) ] %>% ungroup()
    names(data) <-  c('REGION', 'ESCO', 'ft_count', 'jv_count', 'cv_count')
    if (region != 'All') data <- data %>% filter(REGION == region)
    data <- data %>% group_by(ESCO) %>% summarise(ft_count = sum(ft_count), jv_count = sum(jv_count), cv_count = sum(cv_count)) 
    data <- data %>% mutate(job_vacancies = 2*jv_count+ft_count,  supply  = cv_count) %>% filter(!is.null(ESCO) & (ESCO != 'NULL')) 
    
    scatterD3(x = data$supply, 
              y = data$job_vacancies, 
              lab = data$ESCO)
  })
  
  output$value <- renderPrint({ input$select })
  
  output$barplot <- renderPlot({
    # display barchart of training by occupation and country
    
    ## Ignore popn then melt
    piaac$Popn <- NULL
    melted <- melt(piaac, id.vars = c("Esco_Level_1", "Esco_Level_2", "REGION0", "Esco_code"))
    colnames(melted) <- c("Esco_Level_1", "Esco_Level_2", "REGION0", "Esco_code", "Training", "Value")
    
    ## Make training types look pretty
    melted$Training <- gsub("non.formal", "non-formal", melted$Training, fixed = TRUE)
    melted$Training <- gsub("on_job", "on the job", melted$Training, fixed = TRUE)
    
    ## Convert input$select from ui selection to be used here
    value <- as.numeric(input$select)
    melted_selected <- subset(melted, Esco_code == value)
    
    ## Plot
    ggplot(data = melted_selected, aes(x = Esco_Level_2, y = Value, group = Training, colour = Training)) +
      geom_bar(aes(fill = Training), position = "dodge", stat = "identity") +
      coord_flip() +
      labs(x = "Occupation", y = "Percentage")+
      facet_grid(.~REGION0)+
      theme_minimal()
    
  }, height = 600, width = 1200)
  
  output$mockinfo <- renderText({
  if (MOCK) "THIS VERSION OF THE VISUALISATION USES ONLY SYNTHETIC DATA!" else"" })
  
  output$description <- renderText({"
The tool shows how the mismatch between supply and demand varies across occupation groups in five countries in Europe. Demand for skills is measured by job vacancies advertised (using CEDEFOP web scraped data and EURES data from public employment services), while supply is measured by CV's uploaded to the EURES job portal, calibrated to survey data (from the Programme for the International Assessment of Adult Competencies).

There are three visualisations presented:
The first tab is a map which allows the user to browse different geographical and occupation levels to drill down and examine supply, demand or the mismatch between both to compare across Europe
The second tab allows the user to examine particular countries or regions to compare how supply matches demand for specific occupation groups or occupations
The third tab compares the training undertaken for different occupation groups in each of the five countries and whether the training was formal, informal or on the job.
 " })
  output$datasets <- renderText({"
The team focused on using data from:
CEDEFOP on job vacancies (web scraped data from job portals)
EURES about job vacancies on the EU Job Mobility Portal
EURES from CV's supplied by job seekers on the EU Job Mobility Portal
    PIAAC (Programme for the International Assessment of Adult Competencies) survey data about the occupations of those in work and the training they have undertaken in the past year
    The team recognised the potential bias inherent in the CV's uploaded to EURES and sought to 'correct' this by calibrating it to the PIAAC survey data so that residents in countries who were more inclined to upload their CV's did not disproportionately affect the appearance of the “supply” of skills between countries.
 " })    
  output$tools <- renderText({"
      The team mostly used Python and R for development, and AWS for wrangling the larger datasets. The tool is presented in an R Shiny App.
 " })
})



#######################################################
#> sessionInfo()
#R version 3.4.1 (2017-06-30)
#Platform: x86_64-pc-linux-gnu (64-bit)
#Running under: Ubuntu 14.04.5 LTS

#Matrix products: default
#BLAS: /usr/lib/openblas-base/libblas.so.3
#LAPACK: /usr/lib/lapack/liblapack.so.3.0

#locale:
#  [1] LC_CTYPE = en_GB.UTF-8       LC_NUMERIC = C               LC_TIME = en_GB.UTF-8        LC_COLLATE = en_GB.UTF-8     LC_MONETARY = en_GB.UTF-8   
#[6] LC_MESSAGES = en_GB.UTF-8    LC_PAPER = en_GB.UTF-8       LC_NAME = C                  LC_ADDRESS = C               LC_TELEPHONE = C            
#[11] LC_MEASUREMENT = en_GB.UTF-8 LC_IDENTIFICATION = C       

#attached base packages:
#  [1] stats     graphics  grDevices utils     datasets  methods   base     

#other attached packages:
#  [1] bindrcpp_0.2       geojsonio_0.3.2    dplyr_0.7.1        reshape2_1.2.2     htmltools_0.3.6    RColorBrewer_1.0-5 ggplot2_2.2.1     
#[8] leaflet_1.1.0      scatterD3_0.8.1    shiny_1.0.3       

#loaded via a namespace (and not attached):
#  [1] Rcpp_0.12.11      compiler_3.4.1    plyr_1.8          bindr_0.1         tools_3.4.1       digest_0.6.4      jsonlite_1.5      tibble_1.3.3     
#[9] gtable_0.1.2      lattice_0.20-35   pkgconfig_2.0.1   rlang_0.1.1       crosstalk_1.0.0   rgdal_1.2-8       curl_2.7          yaml_2.1.14      
#[17] httr_1.2.1        stringr_0.6.2     sourcetools_0.1.6 htmlwidgets_0.8   rgeos_0.3-23      grid_3.4.1        glue_1.1.1        ellipse_0.3-8    
#[25] R6_2.2.2          foreign_0.8-69    sp_1.2-5          magrittr_1.5      maptools_0.9-2    scales_0.4.1      assertthat_0.2.0  mime_0.5         
#[33] xtable_1.8-2      colorspace_1.2-2  httpuv_1.3.5      labeling_0.1      V8_1.5            lazyeval_0.2.0    munsell_0.4.2   