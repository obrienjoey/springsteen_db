#####################################################################
### Project: Bruce Database
### Script: 1_initial_data_collection
### Script purpose: initial scrape of all the Springsteen data you 
###                 could ever need, to be run only once to initiate
###                 the database
### Date: 18-11-2021
### Author: Joey O'Brien
#####################################################################

source('code/0_source.R')

### what years will we collect
first_year = 1973 # first year interested in
years = first_year:year(today()) # years to look at

### collect the concerts from these years
concert_df = map_df(years, get_concerts_by_year)

### and the corresponding setlists
setlist_df = map_df(concert_df$gig_url, get_setlist)

### find all tours
tour_df = get_tour_names()
### and their associated concerts
gig_link_df = map2_df(unique(tours$tour), unique(tours$tour_url), get_tour_gigs)

### find all songs performed by Bruce Springsteen
song_df = get_songs()
### and add the lyrics and album details of each of these songs
song_df = song_df %>%
  mutate(details = map(.x = links, .f = lyrics_and_album)) %>%
  unnest_wider(details)

### lastly lets save all these details to our SQL database
### now to load it into a sql database

springsteen_db <- DBI::dbConnect(RSQLite::SQLite(), 
                                 here("database/springsteen_data.sqlite"))

### write the in-memory data into the database as a table

DBI::dbWriteTable(springsteen_db, 
                  "concerts",
                  concert_df)

DBI::dbWriteTable(springsteen_db, 
                  "setlists",
                  setlist_df)

DBI::dbWriteTable(springsteen_db, 
                  "concert_tours",
                  gig_link_df)

DBI::dbWriteTable(springsteen_db, 
                  "songs",
                  song_df)

### and also close the database connection

DBI::dbDisconnect(springsteen_db)