library(readr)


run_quiz <- function(Node = "", csvFile = ".questions.csv") {
  library(shiny)
  library(stringr)
  
  # If you don't have a .ref.csv file, remove or comment out these lines
  ref <- SupressWarnings(read.csv(".ref.csv", stringsAsFactors = FALSE))
  title <- ref[1, Node]
  
  # If you do not need a title from a .ref.csv, just define a static title:
  title <- paste("Quiz for", title)
  
  ###########################################################################
  # UI
  ###########################################################################
  ui <- fluidPage(
    titlePanel(title),
    br(),
    
    # Display the current question
    htmlOutput("questionText"),
    
    # Dropdown for selecting an answer
    selectInput("answer", "Select your answer:", choices = c("A", "B", "C", "D")),
    
    # Action buttons
    fluidRow(
      column(width = 2, actionButton("nextQ", "Next Question")),
      column(width = 2, actionButton("submitFinal", "Submit Quiz")),
      column(width = 2, actionButton("reset", "Reset"))
    ),
    br(), br(),
    
    # Display a message when all questions have been answered (but not yet submitted)
    textOutput("allDoneMsg"),
    
    br(), br(),
    tableOutput("resultsTable"),
    textOutput("scoreText")
  )
  
  ###########################################################################
  # Server
  ###########################################################################
  server <- function(input, output, session) {
    # Reactive expression for reading the entire CSV
    full_df <- reactive({
      SupressWarningsread.csv(csvFile, stringsAsFactors = FALSE))
    })
    
    # Subset for the chosen Node
    sub_df <- reactive({
      subset(full_df(), node == Node & type == "mcq")
    })
    
    # Store the quiz state
    rvals <- reactiveValues(
      df = NULL,             # The subset for this Node
      questionIndex = 1,     # Current question index
      userAnswers = NULL,    # Vector storing the user's answers
      showResults = FALSE,   # Whether to display final results
      allDone = FALSE        # Flag to indicate all questions answered
    )
    
    # Reset or init the quiz
    resetQuiz <- function() {
      dfSubset <- sub_df()
      
      if (nrow(dfSubset) == 0) {
        showModal(modalDialog(
          title = "No Questions Found",
          paste("No questions found for Node =", Node),
          easyClose = TRUE
        ))
        return(NULL)
      }
      
      # Ensure the 'correct' column exists in the dataset
      if (!"correct" %in% colnames(dfSubset)) {
        dfSubset$correct <- rep(NA_integer_, nrow(dfSubset))
      }
      
      # Keep the original order, no shuffling
      rvals$df <- dfSubset
      rvals$questionIndex <- 1
      rvals$userAnswers <- rep(NA_character_, nrow(dfSubset))
      rvals$showResults = FALSE
      rvals$allDone = FALSE
    }
    
    # Call reset on start
    observeEvent(sub_df(), {
      resetQuiz()
    }, ignoreInit = FALSE)
    
    # If user hits Reset, do it again
    observeEvent(input$reset, {
      resetQuiz()
    })
    
    # Next Question button
    observeEvent(input$nextQ, {
      # Save current selection
      rvals$userAnswers[rvals$questionIndex] <- input$answer
      
      # If not the last question, move to the next
      if (rvals$questionIndex < nrow(rvals$df)) {
        rvals$questionIndex <- rvals$questionIndex + 1
      } else {
        # We've reached the last question
        rvals$allDone <- TRUE
      }
    })
    
    # Submit Quiz button
    observeEvent(input$submitFinal, {
      # Make sure we save the user's last choice
      rvals$userAnswers[rvals$questionIndex] <- input$answer
      
      # Store user's answers
      rvals$df$submitted <- rvals$userAnswers
      
      # Check correctness and assign 1 if correct
      rvals$df$result <- ifelse(rvals$df$submitted == rvals$df$correct, 1, 0)
      
      # Show the results
      rvals$showResults <- TRUE
      
      # Overwrite only the relevant rows in .questions.csv
      dfAll <- full_df()
      idx <- which(dfAll$node == Node)
      dfAll$submitted[idx] <- rvals$df$submitted
      dfAll$correct[idx] <- rvals$df$correct  # Save correctness column
      
      write.csv(dfAll, csvFile, row.names = FALSE)
    })
    
    # Display the current question or a final message
    output$questionText <- renderUI({
      if (!rvals$showResults) {
        HTML(rvals$df$question[rvals$questionIndex])
      } else {
        HTML("<strong>All questions answered!</strong>")
      }
    })
    
    # Display a message if we're at the last question but not yet submitted
    output$allDoneMsg <- renderText({
      if (rvals$allDone && !rvals$showResults) {
        "All done. Submit the quiz to see your results."
      } else {
        ""
      }
    })
    
    # Show final table after submission
    output$resultsTable <- renderTable({
      if (rvals$showResults) {
        data.frame(
          Question = rvals$df$question,
          Correct_Answer = rvals$df$correct,
          Submitted = rvals$df$submitted,
          stringsAsFactors = FALSE
        )
      }
    }, sanitize.text.function = function(x) x)
    
    # Final score text
    output$scoreText <- renderText({
      if (rvals$showResults) {
        correctCount <- sum(rvals$df$result, na.rm = TRUE)
        totalQ <- nrow(rvals$df)
        perc <- round(100 * correctCount / totalQ, 2)
        paste0("Your final score: ", correctCount, "/", totalQ, " (", perc, "%)")
      }
    })
  }
  
  ###########################################################################
  # Run the App
  ###########################################################################
  shinyApp(ui = ui, server = server,options = list(height = 400))
}


