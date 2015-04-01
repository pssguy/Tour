

yelp.url <- function(category, city,radius,cons_key, cons_sec, tok, tok_sec) {
  
  #Add escape codes to the search parameter
  category1 <- gsub(pattern = " ", replacement = "%2520", x = category)
  category2 <- gsub(pattern = " ", replacement = "+", x = category)
  city1 <- gsub(pattern = " ", replacement = "%2520", x = city)
  city2 <- gsub(pattern = " ", replacement = "+", x = city)
  
  
  #Create random string for use in encoding
  nonce <- paste(sample(x = c(0:9, letters, LETTERS, "_"), size = 32, 
                        replace = TRUE), collapse= "")
  
  #Time stamp
  tm <- format(x = Sys.time()+8000000000, "%s")
  
  #Prepare URL for authenticating     
  #Tried CurlEscape() but needed finer control over escape strings
  api.url <- paste("GET\u0026http%3A%2F%2Fapi.yelp.com%2Fv2%2Fsearch\u0026",
                   "category_filter%3D", category1,"%26",
                   "limit%3D10%26location%3D",city1,"%26",
                   "oauth_consumer_key%3D", cons_key, "%26",
                   "oauth_nonce%3D", nonce, "%26",
                   "oauth_signature_method%3DHMAC-SHA1%26",
                   "oauth_timestamp%3D", tm, "%26",
                   "oauth_token%3D", tok, "%26",
                   "radius_filter%3D",radius,"%26",
                   "sort%3D2",
                   sep = "")
  
  #Encode signature
  signature <- as.character(curlPercentEncode(base64(
    hmac(key=paste(cons_sec, tok_sec, sep="&"), 
         object=api.url, algo="sha1", serialize=FALSE, raw=TRUE))))
  
  
  #Build the URL to be used in the request
  api.url <- paste("http://api.yelp.com/v2/search?",
                   "category_filter=", category2,"&",
                   "limit=10&location=",city2,"&",
                   "oauth_consumer_key=", cons_key, "&",
                   "oauth_nonce=", nonce, "&",
                   "oauth_signature=", signature, "&",
                   "oauth_signature_method=HMAC-SHA1&",
                   "oauth_timestamp=", tm, "&",
                   "oauth_token=", tok, "&",
                   "radius_filter=",radius,"&",
                   "sort=2",
                   sep = "")
  
  return(api.url)
}

yelp.data <- function(category="bars", city="Chester", radius=3500, consumerkey, consumersecret, token, tokensecret) {
  
  #Create the signed URL 
  y.url <- yelp.url(category = category,city=city,
                    radius=radius,
                    cons_key = consumerkey,
                    cons_sec = consumersecret,
                    tok = token,
                    tok_sec = tokensecret)
  
  #Post URL to Yelp and process the JSON returned
  
  x <- getURL(y.url) %>% fromJSON()
  
  #Extract lat/long pairs and concatenate
  businesses <- unlist(x$businesses)
  business.names <- unname(businesses[grep('^name$',names(businesses))])
  latlong <- businesses[grep('^location.coordinate.',names(businesses))]
  latlong.matrix <- apply(matrix(latlong, ncol = 2, byrow = TRUE), 1, 
                          paste, collapse = ",")
  latlong.matrix2 <- matrix(latlong, ncol = 2, byrow = TRUE)
  o.latlong <- paste(latlong.matrix,sep="|",collapse="|")
  df <- data.frame(business.names,latlong.matrix2)
  #colnames(df) <- c("Venue Name", "Lat", "Long")
  output <- list(LatLong = o.latlong, "Names" = business.names, df=df)
  
  return(output)
}

construct.distance.url <- function(origins, return.call = "json", 
                                   sensor = "false") {
  root <- "https://maps.googleapis.com/maps/api/distancematrix/"
  u <- paste(root, return.call, "?origins=", origins, "&destinations=",
             origins,"&mode=walking", sep = "")
  return(URLencode(u))
}

distance.matrix <- function(address,y,verbose=FALSE) {

  if(verbose) cat(address,"\n")
  
  
  u <- construct.distance.url(address) %>% 
    getURL(ssl.verifypeer = FALSE) %>% fromJSON()
  
  
  
  if(u$status=="OK") {
    #Turn JSON into 2 dim matrix, measure=Distance Value in Metres
    x2 <- unlist(u$rows)
    output<-matrix(as.numeric(unname(x2[grep('distance.value',names(x2))])),
                   ncol=as.numeric(nrow(y$df))) %>% forceSymmetric()  
    return(output)
  } else {
    return("There was a problem with the web query")
  }
}

