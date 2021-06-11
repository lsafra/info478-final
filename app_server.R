# Final deliverable server
library(shiny)
library(plotly)
library(ggplot2)
library(stringr)
library(usmap)
GHED_data <- read_excel("data/GHED_data.XLSX")
unique_countries <- unique(GHED_data$country)
# health insurance coverage data
health_insurance_coverage <- read.csv("data/states.csv")
health_insurance_coverage <- rename(health_insurance_coverage,
                                    uninsured_2010=Uninsured.Rate..2010.,                              
                                    uninsured_2015=Uninsured.Rate..2015.,
                                    uninsured_change=Uninsured.Rate.Change..2010.2015.,
                                    avg_tax_2016=Average.Monthly.Tax.Credit..2016.,
                                    expansion=State.Medicaid.Expansion..2016.)
health_insurance_coverage$State <- str_trim(health_insurance_coverage$State)
us_states <- health_insurance_coverage$State
uninsured_2010 <- as.numeric(str_trim(
  str_remove(health_insurance_coverage$uninsured_2010, "%")))
uninsured_2015 <- as.numeric(str_trim(
  str_remove(health_insurance_coverage$uninsured_2015, "%")))

medicaid <- health_insurance_coverage$expansion
uninsured_2015_stripped <- as.numeric(str_trim(
  str_remove(health_insurance_coverage$uninsured_2015, "%")))

df <- data.frame(uninsured_2015_stripped, medicaid) %>%
  filter(medicaid == "True" | medicaid == "False") %>%
  group_by(medicaid) %>%
  summarise(uninsured=mean(uninsured_2015_stripped))

# map data cleaning
map_data <- health_insurance_coverage %>% 
  select(State, uninsured_2015, expansion) %>%
  filter(medicaid == "True" | medicaid == "False") 
map_data$uninsured_2015 <- as.numeric(str_trim(
  str_remove(map_data$uninsured_2015, "%")))
map_data$state <- str_trim(map_data$State)

server <- function(input, output) {
  output$chart <- renderPlotly({
    country_data <- GHED_data %>%
      filter(country == input$country_1 | country == input$country_2) %>%
      filter(year == input$year)
    
    GHED_data_che_gdp <- country_data %>%
       summarize(country, year, che_gdp, .groups = "drop")
    
    p <- ggplot(GHED_data_che_gdp) +
      geom_bar(stat='identity', fill = "cornflowerblue",
               mapping = aes(x = country, y = che_gdp)) +
      labs(
        title = "Comparing CHE%GDP Between Countries",
        subtitle = "",
        x = "Country",
        y = "CHE%GDP"
      )
    ggplotly(p)
  })
  
  output$chart2 <- renderPlotly({
    country_data <- GHED_data %>%
      filter(country == input$country_3)
    
    GHED_data_che_gdp <- country_data %>%
      summarize(country, year, che_pc_usd, .groups = "drop")
    
    p <- ggplot(GHED_data_che_gdp) +
      scale_x_continuous(limits = c(input$year_2, 2018)) +
      geom_smooth(mapping = aes(x = year, y = che_pc_usd)) +
      labs(
        title = "Comparing Health Expenditures per Capita",
        x = "Year",
        y = "Rate",
        color = "Country"
      )
    ggplotly(p)
  })
  
  output$chart3 <- renderPlotly({
    country_data <- GHED_data %>%
      filter(year == input$year_3) %>%
      filter(country == "United States of America" | country == input$country_4)
    
    GHED_data_che_gdp <- country_data %>%
      summarize(year, country, che_pc_usd, .groups = "drop")
    
    p <- ggplot(GHED_data_che_gdp) +
      geom_bar(stat='identity', fill = "deeppink",
               mapping = aes(x = country, y = che_pc_usd)) +
      labs(
        title = "Comparing CHE per Capita Across Countries",
        x = "Year",
        y = "CHE per Capita in USD"
      )
    ggplotly(p)
  })
  
  output$uninsurance <- renderPlotly({

    
    health_insurance <- data.frame(State=health_insurance_coverage$State,
                                   uninsured_2010, uninsured_2015) %>%
      filter(State == input$state_1 | State == input$state_2
             | State == input$state_3 | State == input$state_4
             | State == "United States") %>%
      pivot_longer(
        cols = starts_with("uninsured_"),
        names_to = "Year",
        values_to = "Uninsured"
      )
    health_insurance$Year <- str_remove(health_insurance$Year, "uninsured_")
    
    p <- ggplot(data=health_insurance, aes(x=State, y=Uninsured)) +
      geom_col(aes(fill=Year), position=position_dodge(), width=0.9) +
      labs(title="Uninsurance Rate by State, Compared Across Years",
           subtitle = "", y="Uninsurance Rate (%)") +
      theme(axis.text.x = element_text(angle = 20))
    
    ggplotly(p)
  })
  
  output$medicaid_bar <- renderPlotly({

      ggplot(data=df, aes(x=uninsured, y=medicaid)) +
      geom_col(fill="cornflowerblue", width=0.5) +
      labs(title="Medicaid Expansion vs. Percent Uninsured",
           y="Medicaid Expansion", x="Uninsured in 2015 (%)")
  })
  
  output$map1 <- renderPlotly({
    
    plot_usmap(data=map_data, values = "uninsured_2015", regions = "states") + 
      scale_fill_continuous(low="white", high="red", name="Uninsurance Rate") +
      theme(legend.position = "right") +
      labs(title = "Uninsurance") + 
      theme(panel.background=element_blank())
  })
  
  output$map2 <- renderPlotly({
    plot_usmap(data=map_data, values = "expansion", regions = "states") + 
      scale_fill_discrete(name="Medicaid Expansion") +
      theme(legend.position = "left") +
      labs(title = "Medicaid Expansion") + 
      theme(panel.background=element_blank())
  })

}