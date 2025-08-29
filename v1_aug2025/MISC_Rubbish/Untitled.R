library(shiny)
library(shinydashboard)
library(MASS)  # for polr
library(dplyr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "The Analytical Sommelier",
                  titleWidth = 450),
  
  dashboardSidebar(
    width = 300,
    disable = FALSE,  # Keep sidebar always visible
    
    # Instructions
    h3(HTML("<b>Wine — Chemical Attributes</b>"), style = "padding-left: 15px; color: #8B0000;"),
    p("Enter actual measurement values below.", 
      style = "padding: 0 15px; font-size: 12px; color: #666;"),
    p("NOTE: Values are normalized among the training data, and the new attribute 'free.SO2.ratio' is automatically calculated, before input into the predictive model.", 
      style = "padding: 0 15px; font-size: 10px; color: #888; font-style: italic;"),
    
    br(),
    
    # Categorical Variables
    h5("Wine Characteristics", style = "padding-left: 15px; font-weight: bold;"),
    
    radioButtons("type",
                 label = "Wine Type:",
                 choices = list("Red Wine" = "red", 
                                "White Wine" = "white"),
                 selected = "red"),
    
    radioButtons("location",
                 label = "Location:",
                 choices = list("California" = "California", 
                                "Texas" = "Texas"),
                 selected = "California"),
    
    br(),
    h5("Chemical Properties", style = "padding-left: 15px; font-weight: bold;"),
    
    # Numeric Variables with actual ranges from data
    sliderInput("fixed.acidity",
                label = "Fixed Acidity (g/L):",
                min = 3.8,
                max = 11.6,
                value = 7.1,
                step = 0.1),
    
    sliderInput("volatile.acidity",
                label = "Volatile Acidity (g/L):",
                min = 0.08,
                max = 0.91,
                value = 0.33,
                step = 0.01),
    
    sliderInput("citric.acid",
                label = "Citric Acid (g/L):",
                min = 0,
                max = 0.81,
                value = 0.31,
                step = 0.01),
    
    sliderInput("residual.sugar",
                label = "Residual Sugar (g/L):",
                min = 0.6,
                max = 26.05,
                value = 5.5,
                step = 0.1),
    
    sliderInput("chlorides",
                label = "Chlorides (g/L):",
                min = 0.009,
                max = 0.146,
                value = 0.052,
                step = 0.001),
    
    sliderInput("free.sulfur.dioxide",
                label = HTML("Free SO<sub>2</sub> (mg/L):"),
                min = 1,
                max = 112,
                value = 31,
                step = 1),
    
    sliderInput("total.sulfur.dioxide",
                label = HTML("Total SO<sub>2</sub> (mg/L):"),
                min = 6,
                max = 366.5,
                value = 118,
                step = 1),
    
    sliderInput("density",
                label = HTML("Density (g/cm<sup>3</sup>):"),
                min = 0.98711,
                max = 1.00295,
                value = 0.9945,
                step = 0.0001),
    
    sliderInput("pH",
                label = "pH:",
                min = 2.72,
                max = 3.9,
                value = 3.22,
                step = 0.01),
    
    sliderInput("sulphates",
                label = "Sulphates (g/L):",
                min = 0.22,
                max = 1.08,
                value = 0.52,
                step = 0.01),
    
    sliderInput("alcohol",
                label = "Alcohol (% vol):",
                min = 8,
                max = 14.05,
                value = 10.5,
                step = 0.05),
    
    br(),
    
    # Predict button
    actionButton("predict", 
                 label = "Predict Wine Quality",
                 class = "btn-primary",
                 style = "width: 90%; margin-left: 5%; background-color: #8B0000; border-color: #8B0000;")
  ),
  
  dashboardBody(
    # Custom CSS for wine-themed styling
    tags$head(
      tags$style(HTML("
        /* Remove sidebar toggle button */
        .sidebar-toggle {
          display: none !important;
        }
        
        /* Ensure sidebar stays open */
        .left-side, .main-sidebar {
          transform: translate(0, 0) !important;
        }
        
        .content-wrapper, .right-side {
          background-color: #f8f5f0;
          margin-left: 300px !important;
        }
        
        .big-number-box {
          border-radius: 15px;
          padding: 40px;
          text-align: center;
          color: white;
          box-shadow: 0 10px 30px rgba(114, 47, 55, 0.3);
          margin: 20px;
          position: relative;
          overflow: hidden;
          background-size: cover;
          background-position: center;
          background-repeat: no-repeat;
        }
        
        .wine-overlay {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          border-radius: 15px;
        }
        
        .wine-content {
          position: relative;
          z-index: 2;
        }
        
        .prediction-label {
          font-size: 24px;
          font-weight: 300;
          margin-bottom: 10px;
          text-transform: uppercase;
          letter-spacing: 2px;
        }
        
        .prediction-value {
          font-size: 96px;
          font-weight: bold;
          margin: 20px 0;
          text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        .quality-stars {
          font-size: 32px;
          color: #FFD700;
          margin-top: 10px;
          text-shadow: 1px 1px 2px rgba(0,0,0,0.5);
        }
        
        .probability-box {
          background: white;
          border-radius: 10px;
          padding: 20px;
          margin: 20px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .info-box {
          background: white;
          border-radius: 10px;
          padding: 20px;
          margin: 20px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .normalization-box {
          background: #fff9f0;
          border-radius: 10px;
          padding: 15px;
          margin: 20px;
          border: 1px solid #e8d4b0;
        }
      "))
    ),
    
    fluidRow(
      column(width = 12,
             # Main prediction display with dynamic styling
             uiOutput("prediction_box")
      )
    ),
    
    fluidRow(
      column(width = 6,
             div(class = "probability-box",
                 h4("Quality Probability Distribution", style = "color: #722f37;"),
                 plotOutput("prob_plot", height = "300px")
             )
      ),
      column(width = 6,
             div(class = "info-box",
                 h4("Model Information", style = "color: #722f37;"),
                 verbatimTextOutput("model_info")
             )
      )
    ),
    
    fluidRow(
      column(width = 12,
             div(class = "normalization-box",
                 h4("Data Processing Details", style = "color: #722f37;"),
                 verbatimTextOutput("normalization_info")
             )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Add resource path for images if they're in the app directory
  addResourcePath("images", getwd())
  
  # Load the training data for normalization reference
  trainData <- reactive({
    # Try to load actual data file first
    if (file.exists("trainClean.csv")) {
      read.csv("trainClean.csv", stringsAsFactors = FALSE) %>%
        mutate(
          type = factor(type),
          location = factor(location),
          quality = factor(quality, ordered = TRUE)
        )
    } else {
      # Fallback to mock data if file not found
      showNotification("Warning: trainClean.csv not found. Using mock data.", 
                       type = "warning", duration = 5)
      data.frame(
        ID = 1:100,
        fixed.acidity = runif(100, 3.8, 11.6),
        volatile.acidity = runif(100, 0.08, 0.91),
        citric.acid = runif(100, 0, 0.81),
        residual.sugar = runif(100, 0.6, 26.05),
        chlorides = runif(100, 0.009, 0.146),
        free.sulfur.dioxide = runif(100, 1, 112),
        total.sulfur.dioxide = runif(100, 6, 366.5),
        density = runif(100, 0.98711, 1.00295),
        pH = runif(100, 2.72, 3.9),
        sulphates = runif(100, 0.22, 1.08),
        alcohol = runif(100, 8, 14.05),
        type = factor(sample(c("red", "white"), 100, replace = TRUE)),
        location = factor(sample(c("California", "Texas"), 100, replace = TRUE)),
        quality = factor(sample(3:9, 100, replace = TRUE), ordered = TRUE)
      )
    }
  })
  
  # Create reactive values for predictions
  prediction <- reactiveValues(
    quality = NULL, 
    probs = NULL,
    normalized_values = NULL,
    so2_ratio = NULL
  )
  
  # Dynamic prediction box UI
  output$prediction_box <- renderUI({
    wine_color <- if(input$type == "red") "maroon" else "lightyellow"
    wine_rgba <- if(input$type == "red") "rgba(128, 0, 0, 0.7)" else "rgba(255, 255, 224, 0.7)"
    text_color <- if(input$type == "red") "white" else "#333333"
    
    # Determine background image file
    bg_image <- if(input$location == "California") "ca.png" else "tx.png"
    
    # Create the box with inline background image
    div(class = "big-number-box",
        style = paste0("background-image: url('", bg_image, "'); background-size: cover; background-position: center;"),
        div(class = "wine-overlay", 
            style = paste0("background-color: ", wine_rgba, ";")),
        div(class = "wine-content",
            style = paste0("color: ", text_color, ";"),
            div(class = "prediction-label", "Predicted Wine Quality"),
            div(class = "prediction-value", textOutput("predicted_quality")),
            div(class = "quality-stars", textOutput("quality_stars")),
            div(style = paste0("font-size: 16px; margin-top: 20px; opacity: 0.9; color: ", text_color, ";"), 
                textOutput("confidence_text"))
        )
    )
  })
  
  # Prediction logic
  observeEvent(input$predict, {
    
    # Get the training data
    train_data <- trainData()
    
    # Create new observation with user inputs
    new_obs <- data.frame(
      ID = max(train_data$ID) + 1,
      fixed.acidity = input$fixed.acidity,
      volatile.acidity = input$volatile.acidity,
      citric.acid = input$citric.acid,
      residual.sugar = input$residual.sugar,
      chlorides = input$chlorides,
      free.sulfur.dioxide = input$free.sulfur.dioxide,
      total.sulfur.dioxide = input$total.sulfur.dioxide,
      density = input$density,
      pH = input$pH,
      sulphates = input$sulphates,
      alcohol = input$alcohol,
      type = factor(input$type, levels = levels(train_data$type)),
      location = factor(input$location, levels = levels(train_data$location))
    )
    
    # Calculate free.SO2.ratio
    new_obs$free.SO2.ratio <- new_obs$free.sulfur.dioxide / new_obs$total.sulfur.dioxide
    train_data$free.SO2.ratio <- train_data$free.sulfur.dioxide / train_data$total.sulfur.dioxide
    
    # Store the ratio for display
    prediction$so2_ratio <- new_obs$free.SO2.ratio
    
    # Combine new observation with training data
    combined_data <- rbind(
      train_data[, names(new_obs)],
      new_obs
    )
    
    # Identify numeric columns to normalize (excluding free.SO2.ratio as it's already normalized)
    num_cols <- c("fixed.acidity", "volatile.acidity", "citric.acid", 
                  "residual.sugar", "chlorides", "free.sulfur.dioxide", 
                  "total.sulfur.dioxide", "density", "pH", "sulphates", "alcohol")
    
    # Apply normalization to numeric columns
    normalized_data <- combined_data
    for (col in num_cols) {
      normalized_data[[col]] <- scale(combined_data[[col]])[, 1]
    }
    
    # Extract the normalized values for the new observation (last row)
    new_obs_normalized <- normalized_data[nrow(normalized_data), ]
    
    # Store normalized values for display
    prediction$normalized_values <- new_obs_normalized[, num_cols]
    
    # IMPORTANT: Load and use your actual trained model here
    # model <- readRDS("path/to/your/model.rds")
    # pred_probs <- predict(model, newdata = new_obs_normalized, type = "probs")
    # pred_class <- predict(model, newdata = new_obs_normalized, type = "class")
    
    # For demonstration - replace with actual model predictions
    quality_levels <- as.character(3:9)
    set.seed(sum(unlist(new_obs[, num_cols])) * 1000)
    
    # Simulate prediction based on inputs (replace with real model)
    center <- 3 + (input$alcohol - 8) * 0.5 + 
      (1 - input$volatile.acidity) * 2 + 
      input$citric.acid * 2 +
      (input$type == "red") * 0.5
    center <- max(3, min(9, round(center)))
    
    probs <- dnorm(3:9, mean = center, sd = 1)
    probs <- probs / sum(probs)
    
    prediction$quality <- as.character(center)
    prediction$probs <- probs
    
    # Show notification
    showNotification("Quality prediction completed!", 
                     type = "message", 
                     duration = 3)
  })
  
  # Output predicted quality
  output$predicted_quality <- renderText({
    if (is.null(prediction$quality)) {
      "?"
    } else {
      prediction$quality
    }
  })
  
  # Output quality stars
  output$quality_stars <- renderText({
    if (!is.null(prediction$quality)) {
      stars <- as.numeric(prediction$quality)
      full_stars <- floor(stars)
      paste0(paste(rep("★", full_stars), collapse = ""),
             paste(rep("☆", 10 - full_stars), collapse = ""))
    } else {
      "☆☆☆☆☆☆☆☆☆☆"
    }
  })
  
  # Output confidence text
  output$confidence_text <- renderText({
    if (!is.null(prediction$probs)) {
      max_prob <- max(prediction$probs)
      confidence <- ifelse(max_prob > 0.6, "High Confidence",
                           ifelse(max_prob > 0.3, "Moderate Confidence", 
                                  "Low Confidence"))
      paste0("Model Confidence: ", round(max_prob * 100, 1), "% (", confidence, ")")
    } else {
      "Adjust wine attributes and click 'Predict'"
    }
  })
  
  # Create probability plot
  output$prob_plot <- renderPlot({
    if (!is.null(prediction$probs)) {
      quality_levels <- 3:9
      
      # Create gradient colors for bars
      colors <- ifelse(quality_levels == as.numeric(prediction$quality), 
                       "#722f37", "#d4a574")
      
      # Set up the plot with proper y-axis
      par(las = 1)  # Ensure horizontal labels
      
      barplot(prediction$probs,
              names.arg = quality_levels,
              col = colors,
              border = NA,
              ylim = c(0, max(prediction$probs) * 1.2),
              ylab = "Probability",
              xlab = "Wine Quality Score",
              main = "Probability Distribution",
              yaxt = "n")  # Suppress default y-axis
      
      # Add custom y-axis with horizontal labels only
      axis(2, las = 1)
      
      # Add grid lines
      abline(h = seq(0, 1, 0.1), col = "gray90", lty = 2)
      
      # Redraw bars over grid
      barplot(prediction$probs,
              names.arg = quality_levels,
              col = colors,
              border = NA,
              add = TRUE)
      
      # Add percentage labels
      text(x = seq(0.7, by = 1.2, length.out = 7),
           y = prediction$probs + 0.02,
           labels = paste0(round(prediction$probs * 100, 1), "%"),
           pos = 3,
           cex = 0.9,
           font = 2)
    } else {
      plot.new()
      text(0.5, 0.5, "No prediction yet", cex = 1.5, col = "gray50")
    }
  })
  
  # Display model information
  output$model_info <- renderPrint({
    if (!is.null(prediction$quality)) {
      cat("PREDICTED QUALITY:", prediction$quality, "\n")
      cat("Maximum Probability:", round(max(prediction$probs) * 100, 2), "%\n\n")
      cat("Input Wine Characteristics:\n")
      cat("========================\n")
      cat("Type:", input$type, "\n")
      cat("Location:", input$location, "\n")
      cat("Free SO2 Ratio:", round(prediction$so2_ratio, 4), "\n\n")
      cat("Chemical Properties (Original):\n")
      cat("Fixed Acidity:", input$fixed.acidity, "g/L\n")
      cat("Volatile Acidity:", input$volatile.acidity, "g/L\n")
      cat("Alcohol:", input$alcohol, "% vol\n")
    } else {
      cat("No prediction yet.\n")
      cat("Adjust the wine attributes and click 'Predict'.\n\n")
      cat("This model uses the ordinal logit approach\n")
      cat("with normalized chemical properties.")
    }
  })
  
  # Display normalization details
  output$normalization_info <- renderPrint({
    if (!is.null(prediction$normalized_values)) {
      cat("Normalized Values (mean=0, sd=1):\n")
      cat("=================================\n")
      for (i in 1:length(prediction$normalized_values)) {
        cat(sprintf("%-20s: %+.4f\n", 
                    names(prediction$normalized_values)[i], 
                    prediction$normalized_values[[i]]))
      }
      cat("\nFree SO2 Ratio: ", round(prediction$so2_ratio, 4), " (not normalized)\n")
      cat("\nNote: Values normalized by appending to training data\n")
      cat("and applying scale() to maintain consistency.")
    } else {
      cat("Normalization details will appear here after prediction.\n\n")
      cat("Process:\n")
      cat("1. Your input values are appended to the training dataset\n")
      cat("2. The free.SO2.ratio is calculated\n")
      cat("3. All numeric variables are normalized using scale()\n")
      cat("4. The normalized values are extracted for model prediction")
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)