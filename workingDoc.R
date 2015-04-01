### changes

#hard- coded textInput values (would be nice to show up as ****)
#so changed to passwordInput

# seem to only need selection and then click on maps - no ned for intermedate venue and route
## does the route actually give roads though

## need to look at map to be able to zoom in and out - poss not ggmap

## initial uses a distance (should also be abe to get a time)

construct.distance.url <- function(origins, return.call = "json", 
sensor = "false") {
  root <- "https://maps.googleapis.com/maps/api/distancematrix/"
  u <- paste(root, return.call, "?origins=", origins, "&destinations=",
             origins,"&mode=walking", sep = "")
  return(URLencode(u))
}

The Google Distance Matrix API is a service that provides travel distance and time for a matrix
of origins and destinations.
The information returned is based on the recommended route between start and end points, 
as calculated by the Google Maps API,
and consists of rows containing duration and distance values for each pair.

This service does not return detailed route information. 
Route information can be obtained by passing the desired single origin 
and destination to the Directions API. i.e may be more diff with several locations