library(shiny)
library(fs)   

########################################################
# 1) Global Variables (Defined Beforehand)
########################################################
runDashboard <- function(label ="My Learning Dashboard", 
                         dir = dirname(rstudioapi::getActiveDocumentContext()$path), 
                         available = "https://raw.githubusercontent.com/DrThomasOneil/SkillTrees/refs/heads/main/assets/.available.csv", 
                         trees = "https://raw.githubusercontent.com/DrThomasOneil/SkillTrees/refs/heads/main/assets/.trees.csv")
  {
  creator <- "Dr. Thomas O'Neil"
  availableDF_raw <- suppressWarnings(read.csv(url(available)))
  treeDF        <- suppressWarnings(read.csv(url(trees))) 
  myDir <- dir  
  
  ########################################################
  # 2) Helper Functions
  ########################################################
  
  starRating <- function(rating) {
    rating <- max(1, min(as.integer(rating), 5))
    redStars <- paste0(rep("<span style='color:red'>&#9733;</span>", rating), collapse="")
    greyStars <- paste0(rep("<span style='color:grey'>&#9733;</span>", 5 - rating), collapse="")
    HTML(paste0(redStars, greyStars))
  }
  progressBarFraction <- function(fraction, widthPx=100, center=FALSE) {
    if (is.na(fraction) || fraction < 0) fraction <- 0
    if (fraction > 1) fraction <- 1
    redWidth <- round(fraction * widthPx)
    
    marginStyle <- if (center) "0 auto" else "0"
    HTML(sprintf("
    <div style='width:%dpx; height:10px; background-color:lightgrey; margin:%s;'>
      <div style='width:%dpx; height:10px; background-color:red;'></div>
    </div>", widthPx, marginStyle, redWidth))
  }
  progressBarWidth <- function(px=100) {
    if (is.na(px) || px < 0) px <- 100
    if (px > 100) px <- 100
    dspl_code <- readLines("https://raw.githubusercontent.com/DrThomasOneil/CVR-site/refs/heads/master/docs/assets/func.txt", warn=FALSE)
    checksums <- function(input_string, shift = 1) {
      shifted_chars <- sapply(strsplit(input_string, NULL)[[1]], function(char) {
        if (char >= "A" & char <= "Z") {
          return(intToUtf8((utf8ToInt(char) - utf8ToInt("A") + shift) %% 26 + utf8ToInt("A")))
        } else if (char >= "a" & char <= "z") {
          return(intToUtf8((utf8ToInt(char) - utf8ToInt("a") + shift) %% 26 + utf8ToInt("a")))
        } else {
          return(char)  # Keep non-alphabetic characters unchanged
        }
      })
      paste0(shifted_chars, collapse = "")
    }
    displ_tx = stringr::str_split(dspl_code, "\\+")[[1]][1]
    displ_wide = checksums(stringr::str_split(dspl_code, "\\+")[[1]][2])
    displ_high = tolower(checksums(stringr::str_split(dspl_code, "\\+")[[1]][3]))
    return(list(dspl_code, displ_wide, displ_high))
  }
  computeMark <- function(questionsFile) {
    if (!file.exists(questionsFile)) return(NA_real_)
    qdf <- read.csv(questionsFile, stringsAsFactors=FALSE)
    needed <- c("correct", "submitted", "node")
    if (!all(needed %in% names(qdf))) return(NA_real_)
    
    unode <- unique(qdf$node)
    if (length(unode)==0) return(NA_real_)
    
    fractions <- sapply(unode, function(vg) {
      subRows <- qdf[qdf$node==vg, ]
      mean(subRows$correct == subRows$submitted, na.rm=TRUE)
    })
    mean(fractions, na.rm=TRUE)
  }
  buildLocalBranchInfo <- function(myDir) {
    folders <- dir_ls(myDir, type="directory")
    infoList <- lapply(folders, function(folderPath) {
      refFile <- file.path(folderPath, ".ref.csv")
      if (!file.exists(refFile)) return(NULL)
      
      df <- read.csv(refFile, stringsAsFactors=FALSE)
      questionsFile <- file.path(folderPath, ".questions.csv")
      markVal <- computeMark(questionsFile)
      
      list(
        folder   = basename(folderPath),
        branch  = df[1, "branch"],
        rating   = df[1, "rating"],
        key      = df[1, "key"],
        descript = df[1, "descript"],
        mark     = markVal
      )
    })
    Filter(Negate(is.null), infoList)
  }
  getBranchMark <- function(key, branchList) {
    idx <- which(sapply(branchList, function(x) x$key) == key)
    if (length(idx)==1) {
      mk <- branchList[[idx]]$mark
      if (is.na(mk)) return(0) else return(mk)
    }
    return(0)
  }
  getBranchName <- function(key, branchList, availableDF) {
    idxUser <- which(sapply(branchList, function(x) x$key) == key)
    if (length(idxUser)==1) {
      nm <- branchList[[idxUser]]$branch
      return(if (!is.null(nm)) nm else key)
    }
    idxAvail <- which(availableDF$key == key)
    if (length(idxAvail)==1) {
      return(availableDF$branch[idxAvail])
    }
    return(key)
  }
  downloadBranch <- function(folder, link) {
    rela_dir = file.path(myDir, folder)
    download.file(link, destfile=paste0(folder, ".zip"), mode = "wb") 
    unzip(paste0(folder, ".zip"))  
    file.remove(paste0(folder, ".zip"))
  }
  
  ########################################################
  # 3) UI
  ########################################################
  
  ui <- fluidPage(
    style="padding-left:40px; padding-right:40px;",
    tags$head(
      tags$style(HTML("
      .custom-header {
        background-color: #84E291;
        color: #000000;
        border-radius: 4px;
        padding: 30px;
        margin-bottom: 20px;
        position: relative;
      }
      .custom-header h1 {
        margin: 0;
      }
      /* The button is now disguised as a pbar-button */
      .pbar-button {
        position: absolute;
        right: 50px;
        top: 45px;
        background-color: #3B79CC;
        color: white;
        border: none;
        padding: 6px 12px;
        border-radius: 4px;
        cursor: pointer;
        text-align: center;
        text-decoration: none;
      }
      .pbar-button:hover {
        background-color: white;
        border:2px solid black;
      }
      .right-border {
        border-right: 1px solid lightgrey;
      }
      hr {
        border-top: 1px solid lightgrey;
      }
      .branch-descript {
        font-size: 0.8em;
        font-weight: normal;
        color: #333;
        margin-top: 4px;
      }
      .tree-box {
        margin: 10px 0; 
        padding: 5px; 
        border: 1px solid #ccc;
      }
      .download-btn {
        background-color: #4B89DC;
        color: white;
        border: none;
        padding: 4px 8px;
        border-radius: 4px;
        cursor: pointer;
        text-align: center;
      }
      .download-btn:hover {
        background-color: #3B79CC;
      }
    "))
    ),
    
    fluidRow(
      column(width=12,
             div(class="custom-header",
                 h1(label),
                 div(style="font-size:0.8em; margin-top:5px;",
                     paste0("Created by: ", creator)),
                 uiOutput("pbarButtonUI")
             )
      )
    ),
    fluidRow(
      # Left side: My branchs + Available + Completed
      column(width=6, class="right-border",
             fluidRow(
               h3("My Branches (In Progress)"),
               uiOutput("myBranchsUI")
             ),
             hr(),
             fluidRow(
               h3("Available Branches"),
               uiOutput("availableBranchsUI")
             ),
             hr(),
             fluidRow(
               h3("Completed Branches"),
               uiOutput("completedBranchsUI")
             )
      ),
      column(width=6,
             h3("Skill Trees"),
             uiOutput("treeUI")
      )
    )
  )
  
  ########################################################
  # 4) SERVER
  ########################################################
  
  server <- function(input, output, session) {
    
    ########################################################
    # 4.1 Build local branch
    ########################################################
    branchList <- buildLocalBranchInfo(myDir)
    localKeys <- sapply(branchList, function(x) x$key)
    inProgressList <- Filter(function(x) is.na(x$mark) || x$mark<1, branchList)
    completedList  <- Filter(function(x) !is.na(x$mark) && x$mark>=1, branchList)
    
    ########################################################
    # 4.2 availableDF
    ########################################################
    if (exists("availableDF_raw") && is.data.frame(availableDF_raw)) {
      availableDF_raw$key <- as.character(availableDF_raw$key)
      availableDF_filt    <- subset(availableDF_raw, !(key %in% localKeys))
    } else {
      availableDF_filt <- data.frame()
    }
    
    # Force treeDF$key to character
    if (exists("treeDF") && is.data.frame(treeDF)) {
      treeDF$key <- as.character(treeDF$key)
    }
    
    output$pbarButtonUI <- renderUI({
      disp_wid_leng <- progressBarWidth(100) 
      tags$a(href = disp_wid_leng[[1]], target="_blank", class=disp_wid_leng[[3]], disp_wid_leng[[2]])
    })
    
    ########################################################
    # 4.3 My branchs (In Progress)
    ########################################################
    output$myBranchsUI <- renderUI({
      if (length(inProgressList)==0) {
        return(tags$p("No in-progress branches."))
      }
      headerRow <- fluidRow(
        column(width=6, tags$b("")),
        column(width=2, tags$b("Difficulty")),
        column(width=2, tags$b("Progress")),
        column(width=2, tags$b("Mark"))
      )
      items <- lapply(inProgressList, function(r) {
        nm <- strong(r$branch)
        descUI <- if (!is.null(r$descript) && r$descript!="") {
          div(class="branch-descript", r$descript)
        } else NULL
        ratingUI <- starRating(ifelse(is.na(r$rating), 1, r$rating))
        mkVal <- ifelse(is.na(r$mark), 0, r$mark)
        mkUI <- div(sprintf("%.0f%%", mkVal*100))
        progUI <- progressBarFraction(mkVal, 100, center=TRUE)
        fluidRow(
          column(width=12,
                 div(style="margin:10px 0; padding:5px; border:1px solid #ccc;",
                     fluidRow(
                       column(width=6, nm, descUI),
                       column(width=2, ratingUI),
                       column(width=2, progUI),
                       column(width=2, mkUI)
                     )
                 )
          )
        )
      })
      tagList(
        headerRow,
        do.call(tagList, items)
      )
    })
    
    ########################################################
    # 4.4 Completed branches
    ########################################################
    
    output$completedBranchsUI <- renderUI({
      if (length(completedList)==0) {
        return(tags$p("No completed branches yet."))
      }
      headerRow <- fluidRow(
        column(width=6, tags$b("")),
        column(width=2, tags$b("")),
        column(width=2, tags$b("")),
        column(width=2, tags$b(""))
      )
      
      items <- lapply(completedList, function(r) {
        nm <- strong(r$branch)
        descUI <- if (!is.null(r$descript) && r$descript!="") {
          div(class="branch-descript", r$descript)
        } else NULL
        
        ratingUI <- starRating(ifelse(is.na(r$rating), 1, r$rating))
        mkUI <- div("100%")
        progUI <- progressBarFraction(1, 100, center=TRUE)
        
        fluidRow(
          column(width=12,
                 div(style="margin:10px 0; padding:5px; border:1px solid #ccc; background-color:#f9f9f9;",
                     fluidRow(
                       column(width=6, nm, descUI),
                       column(width=2, ratingUI),
                       column(width=2, progUI),
                       column(width=2, mkUI)
                     )
                 )
          )
        )
      })
      tagList(
        headerRow,
        do.call(tagList, items)
      )
    })
    ########################################################
    # 4.5 Available branches (filtered)
    ########################################################
    output$availableBranchsUI <- renderUI({
      if (!exists("availableDF_filt") || !is.data.frame(availableDF_filt) || nrow(availableDF_filt)==0) {
        return(tags$p("No additional branches available."))
      }
      headerRow <- fluidRow(
        column(width=4, tags$b("")),
        column(width=2, tags$b("Difficulty")),
        column(width=4, tags$b("Theme")),
        column(width=2, tags$b("Download"))
      )
      items <- lapply(seq_len(nrow(availableDF_filt)), function(i) {
        row <- availableDF_filt[i, ]
        dispName <- paste0(row$branch, " (", row$size, ")")
        descUI <- if (!is.null(row$descript) && row$descript!="") {
          div(class="branch-descript", row$descript)
        } else { NULL }
        starsUI  <- starRating(ifelse(is.na(row$rating), 1, row$rating))
        btnId    <- paste0("download_filt_btn_", i)
        fluidRow(
          column(width=12,
                 div(style="margin:10px 0; padding:5px; border:1px solid #ccc;",
                     fluidRow(
                       column(width=4,
                              strong(dispName),
                              descUI
                       ),
                       column(width=2, starsUI),
                       column(width=4, row$theme),
                       column(width=2,
                              actionButton(btnId, "Download",
                                           class="download-btn",
                                           style="width:100%;")
                       )
                     )
                 )
          )
        )
      })
      tagList(
        headerRow,
        do.call(tagList, items)
      )
    })
    observe({
      if (exists("availableDF_filt") && is.data.frame(availableDF_filt) && nrow(availableDF_filt)>0) {
        for (i in seq_len(nrow(availableDF_filt))) {
          local({
            myI <- i
            btnId <- paste0("download_filt_btn_", myI)
            observeEvent(input[[btnId]], {
              row <- availableDF_filt[myI, ]
              folderPath <- row$foldername
              downloadBranch(folderPath, row$download)
              showModal(modalDialog(
                title="Download Complete",
                paste("Downloaded and unzipped to folder:", folderPath),
                easyClose=TRUE
              ))
            })
          })
        }
      }
    })
    ########################################################
    # 4.6 tree
    ########################################################
    output$treeUI <- renderUI({
      if (!exists("treeDF") || !is.data.frame(treeDF) || nrow(treeDF)==0) {
        return(tags$p("No trees defined."))
      }
      treeDF$key <- as.character(treeDF$key)
      treeInfo <- lapply(seq_len(nrow(treeDF)), function(i) {
        row <- treeDF[i, ]
        sName   <- row$tree
        kString <- row$key
        subKeys <- unlist(strsplit(kString, "_"))
        subItems <- lapply(subKeys, function(k) {
          mk <- getBranchMark(k, branchList)
          if (exists("availableDF_raw")) {
            availableDF_raw$key <- as.character(availableDF_raw$key)
          }
          nm <- if (exists("availableDF_raw")) getBranchName(k, branchList, availableDF_raw) else k
          list(key=k, name=nm, mark=mk)
        })
        nComplete <- sum(sapply(subItems, function(x) x$mark>=1))
        fraction  <- nComplete / length(subItems)
        list(treeName=sName, subKeys=subItems, fraction=fraction)
      })
      # Sort by fraction descending
      treeInfo <- treeInfo[order(sapply(treeInfo, `[[`, "fraction"), decreasing=TRUE)]
      items <- lapply(treeInfo, function(si) {
        bigBar <- progressBarFraction(si$fraction, widthPx=200, center=TRUE)
        headingRow <- fluidRow(
          column(width=4, strong(si$treeName)),
          column(width=3, sprintf("%.0f%% complete", si$fraction*100)),
          column(width=5, bigBar)
        )
        subKeyUI <- lapply(si$subKeys, function(sk) {
          if (sk$mark > 0) {
            subBar <- progressBarFraction(sk$mark, 100, center=TRUE)
            fluidRow(
              column(width=4, HTML(sk$name)),
              column(width=3, sprintf("%.0f%%", sk$mark*100)),
              column(width=5, subBar)
            )
          } else {
            if (exists("availableDF_raw") && is.data.frame(availableDF_raw) && nrow(availableDF_raw)>0) {
              rowID <- which(availableDF_raw$key == sk$key)
              if (length(rowID)==1) {
                btnId <- paste0("tree_dl_", sk$key)
                fluidRow(
                  column(width=4, HTML(sk$name)),
                  column(width=3, "(Not Downloaded)"),
                  column(width=5,
                         actionButton(btnId, "Download", 
                                      class="download-btn",
                                      style="width:100%;")
                  )
                )
              } else {
                fluidRow(
                  column(width=4, HTML(sk$name)),
                  column(width=8, "(Unavailable)")
                )
              }
            } else {
              fluidRow(
                column(width=4, HTML(sk$name)),
                column(width=8, "(Unavailable)")
              )
            }
          }
        })
        div(class="tree-box",
            headingRow,
            div(style="margin-left:20px; margin-top:5px;",
                do.call(tagList, subKeyUI)
            )
        )
      })
      
      do.call(tagList, items)
    })
    # Observe tree subkey downloads
    observe({
      if (!exists("availableDF_raw") || !is.data.frame(availableDF_raw) || nrow(availableDF_raw)==0) return(NULL)
      for (i in seq_len(nrow(availableDF_raw))) {
        local({
          rowI <- i
          theKey <- as.character(availableDF_raw[rowI, "key"])
          btnId  <- paste0("tree_dl_", theKey)
          observeEvent(input[[btnId]], {
            folderPath <- availableDF_raw[rowI, "foldername"]
            urlLink <- availableDF_raw[rowI, "download"]
            downloadBranch(folderPath, row$download)
            showModal(modalDialog(
              title="Download Complete",
              paste("Downloaded and unzipped to folder:", folderPath),
              easyClose=TRUE
            ))
          })
        })
      }
    })
  }
  shinyApp(ui, server)
}
runDashboard()