complete_path <- function(Node = "Node1") {
  ui <- fluidPage(
    h3("Click here to record your progress:"),
    actionButton("update", "Update"),
    br(), br(),
    textOutput("status")
  )
  
  server <- function(input, output, session) {
    observeEvent(input$update, {
      # 1. Read .ref.csv
      ref <- SuppressWarnings(read.csv(".ref.csv", stringsAsFactors = FALSE))
      
      # 2. Ensure the column exists
      if (!Node %in% colnames(ref)) {
        output$status <- renderText(
          paste("ERROR: Column", Node, "not found in .ref.csv!")
        )
        return(NULL)
      }
      
      # 3. Update row 2 -> 1, row 3 -> today's date
      ref[2, Node] <- 1
      ref[3, Node] <- format(Sys.Date(), "%Y-%m-%d")
      
      # 4. Overwrite the .ref.csv file
      write.csv(ref, ".ref.csv", row.names = FALSE)
      
      # 5. Display a confirmation in the app
      output$status <- renderText("Progress recorded!")
    })
  }
  shinyApp(ui, server, options = list(height = 130))
}

displayQuestion <- function(title, 
                            qvalue="answer <-", 
                            nrows=5,
                            positive = "✅ Correct! Well done.",
                            negative = "❌ Try again. Check your calculation.",
                            question, 
                            Node, 
                            csvFile = ".questions.csv") {
  
  if (!is.null(question) && !is.null(Node)) {
    quest <- SupressWarningsread.csv(csvFile, stringsAsFactors = FALSE))
    subs <- subset(quest, node == Node & type == question)
    
    # Ensure there's at least one question available
    if (nrow(subs) == 0) {
      stop("No questions found for the given Node and Question type.")
    }
    
    question_text <- subs$question[1]
  } else {
    question_text <- "Write and execute your R code below:"
  }
  
  ui <- fluidPage(
    titlePanel(title),
    
    # User-editable R code
    textAreaInput("user_code", label = subs$question[1], 
                  value = qvalue,
                  rows = nrows, width = "100%"),
    
    actionButton("run_code", "Submit Answer"),
    
    verbatimTextOutput("code_output"),  # Show user output
    verbatimTextOutput("feedback")      # Show feedback if correct
  )
  
  server <- function(input, output, session) {
    full_df <- reactive({
      SuppressWarnings(read.csv(csvFile, stringsAsFactors = FALSE))
    })
    
    user_result <- reactive({
      input$run_code
      isolate({
        tryCatch({
          eval(parse(text = input$user_code), envir = .GlobalEnv)
        }, error = function(e) return(paste("Error:", e$message)))
      })

    
    output$code_output <- renderPrint({ user_result() })
    
    if (is.null(question) || is.null(Node)) return()
    
    output$feedback <- renderPrint({
      subtmp <- subs  # Use the filtered dataset
      expected_value <- tryCatch({
        eval(parse(text = subtmp$correct[1]), envir = .GlobalEnv)
      }, error = function(e) return(NA))
      
      # Ensure the expected value exists
      if (!is.null(user_result()) && !is.na(expected_value) && identical(user_result(), expected_value)) {
        subm_quest <- full_df()
        subm_quest[subm_quest$node == Node & subm_quest$type == question, "result"] <- 1
        write.csv(subm_quest, csvFile, row.names = FALSE)
        return(positive)
      } else {
        subm_quest <- full_df()
        subm_quest[subm_quest$node == Node & subm_quest$type == question, "result"] <- 0
        write.csv(subm_quest, csvFile, row.names = FALSE)
        return(negative)
      }
    })
    })
  }
  
  shinyApp(ui, server, options = list(height = 200+(23*nrows)))
}


