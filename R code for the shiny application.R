library(shiny)
library(shinydashboard)
library(leaflet)
library(DBI)
library(odbc)
library(dplyr)
library(ggplot2)
library(DT)
library(scales)

source("credentials_v4.R")

# Database connection
db <- dbConnector(
  server = getOption("database_server"),
  database = getOption("database_name"),
  uid = getOption("database_userid"),
  pwd = getOption("database_password"),
  port = getOption("database_port")
)
Sys.setenv(LANG = "en")

# Create the Shiny dashboard
ui <- dashboardPage(
  dashboardHeader(title = "ITOM6265 Group 8"),
  skin = "blue",
  dashboardSidebar(
    sidebarMenu(
      menuItem("House On Market", tabName = "house_on_market", icon = icon("edit")),
      menuItem("House Closed by Agent", tabName = "house_closed_by_agent", icon = icon("table")),
      menuItem("Add New House", tabName = "add_new_house", icon = icon("plus")),
      menuItem("Remove House", tabName = "delete_listing", icon = icon("trash")),
      menuItem("House Filter", tabName = "House_Filter", icon = icon("filter")),
      menuItem("Update Home Listing", tabName = "update_home_listing", icon = icon("edit")),
      menuItem("Dallas Home Analytics", tabName = "dallas_home_analytics", icon = icon("chart-bar"))
    )
  ),
  dashboardBody(
    tabItems(
      ## House On Market
      tabItem(tabName = "house_on_market",
              h3("Welcome to the House On Market Tab"),
              h4("Explore the current listings available in the Dallas area."),
              box(
                title = "Introduction",
                status = "info",
                solidHeader = TRUE,
                collapsible = TRUE,
                width = 12,
                p("This application allows you to explore houses currently on the market in Dallas."),
                p("Take advantage of the interactive map to visualize the locations of available houses."),
                p("As well as applying filters to narrow down your search for your dream house."),
                p("Feel free to interact with the data and discover more about the Dallas real estate market!"),
                HTML("<ul><li><h4>House Closed by Agent</h4></li></ul>"),
                tags$p(style = "text-indent: 40px;", "This tab allows inputs for agent ID to retrieves and displays relevant sales data for the specified agent"),
                HTML("<ul><li><h4>Add New House</h4></li></ul>"),
                tags$p(style = "text-indent: 40px;", "This tab allows users to add new house along with its information to the database"),
                HTML("<ul><li><h4>Delete SalesContract</h4></li></ul>"),
                tags$p(style = "text-indent: 40px;", "This tab enables users to delete house information based on the provided Listing ID"),
                HTML("<ul><li><h4>House Filter by Agent</h4></li></ul>"),
                tags$p(style = "text-indent: 40px;", "This tab provides filter options for houses based on various criteria 
                       (bedrooms, bathrooms, garage, list price, square footage, description)."),
                HTML("<ul><li><h4>Update Home listing</h4></li></ul>"),
                tags$p(style = "text-indent: 40px;", "This tab allows users to update the listing price using Property ID, Listing ID, or both"),
                HTML("<ul><li><h4>Dallas Home Analytics</h4></li></ul>"),
                tags$p(style = "text-indent: 40px;", "This tab generates a scatter plot of list price against the duration a house stays on the market")
                
              ),
              box(
                title = "Credit",
                status = "info",
                solidHeader = TRUE,
                collapsible = TRUE,
                width = 12,
                h5("This application is built by:"),
                fluidRow(
                  column(3, align = "center",
                         h4("Alex Sun")
                  ),
                  column(3, align = "center",
                         h4("Xuelin Lin")
                  ),
                  column(3, align = "center",
                         h4("Zhi Gui")
                  ),
                  column(3, align = "center",
                         h4("Richard Liang")
                  )
                )
              )
      ),
      
      ## House Closed by Agent
      tabItem(tabName = "house_closed_by_agent",
              fluidRow(
                column(12,
                       textInput("agent_id", "Agent ID:", "")
                ),
                column(12,
                       actionButton("get_results", "Search")
                ),
                # Add space
                column(12, style = "margin-top: 20px;"),
                h3("This is your search result:"),
                DT::dataTableOutput("sales_table")
              )
      ),
      

      
      #Add New house to the database
      tabItem(tabName = "add_new_house",
              h3("Add New House to the DataBase:"),
              textInput("new_propertyID", label = "ProperyID", value = " "),
              textInput("new_address", label = "Address", value = " "),
              textInput("new_square_footage", label = "Square Footage", value = " "),
              textInput("new_bedrooms", label = "# of Bedrooms", value = " "),
              textInput("new_Bathrooms", label = "# of Bathrooms", value = " "),
              textInput("new_Num_Garage", label = "# of Garage", value = " "),
              textInput("new_price", label = "Listing Price", value = " "),
              textInput("new_Descript", label = "Description", value = " "),
              actionButton("addition", "Add")
        
      ),
      
      
      
      ## Delete Sales Contract
      tabItem(tabName = "delete_listing",
              h1("If you wish to remove your house's information from this app"),
              textInput("property_ID", label = "Property ID", value = " "),
              actionButton("delete_action", "Delete My House"),
              textOutput("delete_message")
      ),
      
      ## House Filter
      tabItem(tabName = "House_Filter",
              fluidRow(
                box(
                  title = "House Filters",
                  status = "primary",
                  sliderInput("bedrooms", "NumberOfBedRooms", min = 1, max = 6, value = c(1, 6)),
                  sliderInput("bathrooms", "NumberOfBathRooms", min = 1, max = 8, value = c(1, 8)),
                  sliderInput("garage", "NumberOfGarage", min = 0, max = 4, value = c(0, 4)),
                  sliderInput("listPrice", "ListPrice", min = 20000, max = 10000000, value = c(20000, 10000000)),
                  sliderInput("squareFootage", "SquareFootage", min = 500, max = 5000, value = c(500, 5000)),
                  textInput("description", "Description", placeholder = "Enter keywords, e.g., 'Built in'"),
                  actionButton("applyFilters", "Apply Filters")
                ),
                box(
                  title = "Map",
                  leafletOutput("map", height = "600px")
                )
              )
      ),
      
      ## Update Home listing
      tabItem(tabName = "update_home_listing",
              fluidRow(
                box(
                  title = "Update Listing Price",
                  status = "primary",
                  width = 12,
                  sidebarLayout(
                    sidebarPanel(
                      h4("Update the listing price using either the Property ID, Listing ID, or both."),
                      textInput("listingID", "Listing ID", ""),
                      textInput("propertyID", "Property ID", ""),
                      numericInput("newPrice", "New Listing Price", value = 0),
                      actionButton("updateBtn", "Update Price")
                    ),
                    mainPanel(
                      textOutput("result"),
                      leafletOutput("updatedMap", height = "600px")
                    )
                  )
                )
              )
      ),

      ## Dallas Home Analytics
      tabItem(tabName = "dallas_home_analytics",
              h3("This is your search result:"),
              fluidRow(
                column(12,
                       offset = 1,  # Add an indent by setting the offset
                       actionButton("get_plot", "Get Plot")
                ),
                column(12, style = "margin-top: 10px;"),  # Add some top margin for space
                column(12,
                       plotOutput("analytics_chart")
                )
              )
      )
    )
  )
)

# Model
server <- function(input, output, session) {
  
 
  observeEvent(input$get_results, {
    query <- paste(
      "SELECT
        PropertyID
        ,ListPrice
        ,DATEDIFF(day, ListDate, SoldDate) AS ListOnMarket
        ,A.AgentID
        ,A.Name
        ,A.Office 
      FROM [ITOM6265_F23_Group8].[dbo].[Agent] A 
      INNER JOIN Listing L ON A.AgentID = L.AgentID
      WHERE L.Status = 'Sold' AND A.AgentID = ", input$agent_id, ";", sep = ""
    )
    data <- dbGetQuery(db, query)
    output$sales_table <- DT::renderDataTable({
      DT::datatable(data)
    })
  })
  
  
  observeEvent(input$addition, {
    # Create a query to insert the new house into the House table
    insertQuery <- sprintf("INSERT INTO House (PropertyID, Address, SquareFootage, NumberOfBedRooms, NumberOfBathRooms, NumberOfGarage, ListPrice, Description) VALUES ('%s', '%s', %s, %s, %s, %s, %s, '%s')",
                           input$new_propertyID, input$new_address, input$new_square_footage,
                           input$new_bedrooms, input$new_Bathrooms, input$new_Num_Garage, input$new_price, input$new_Descript)
    
    # Try to execute the query
    tryCatch({
      dbExecute(db, insertQuery)
      showNotification("New house added successfully.", type = "message", duration = 5)
      
      # Clear input fields after successful addition
      updateTextInput(session, "new_propertyID", value = "")
      updateTextInput(session, "new_address", value = "")
      updateTextInput(session, "new_square_footage", value = "")
      updateTextInput(session, "new_bedrooms", value = "")
      updateTextInput(session, "new_Bathrooms", value = "")
      updateTextInput(session, "new_Num_Garage", value = "")
      updateTextInput(session, "new_price", value = "")
      updateTextInput(session, "new_Descript", value = "")
    }, error = function(e) {
      showNotification("Error adding new house. Please try again.", type = "error", duration = 5)
    })
  })
  
  observeEvent(input$delete_action, {
    # Create the query
    query <- paste("DELETE FROM House 
                  WHERE PropertyID = '", input$property_ID, "';", sep = "")
    
    # Try to execute the query
    tryCatch({
      dbExecute(db, query)
      showNotification("Your information has been deleted", type = "message", duration = 5)
    }, error = function(e) {
      showNotification("Invalid Property ID or you have successfully deleted your information", type = "message", duration = 5)
    })
  })
  
  observeEvent(input$applyFilters, {
    query <- sprintf(
      "SELECT * FROM [ITOM6265_F23_Group8].[dbo].[House]
       WHERE NumberOfBedRooms BETWEEN %d AND %d
       AND NumberOfBathRooms BETWEEN %d AND %d
       AND NumberOfGarage BETWEEN %d AND %d
       AND ListPrice BETWEEN %d AND %d
       AND SquareFootage BETWEEN %d AND %d
       %s",
      input$bedrooms[1], input$bedrooms[2],
      input$bathrooms[1], input$bathrooms[2],
      input$garage[1], input$garage[2],
      input$listPrice[1], input$listPrice[2],
      input$squareFootage[1], input$squareFootage[2],
      if (input$description != "") {
        sprintf("AND Description LIKE '%%%s%%'", input$description)
      } else {
        ""
      }
    )
    filteredData <- dbGetQuery(db, query)
    output$map <- renderLeaflet({
      leaflet(data = filteredData) %>%
        addTiles() %>%
        addCircleMarkers(
          lng = ~Longitude, lat = ~Latitude,
          radius = 6, color = "#007bff",
          popup = ~paste(
            "Address:", Address,
            "<br/>Bedrooms:", NumberOfBedRooms,
            "<br/>Bathrooms:", NumberOfBathRooms,
            "<br/>Garage:", NumberOfGarage,
            "<br/>ListPrice:", ListPrice,
            "<br/>Square Footage:", SquareFootage,
            "<br/>Description:", Description
          )
        )
    })
  })
  
  # Initialize new/old ListPrice as a reactive value(Tab Update Listing)
  oldListPrice <- reactiveVal()
  newListPrice <- reactiveVal()
  
  observeEvent(input$updateBtn, {
    # Validate input
    if (input$listingID == "" && input$propertyID == "") {
      output$result <- renderText("Please enter a Listing ID or Property ID.")
      return()
    }
    
    # Check if both IDs are provided and validate their match
    if (input$listingID != "" && input$propertyID != "") {
      propertyIDQuery <- sprintf("SELECT PropertyID FROM Listing WHERE ListingID = '%s'", input$listingID)
      propertyData <- dbGetQuery(db, propertyIDQuery)
      if (nrow(propertyData) > 0 && propertyData$PropertyID[1] != input$propertyID) {
        output$result <- renderText("Property ID and Listing ID do not match. List Price update failed.")
        return()
      }
    }
    
    # Determine the PropertyID
    actualPropertyID <- ifelse(input$propertyID != "", input$propertyID, NA)
    
    # If ListingID is provided, fetch the corresponding PropertyID
    if (input$listingID != "") {
      propertyQuery <- sprintf("SELECT PropertyID FROM Listing WHERE ListingID = '%s'", input$listingID)
      propertyData <- dbGetQuery(db, propertyQuery)
      if (nrow(propertyData) > 0) {
        actualPropertyID <- propertyData$PropertyID[1]
      } else {
        output$result <- renderText("No corresponding PropertyID found for the given ListingID.")
        return()
      }
    }
    
    # Retrieve the old price for comparison
    oldPriceQuery <- sprintf("SELECT ListPrice FROM Listing WHERE PropertyID = '%s'", actualPropertyID)
    oldPriceData <- dbGetQuery(db, oldPriceQuery)
    if (nrow(oldPriceData) > 0) {
      oldListPrice(oldPriceData$ListPrice[1])
    }
    
    # Start transaction
    dbBegin(db)
    
    # Update the listing price in Listing table
    updateListingQuery <- sprintf("UPDATE Listing SET ListPrice = %f WHERE PropertyID = '%s'",
                                  input$newPrice, actualPropertyID)
    dbExecute(db, updateListingQuery)
    
    # Update the listing price in House table
    updateHouseQuery <- sprintf("UPDATE House SET ListPrice = %f WHERE PropertyID = '%s'",
                                input$newPrice, actualPropertyID)
    dbExecute(db, updateHouseQuery)
    
    # Commit the transaction
    dbCommit(db)
    
    # Set the new list price
    newListPrice(input$newPrice)
    
    # Calculate the difference and average
    avgPriceQuery <- "SELECT AVG(ListPrice) as AvgPrice FROM Listing"
    avgPriceData <- dbGetQuery(db, avgPriceQuery)
    difference <- input$newPrice - oldListPrice()
    differenceFromAvg <- input$newPrice - avgPriceData$AvgPrice
    
    # Update result text
    output$result <- renderText({
      sprintf("Price updated to %s successfully. New price is %s %s than the previous price and %s %s than the average listing price in Dallas.",
              format(round(input$newPrice), nsmall = 0),
              format(round(abs(difference)), nsmall = 0),
              ifelse(difference >= 0, "higher", "lower"),
              format(round(abs(differenceFromAvg)), nsmall = 0),
              ifelse(differenceFromAvg >= 0, "higher", "lower"))
    })
    
    # Display map with updated listing highlighted
    output$updatedMap <- renderLeaflet({
      updatedData <- dbGetQuery(db, sprintf("SELECT * FROM House WHERE PropertyID = '%s'", actualPropertyID))
      
      leaflet(data = updatedData) %>%
        addTiles() %>%
        addCircleMarkers(
          lng = ~Longitude, lat = ~Latitude,
          radius = 8, color = "red",
          popup = ~paste(
            "Address:", Address,
            "<br/>Bedrooms:", NumberOfBedRooms,
            "<br/>Bathrooms:", NumberOfBathRooms,
            "<br/>Garage:", NumberOfGarage,
            "<br/><strong><span style='color: red;'>Old ListPrice:</span></strong>", oldListPrice(),
            "<br/><strong><span style='color: green;'>New ListPrice:</span></strong>", newListPrice(),
            "<br/>Square Footage:", SquareFootage,
            "<br/>Description:", Description
          )
        )
    })
  })
  observeEvent(input$get_plot, {
    query <- "SELECT
      ListPrice
      ,DATEDIFF(day, ListDate, SoldDate) AS ListOnMarket
    FROM [ITOM6265_F23_Group8].[dbo].[Agent] A 
    INNER JOIN Listing L ON A.AgentID = L.AgentID
    WHERE L.Status = 'Sold';"
    data <- dbGetQuery(db, query)
    output$analytics_chart <- renderPlot({
      ggplot(data, aes(y=ListOnMarket, x=ListPrice)) + 
        geom_point() +
        geom_smooth(method='lm', formula=y~x) + 
        scale_x_continuous(labels = scales::comma)
    })
  })
}

# Controller
shinyApp(ui = ui, server = server)