library(shiny)

# Define server logic required to draw a chart
shinyServer(function(input, output) {
  
  # Expression that generates a horizontal bar chart. The expression is
  # wrapped in a call to renderPlot to indicate that:
  #
  #  1) It is "reactive" and therefore should re-execute automatically
  #     when inputs change
  #  2) Its output type is a plot
  
  output$value <- renderPrint({ input$select })
  
  output$barplot <- renderPlot({

    library(ggplot2)
    library(reshape2)
    
    ## Read in data
    piaac <- read.csv("C:/Users/ONS-BIG-DATA/Documents/Hackathon/datasets/Visualise/piaac_summary.csv", header=TRUE, sep=",")
    
    ## Ignore popn then melt
    piaac$Popn <- NULL
    melted <- melt(piaac, id.vars = c("Esco_Level_1", "Esco_Level_2", "REGION0", "Esco_code"))
    colnames(melted) <- c("Esco_Level_1", "Esco_Level_2", "REGION0", "Esco_code", "Training", "Value")
 
    ## Make training types look pretty
    melted$Training <- gsub("non.formal", "non-formal", melted$Training, fixed=TRUE)
    melted$Training <- gsub("on_job", "on the job", melted$Training, fixed=TRUE)
       
    ## Convert input$select from ui selection to be used here
    value <- as.numeric(input$select)
    melted_selected <- subset(melted, Esco_code==value)
    
    ## Plot
    ggplot(data=melted_selected, aes(x=Esco_Level_2, y=Value, group = Training, colour = Training)) +
      geom_bar(aes(fill = Training), position = "dodge", stat="identity") +
      coord_flip() +
      labs(x="Occupation", y="Percentage")+
      facet_grid(.~REGION0)
    
  }, height = 600, width = 1200)
})