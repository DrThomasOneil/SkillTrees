library(readr)


run_quiz <- function(Node = "", 
                     csvFile = ".questions.csv", 
                     show_answers=T) {
  library(shiny)
  library(stringr)
  
  # If you have a .ref.csv that can provide a title:
  # if you do not need it, you can comment out these lines
  ref <- suppressWarnings(read.csv(".ref.csv", stringsAsFactors = FALSE))
  titleVal <- if (!Node %in% colnames(ref)) {
    # fallback if Node not found in ref
    paste("Quiz for", Node)
  } else {
    paste("Quiz for", ref[1, Node])
  }
  
  ###########################################################################
  # UI
  ###########################################################################
  ui <- fluidPage(
    titlePanel(titleVal),
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
    # 1) Read the entire CSV
    full_df <- reactive({
      suppressWarnings(read.csv(csvFile, stringsAsFactors = FALSE))
    })
    
    # 2) Subset for the chosen Node with type == "mcq"
    #    Also store the original row indices
    sub_df <- reactive({
      dfAll <- full_df()
      # which(...) finds the row indices
      theseRows <- which(dfAll$node == Node & dfAll$type == "mcq")
      if (length(theseRows) == 0) {
        return(data.frame())
      }
      
      # Make a subset
      dfSubset <- dfAll[theseRows, , drop = FALSE]
      # Store original row indices so we can write back exactly
      dfSubset$origIndex <- theseRows
      dfSubset
    })
    
    # 3) Reactive values for quiz state
    rvals <- reactiveValues(
      df = NULL,             # The subset for this Node (including origIndex)
      questionIndex = 1,     # Current question index
      userAnswers = NULL,    # Vector storing the user's answers
      showResults = FALSE,   # Whether to display final results
      allDone = FALSE        # Flag to indicate all questions answered
    )
    
    # Helper function to reset to the beginning
    resetQuiz <- function() {
      dfSubset <- sub_df()
      
      if (nrow(dfSubset) == 0) {
        showModal(modalDialog(
          title = "No Questions Found",
          paste("No MCQ questions found for Node =", Node),
          easyClose = TRUE
        ))
        return(NULL)
      }
      
      # Ensure the 'correct' column exists
      if (!"correct" %in% colnames(dfSubset)) {
        dfSubset$correct <- rep(NA_character_, nrow(dfSubset))
      }
      # Also ensure there's a 'submitted' col, optionally
      if (!"submitted" %in% colnames(dfSubset)) {
        dfSubset$submitted <- rep(NA_character_, nrow(dfSubset))
      }
      
      # Keep the original order, no shuffling
      rvals$df <- dfSubset
      rvals$questionIndex <- 1
      rvals$showResults <- FALSE
      rvals$allDone <- FALSE
      rvals$userAnswers <- rep(NA_character_, nrow(dfSubset))
    }
    
    # Call reset on start
    observeEvent(sub_df(), {
      resetQuiz()
    }, ignoreInit = FALSE)
    
    # If user hits Reset
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
      # Save the user's final answer for the current question
      rvals$userAnswers[rvals$questionIndex] <- input$answer
      
      # Fill the 'submitted' column in rvals$df
      rvals$df$submitted <- rvals$userAnswers
      
      # If there's a 'correct' col, we can check correctness
      rvals$df$result <- ifelse(rvals$df$submitted == rvals$df$correct, 1, 0)
      
      # Indicate final results
      rvals$showResults <- TRUE
      
      # 4) Write back EXACT rows in the main CSV
      dfAll <- full_df()
      
      # For each row in rvals$df, we have an original index in 'origIndex'
      # We'll write the 'submitted' and 'correct' columns back
      for (i in seq_len(nrow(rvals$df))) {
        orig <- rvals$df$origIndex[i]
        dfAll$submitted[orig] <- rvals$df$submitted[i]
        dfAll$correct[orig]   <- rvals$df$correct[i]
      }
      
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
    
    # Display a message if all Qs are done but not yet submitted
    output$allDoneMsg <- renderText({
      if (rvals$allDone && !rvals$showResults) {
        "All done. Submit the quiz to see your results."
      } else {
        ""
      }
    })
    
    # Show final table after submission
    if(show_answers){
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
    }

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
  shinyApp(ui = ui, server = server, options = list(height = 400))
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
      ref <- suppressWarnings(read.csv(".ref.csv", stringsAsFactors = FALSE))
      
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
      
      # 5. Read questions
      qu <- suppressWarnings(read.csv(".questions.csv"), row)
      for (i in seq_len(nrow(qu))) {
        if (qu$type[i] == "mcq" && qu$node[i] == Node) {
          # Compare correct vs. submitted
          if (qu$correct[i] == qu$submitted[i]) {
            qu$result[i] <- 1
          } else {
            qu$result[i] <- 0
          }
        } else if (qu$type[i] != "mcq" && qu$node[i] == Node) {
          qu$result[i] <- 1
        }
      }
      write.csv(qu, ".questions.csv", row.names = FALSE)
      
      # Display a confirmation in the app
      output$status <- renderText("Progress recorded!")
    })
  }
  shinyApp(ui, server, options = list(height = 130))
}

