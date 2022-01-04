#####################################################################
### Project: Bruce Database
### Script: 2_update_databases
### Script purpose: update each of the databases by checking if there
###                 has been any concerts in the past year that haven't
###                 been included in the database
### Date: 18-11-2021
### Author: Joey O'Brien
#####################################################################

source('code/0_source.R')

update_dbs <- function(check_date = today(),
                       db_loc = here('database/springsteen_data.sqlite')){
  
  springsteen_db <- DBI::dbConnect(RSQLite::SQLite(), db_loc)
  check_date = as.Date(check_date)
  
  concerts_in_year = get_concerts_by_year(year(check_date))
  
  ### update the setlist table
  
  ### first check all concerts have occurred this years
  ### in case more than one has been added and compare with
  ### the current database
  
  if(nrow(concerts_in_year) != 0){
    gigs_to_check = concerts_in_year %>%
      mutate(date = ymd(date)) %>%
      anti_join(., springsteen_db %>%
                  tbl(., 'setlists') %>%
                  collect) %>%
      filter(date < check_date) %>%
      pull(gig_url)
  }else{
    gigs_to_check = c()
    cat('No concerts recorded this year so far :( \n')
  }
  
  ### check if there are any new concerts to collect and if so
  ### scrape the setlist
  
  if(length(gigs_to_check) != 0){
    new_setlists = map_df(gigs_to_check, get_setlist)
    
    DBI::dbWriteTable(conn = springsteen_db, 
                      name = "setlists",
                      value = new_setlists,
                      append = TRUE)
    
    ### update the concert link table
  
    ### first check which concerts are not currently in the table
  
    new_concerts = concerts_in_year %>%
      anti_join(., springsteen_db %>%
                  tbl(., 'concerts') %>%
                  collect(), by = 'gig_url')
    
  }else{
    new_concerts = c()
    cat('Nothing new to add today :( \n')
  }
  
  ### check if there are any new concerts to collect and if so
  ### scrape the concert details
  
  if(length(new_concerts) != 0){
    DBI::dbWriteTable(conn = springsteen_db, 
                      name = "concerts",
                      value = new_concerts,
                      append = TRUE)
  }

  ### and lastly the tour statistics table

  ### find the current tour  
  tours = get_tour_names()

  current_tour = tours %>%
    filter(years == year(check_date))
  
  if(length(current_tour) != 0){
    ### obtain all concert from this tours and check if we already have them all
    tour_concerts_year = map2_df(current_tour$tour, current_tour$tour_url,
                                 get_tour_gigs)

    new_concerts_year = tour_concerts_year %>%
      anti_join(., springsteen_db %>%
                  tbl(., 'concert_tours') %>%
                  collect(), by = 'gig_url')

    ### if any are missing, add them to the table

    if(length(new_concerts_year) != 0){
      DBI::dbWriteTable(conn = springsteen_db, 
                        name = "concert_tours",
                        value = new_concerts_year,
                        append = TRUE)
    }
  }
  
  ### disconnect from the database
  DBI::dbDisconnect(springsteen_db)
  
}

update_dbs()
