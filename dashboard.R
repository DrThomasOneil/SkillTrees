# install packages if needed
#
#  install.packages("shinyalert")
#  install.packages("tidyverse")

source(url("https://raw.githubusercontent.com/DrThomasOneil/SkillTrees/refs/heads/main/assets/.dashboard.R"))
runDashboard(
  label ="My SkillTree Dashboard", 
  dir = dirname(rstudioapi::getActiveDocumentContext()$path), 
  available = "https://raw.githubusercontent.com/DrThomasOneil/SkillTrees/refs/heads/main/assets/.available.csv", # default location
  trees = "https://raw.githubusercontent.com/DrThomasOneil/SkillTrees/refs/heads/main/assets/.trees.csv" # default location
)