tsp.route <- function(places,names){

  items <- as.numeric(NROW(names))
  city.matrix <- matrix(places,nrow=items, ncol=items, dimnames=list(names,names))
  tsp <- TSP(city.matrix)
  
  methods <- c("nearest_insertion", "farthest_insertion", 
               "cheapest_insertion","arbitrary_insertion","nn", 
               "repetitive_nn", "2-opt")
  
  
  tours <- sapply(methods, FUN = function(m) 
    solve_TSP(tsp,method = m),simplify=FALSE)
  best <- tours[which.min(c(sapply(tours, FUN = attr, "tour_length")))]
  best.route <- names(best[[1]])
  best.distance <- tour_length(tsp,best[[1]])
  
  output <- list(route = best.route, distance.travelled = best.distance)
  
  return(output)            
}

create.map<-function(lst, city, radius){
 
  
  #Create DF and prevent factors from being created.
  way.points <- data.frame(lapply(lst[,1:3], as.character), 
                           stringsAsFactors=FALSE)
  
  #Combine the row number with the business names to 
  #related points to legend labels
  way.points <- mutate(way.points, business.names = 
                         paste(seq_along(X1),business.names, sep = " "))
  
  #Call Route() in 1 pass 
  rte.from <- apply(way.points[-nrow(way.points),2:3],1,paste,collapse=",")
  rte.to <- apply(way.points[-1,2:3],1,paste,collapse=",")
  rte <- do.call(rbind,
                 mapply(route, rte.from, rte.to, SIMPLIFY=FALSE,
                        MoreArgs=list(mode="walking",
                                      output="simple",structure="leg")))
  
  
  #Work out the rough centre point of the map
  map.centre <- c(mean(as.numeric(way.points$X2)),mean(as.numeric(way.points$X1)))
  
  #Load the coordinates from Route() to be used to plot the paths
  coords <- rbind(as.matrix(rte[,7:8]),as.matrix(rte[nrow(rte),9:10])) %>% 
    as.data.frame() 
  
  
  
  #Create the Map - first 2 layers are the path and point.  
  #The second geom_point is a dummy one used to define the legend. 
  
  ggm <- qmap(location=map.centre,zoom = 15,maptype = "road",legend="bottomleft")  
  ggm + 
    geom_path(data=coords,aes(x=startLon,y=startLat),color="blue",size=2)+
    geom_point(data=way.points,aes(x=as.numeric(X2),y=as.numeric(X1)),
               size=10,color="yellow")+
    geom_point(data=way.points,
               aes(x=as.numeric(X2),y=as.numeric(X1),color = 
                     factor(business.names, levels=unique(business.names))), 
               alpha = 0) +
    geom_text(data=way.points,
              aes(x=as.numeric(X2),y=as.numeric(X1), label=seq_along(X1)))+
    scale_color_discrete(name = "Venues") +
    labs(title=paste("The optimal route for the top rated Venues to visit in ",city,
                     " within a ",as.numeric(radius)/1000,"km radius",sep=""))+
    theme(legend.key = element_rect(fill = NA),legend.position = c(-0.40, 0.41),
          plot.title = element_text(hjust = 0, vjust = 1, face = c("bold")))
  
}


shinyServer(function(input, output) {


  
  
  dataset <- reactive({
    #Check for empty fields
    validate(
      need(input$type, 'Select a category'),
      need(input$city != '', 'Please enter a city.'),
      need(input$country != '', 'Please enter a country.')
    )
    
    validate(
      need(input$consumerkey !='', 'Enter a consumer key on the API Keys tab'),
      need(input$consumersecret != '', 'Enter a consumer secret on the API Keys tab'),
      need(input$token != '', 'Enter a token on the API Keys tab.'),
      need(input$tokensecret != '', 'Enter a token secret on the API Keys tab.')
    )
    
    
    #Call the Yelp function to retreive top venues based in inputs
    yelpdat<<-yelp.data(category=input$type, 
                        city=paste(input$city, " ", input$country),
                        radius=input$radius, consumerkey=input$consumerkey, 
                        consumersecret=input$consumersecret, 
                        token=input$token, tokensecret=input$tokensecret)
    yelpdat
  })
  
  route <- reactive({
    #Find the distances between venues
    x <- distance.matrix(dataset()$LatLong,yelpdat)
    
    w.route<-tsp.route(x,dataset()$Names)
    #Sort the Yelp venues by the predicted route
    sorted.route<-dataset()$df[match(w.route$route, dataset()$df$business.names),]
    sorted.route 
    
  })
  
  output$venues <- renderDataTable({
    dataset()$df},options=list(paging= FALSE))
  
  output$route <- renderTable({
    route()
  })
  
  output$map <- renderPlot({
    
    create.map(route(),input$city, input$radius)
  }, height=500, width="auto")
  
  
})