displayQuestion <- function(title,
                            qvalue="answer <-",
                            nrows=5,
                            positive = "✅ Correct! Well done.",
                            negative = "❌ Try again. Check your answer",
                            question,
                            Node,
                            csvFile = ".questions.csv") {
  if (!is.null(question) && !is.null(Node)) {
    quest <- suppressWarnings(read.csv(csvFile, stringsAsFactors = FALSE))
    
    # We might have multiple rows with the same node & type == question.
    # We'll pick the first row for display.
    rowsMatching <- which(quest$node == Node & quest$type == question)
    
    if (length(rowsMatching) == 0) {
      stop("No questions found for the given Node and Question type.")
    }
    
    # We'll store the index of that single row
    singleIndex <- rowsMatching[1]
    
    # Extract the question text
    question_text <- quest$question[singleIndex]
  } else {
    question_text <- "Write and execute your R code below:"
    singleIndex <- NA  # We'll ignore if there's no question
  }
  
  ui <- fluidPage(
    titlePanel(title),
    
    # User-editable R code
    textAreaInput("user_code", label = question_text,
                  value = qvalue,
                  rows = nrows, width = "100%"),
    
    actionButton("run_code", "Submit Answer"),
    
    verbatimTextOutput("code_output"),  # Show user output
    verbatimTextOutput("feedback")      # Show feedback if correct
  )
  
  server <- function(input, output, session) {
    # We'll read the full CSV on the fly
    full_df <- reactive({
      suppressWarnings(read.csv(csvFile, stringsAsFactors = FALSE))
    })
    
    # Evaluate user code
    user_result <- reactive({
      input$run_code
      isolate({
        tryCatch({
          eval(parse(text = input$user_code), envir = .GlobalEnv)
        }, error = function(e) {
          return(paste("Error:", e$message))
        })
      })
    })
    
    output$code_output <- renderPrint({
      user_result()
    })
    
    # If question or node is NULL, we skip the feedback logic
    if (is.null(question) || is.null(Node)) return()
    
    output$feedback <- renderPrint({
      dfAll <- full_df()
      
      # Check if singleIndex is valid
      if (is.na(singleIndex) || singleIndex < 1 || singleIndex > nrow(dfAll)) {
        return("Internal error: question row index is invalid.")
      }
      
      # Extract the expected 'correct' expression from that row
      # If 'correct' doesn't exist, we skip the check
      if (!"correct" %in% colnames(dfAll)) {
        return("No 'correct' column found in questions CSV.")
      }
      
      # Evaluate the correct expression in .GlobalEnv
      expected_value <- tryCatch({
        eval(parse(text = dfAll$correct[singleIndex]), envir = .GlobalEnv)
      }, error = function(e) {
        return(NA)
      })
      
      # Compare user's result with expected_value
      user_val <- user_result()
      
      # If user_val is exactly the same as expected_value => correct
      # We'll store 1 or 0 in 'result' column for that single row
      if (!is.null(user_val) && !is.na(expected_value) && identical(user_val, expected_value)) {
        return(positive)
      } else {
        return(negative)
      }
    })
  }
  
  shinyApp(ui, server, options = list(height = 200 + (23*nrows)))
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
  ref_data <- suppressWarnings(read.csv(".ref.csv", stringsAsFactors = FALSE))
  
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
