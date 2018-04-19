#### CREATE CDPH UNINSURANCE AND BREAST CANCER RISK INTERACTIVE MAP ####
## R script that renders a Shiny app that maps uninsured/at-risk of breast cancer women in Chicago
## Fall 2017
## Civis Analytics
## R version 3.4.2

## ----------------------------< Prepare Workspace >------------------------------------
rm(list = ls())  # clear workspace

install.packages(c('leaflet',
                   'shinythemes'),
                 repos='https://cran.rstudio.com/')

## load necessary packages
library(shiny)        # version 1.0.5
library(leaflet)      # version 1.1.0
library(shinythemes)  # version 1.1.1
library(rsconnect)    # version 0.8.5

#           "viridis",      # version 0.4.0
 

## load data for map -- this has to be in the same directory as your working directory
load("cdph_mapping.Rdata")


################ INTERACTIVE MAP ################

## ----------------< User Interface of Shiny App >----------------
ui <- fluidPage(
  theme = shinythemes::shinytheme("lumen"),
  headerPanel("Target Areas for Breast Cancer Screening in Chicago (2017)"),  # title of app
  sidebarLayout(
    # left sidebar of app where drop down menus to customize map will be located
    sidebarPanel(
      # drop down menu where users can select what granularity to map 
      selectInput("level", "Choose what level to map:", 
                  choices = c("by Community Area", 
                              "by Census Tract"
                  )),
      # drop down menu where users can select what population to map
      selectInput("population", "Choose what population to map:", 
                  choices = c("Uninsured Women", 
                              "Women At-Risk of Breast Cancer", 
                              "Women who are Both Uninsured and At-Risk of Breast Cancer",
                              "Women who are Uninsured or At-Risk of Breast Cancer"))
    ),
    # main panel of app where map will appear
    mainPanel(tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"),  # make map fill up the window
              leafletOutput("map"))
  )
)


## ----------------< Shiny Server which Renders Data Inputs into Outputs >----------------
server <- function(input, output, session){
  
  # identify dataset to use based on user input
  datasetInput <- reactive({
    switch(input$level,
           "by Community Area" = ca, 
           "by Census Tract" = tract)
  })
  
  # identify population column based on user input
  popInput <- reactive({
    switch(input$population,
           "Uninsured Women" = "avgp_uninsured", 
           "Women At-Risk of Breast Cancer" = "avgp_bcrisk", 
           "Women who are Both Uninsured and At-Risk of Breast Cancer" = "avgp_both",
           "Women who are Uninsured or At-Risk of Breast Cancer" = "avgp_either")
  })   
  
  # adjust callout labels based on user input
  labelTitleInput <- reactive({
    switch(input$level,
           "by Community Area" = "<strong>%s</strong><br/>", 
           "by Census Tract" = "<strong>Census Tract %s</strong><br/>")
  })
  labelPlaceInput <- reactive({
    switch(input$level,
           "by Community Area" = "community", 
           "by Census Tract" = "tractce10")
  })
  labelInfoInput <- reactive({
    switch(input$population,
           "Uninsured Women" = "Approx. %.2f%% Uninsured</br>",
           "Women At-Risk of Breast Cancer" = "Approx. %.2f%% At-Risk</br>",
           "Women who are Both Uninsured and At-Risk of Breast Cancer" = "Approx. %.2f%% Uninsured and At-Risk</br>",
           "Women who are Uninsured or At-Risk of Breast Cancer" = "Approx. %.2f%% Uninsured or At-Risk</br>")
  })
  
  # set coloring of map based on user input
  palInput <- reactive({
    switch(input$population,
           "Uninsured Women" = "Blues",                                              # to make palette colorblind-friendly, can replace "Blues" with: viridis(2)
           "Women At-Risk of Breast Cancer" = "Reds",                                # to make palette colorblind-friendly, can replace "Reds" with: magma(2)
           "Women who are Both Uninsured and At-Risk of Breast Cancer" = "Purples",  # to make palette colorblind-friendly, can replace "Purples" with: plasma(2)
           "Women who are Uninsured or At-Risk of Breast Cancer" = "Greens")         # to make palette colorblind-friendly, can replace "Greens" with: inferno(2)
  })
  
  # change legend title based on user input
  legendTitleInput <- reactive({
    switch(input$population,
           "Uninsured Women" = "Approx. % Uninsured", 
           "Women At-Risk of Breast Cancer" = "Approx. % At-Risk", 
           "Women who are Both Uninsured and At-Risk of Breast Cancer" = "Approx. % Uninsured and At-Risk",
           "Women who are Uninsured or At-Risk of Breast Cancer" = "Approx. % Uninsured or At-Risk")
  })
  
  
  
  # create leaflet map
  output$map <- renderLeaflet({
    
    # grab user input data
    data <- datasetInput()
    pop <- popInput()
    
    labeltitle <- labelTitleInput()
    labelinfo <- labelInfoInput()
    labelplace <- labelPlaceInput()
    
    pal_input <- palInput()
    
    legendtitle <- legendTitleInput()
    
    # set up color palette based off user input
    pals <- colorNumeric(palette = pal_input,
                         domain = data$pop
                         )
    
    # create map pop-up labels based on user input
    labels <- sprintf(paste0(labeltitle, labelinfo),
                      data@data[[labelplace]], data@data[[pop]]) %>%
      lapply(htmltools::HTML)
    
    # create map
    leaflet(data = data) %>%
      # background map of Chicago and surrounding area
      addProviderTiles(providers$CartoDB.Positron,
                       options = providerTileOptions(opacity = 0.5),
                       group = "Background Map") %>%
      # map with information of interest
      addPolygons(stroke = TRUE, color = "gray", weight = 0.8, opacity = 0.8,  # geographic area outlines
                  fillColor = pals(data[[pop]]), fillOpacity = 0.6,            # geographic area fill
                  # options when you scroll over a geographic area
                  highlight = highlightOptions(
                    weight = 2,
                    color = "black",
                    fillOpacity = 1,
                    bringToFront = TRUE),
                  label = labels,
                  labelOptions = labelOptions(
                    style = list("font-weight" = "normal", padding = "3px 8px"),
                    textsize = "12px",
                    direction = "auto")) %>%
      addLegend("bottomleft", pal = pals, values = data[[pop]], title = legendtitle,
                labFormat = labelFormat(suffix = "%"),
                opacity = 1) %>%
      addLayersControl(
        overlayGroups = c("Background Map"),  # allow option to remove background map
        options = layersControlOptions(collapsed = FALSE))
  })
  
  session$allowReconnect("force")
}


## ----------------< Run the Shiny App >----------------
shinyApp(ui = ui, server = server)


