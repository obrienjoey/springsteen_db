#####################################################################
### Project: Bruce Database
### Script: 3_update_csv
### Script purpose: take the sql database and write each table
###                 to a corresponding csv file to allow for more
###                 users to access
### Date: 16-02-2022
### Author: Joey O'Brien
#####################################################################

source('code/0_source.R')

update_csvs <- function(db_loc = here::here('database/springsteen_data.sqlite')){
  
  springsteen_db <- DBI::dbConnect(RSQLite::SQLite(), db_loc)
  
  concert_df <- springsteen_db %>%
                  tbl(., 'concerts') %>%
                  collect()
  
  song_df <- springsteen_db %>%
               tbl('songs') %>%
               collect() %>%
               mutate_if(is.character, list(~na_if(.,""))) 
  
  setlist_df <- springsteen_db %>%
                  tbl('setlists') %>%
                  collect() %>%
                  group_by(gig_url) %>%
                  mutate(song_number = row_number())
  
  tour_df <- springsteen_db %>%
               tbl('concert_tours') %>%
               collect()
  
  ### check each of the local csv files to see if they need
  ### to be updated
  
  csv_update_check(concert_df, here('csv/concerts.csv'))
  print('concert csv checked')
  csv_update_check(song_df, here('csv/songs.csv'))
  print('song csv checked')
  csv_update_check(setlist_df, here('csv/setlists.csv'))
  print('setlist csv checked')
  csv_update_check(tour_df, here('csv/tours.csv'))
  print('tour csv checked')
  
  ### disconnect from the database
  DBI::dbDisconnect(springsteen_db)
  
}

update_csvs()
