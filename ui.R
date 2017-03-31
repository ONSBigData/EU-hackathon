library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Percentage of workers who have done training in past year, by occupation and country"),
  
  # Drop down menu for selecting an occupation group, with default which is Managers
  selectInput("select", label = h3("Select occupation group"), 
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

  )
))