userCode <- function(title, 
                            qvalue="answer <-", 
                            nrows=5,
                     question_text = NULL) {
  # Define UI
  ui <- fluidPage(
    titlePanel(title),
    
    # User-editable R code
    textAreaInput("user_code", label = question_text, 
                  value = qvalue,
                  rows = nrows, width = "100%"),
    
    actionButton("run_code", "Run Code"),
    
    verbatimTextOutput("code_output") 
  )
  
  # Define Server
  server <- function(input, output, session) {
    user_result <- reactive({
      input$run_code
      isolate({
        tryCatch({
          eval(parse(text = input$user_code), envir = .GlobalEnv)
        }, error = function(e) return(paste("Error:", e$message)))
      })
    })
    
    output$code_output <- renderPrint({ user_result() })
  }
  
  # Run the Shiny App
  shinyApp(ui, server, options = list(height = 200 + (23 * nrows)))
}
footer <- function() {
  # Read CSV once
  ref_data <- SuppressWarnings(read.csv(".ref.csv", stringsAsFactors = FALSE))
  
  # Extract values (assuming row 1 is the correct one)
  creator <- ref_data[1, "creator"]
  link <- ref_data[2, "creator"]
  charity <- ref_data[1, "charity"]
  charitylink <- ref_data[2, "charity"]
  
  # Generate footer HTML
  footer_html <- sprintf("
  <wimr><br>
  <div class='custom-footer'>
  <div class='footer-left'>
  <a href='https://paypal.me/drthomasoneil?country.x=AU&locale.x=en_AU' target='_blank'>
  <strong>Support the Creator of<br>
  <span style='font-size:2em'>SkillTree</span></strong>
  </a>
  </div>

  <div class='footer-center'>
  <strong><span style='font-size:2em'>Node Created by</span></strong><br>
  <a href='%s' target='_blank'>
  <span style='font-size:1.3em'>%s</span>
  </a>
  </div>

  <div class='footer-right'>
  <p>
  <span style='font-size:1.3em'><strong>Support the Creator's<br>Chosen Charity:</strong></span><br>
  <a href='%s' target='_blank'>
  <span style='font-size:2em'>%s</span>
  </a>
  </p>
  </div>

  </div>
  <br><hr><br>
  ", link, creator, charitylink, charity)
  
  # Output the HTML
  cat(footer_html)
}
