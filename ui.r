library(shiny)
shinyUI(navbarPage(
  title = 'The Tour Planner',
  
  tabPanel('Documentation',
           tags$h1("Documentation for the ultimate tour"),
           tags$p("This shiny app uses the crowd to arrange a city tour. It does this by querying online services and using the TSP package to predict the optimal route and plotting the route on Google maps using the GGMAP package"),
           tags$p("The R code queries the following sources:"),
           tags$ol(
             tags$li("Yelp.com API - to find venues that are highly rated by the crowd."), 
             tags$li("Google Maps Distance API - to find a distance matrix."), 
             tags$li("Google Maps Route API - to plot the plot."), 
             tags$li("Various packages are used to acquire, transform and model.")
           ),
           tags$p("The main model is built using the TSP (Travelling Sales Person) package. The prediction is made by cycling through the algorithms and selecting the one returning the minimum distance"),  
           tags$p("To process the model select the parameters on the Input tab and press the process button"),      
           tags$p("Click on the Venue tab to see the list of venues returned by the Yelp query.  It may take a few seconds for the results to appear."),      
           tags$p("Click on the Route tab to see the prediction of the optimal route returned from the TSP package."),      
           tags$p("Click on the Map tab to see the route plotted on Google Maps.It may take a few seconds for the map to appear to please be patient.")      
           
  ),
 
  
  
  
  
  tabPanel('API Keys',
           tags$p("At the moment this app queries Yelp and Google.  Yelp require a developer account in order to retrieve a set of keys"),
           tags$p("Google allows API access with no account up to a certain limit."), 
           tags$a(href="https://www.yelp.com/developers", "Click here to sign up for a Yelp developer account"),
           tags$h3("Enter the Yelp API keys here"),
           passwordInput("consumerkey", "Consumer Key", value="0gk3gsBBNFcM__JrM0BpSg"),
           passwordInput("consumersecret", "Consumer Secret",value="xnwFrSco30G_UcO0ypf4-yfZOfY"),
           passwordInput("token", "Token",value="apQ-f2E6pnELIjk6uRlKthOzPv2TNQXo"),
           passwordInput("tokensecret", "Token Secret",value="vpk-qphYA_vMvO823-npAdmk4yQ")
           
           
           
  ),
  
  
  
  
  tabPanel('Selection',textInput("city", "Enter a city", value="Chester"),
           textInput("country", "Enter a country", value="UK"),
           selectInput("type", "Select the venue type you wish to visit", choices=(c("bars", "resturants", "museums", "parks")), selected="bars"), 
           sliderInput("radius", "Select the radius (distance(metres) you want to walk)", value=3000,min=1000, max=10000, step=1000, format="#####"),                
           h4("When ready press the process button to create the tour"),
           submitButton("Process",icon("refresh"))
           
  ),
  tabPanel('Venues', dataTableOutput('venues')),
  tabPanel('Route', tableOutput('route')),
  tabPanel('Map', plotOutput('map'))
  
))