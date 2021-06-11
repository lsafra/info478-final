# Final Deliverable Shiny App
library("shiny")
library("dplyr")
library("plotly")
library("shinythemes")
library(readxl)
library(tidyverse)
library(lintr)
source("app_ui.R")
source("app_server.R")

# Shiny App

shinyApp(ui = ui, server = server) 