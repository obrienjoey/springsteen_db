#####################################################################
### Project: Bruce Database
### Script: 0_source.R
### Script purpose: load the required packages and functions to 
###                 scrape the data
### Date: 18-11-2021
### Author: Joey O'Brien
#####################################################################

### libraries needed

library(dplyr)
library(httr)
library(stringr)
library(rvest)
library(purrr)
library(janitor)
library(readr)
library(here)
library(lubridate)

# database libraries
library(dbplyr)
library(RSQLite)
library(DBI)

### plotting options

### functions used

get_concerts_by_year <- function(year = 2021){
  
  ### function used to collect all the concert details for a given year
  ###
  ### input : year - a certain year to check the concerts from
  ###
  ### output : a tibble with details of the concert
  
  url = paste0('http://brucebase.wikidot.com/', year)
  html = url %>%
          httr::GET(., httr::timeout(10)) %>%
          rvest::read_html()
  
  gig_url = html %>%
    html_elements('strong') %>%
    html_nodes('a') %>%
    html_attr('href')
  
  details = html %>%
    html_elements('strong') %>%
    html_nodes('a') %>%
    html_text()
  
  concerts = tibble(gig_url, details) %>%
    filter(grepl('/gig:', gig_url)) %>%
    mutate(date = str_extract(details, "\\d{4}-\\d{2}-\\d{2}"),
           location = str_remove_all(details, "\\d{4}-\\d{2}-\\d{2} - ")) %>%
    select(-details)
  
  return(concerts)
}


get_setlist <- function(gig_url = '/gig:2021-07-07-st-james-theatre-new-york-city-ny'){
  
  ### function used to get the setlist from any Springsteen concert
  ###
  ### input : gig_url - the url associated with a certain concert
  ###                   e.g., '/gig:2021-07-07-st-james-theatre-new-york-city-ny'  
  ###
  ### output : setlist information from the provided gig 
  
  base_url = 'http://brucebase.wikidot.com'
  html = rvest::read_html(paste0(base_url, gig_url))
  
  # check if there is a set list known for this concert
  
  setlist_check = !"No set details known." %in% 
    (html %>%
       html_elements('p') %>%
       html_text())
  
  # if setlist_check... do your thing
  if(setlist_check){
    
    links = html %>%
      html_elements('ol') %>%
      html_elements('a') %>%
      html_attr('href')
    
    songs = html %>%
      html_elements('ol') %>%
      html_elements('a') %>%
      html_text()
    
    gig = rep(gig_url, length(songs))
    
    return(tibble(gig_url = gig, links, songs))}
    Sys.sleep(0.5) # don't overload the website...
}

get_tour_names <- function(){
  
  ### function used to scrape details of all Springsteen tours
  ###
  ### outputs : tibble with urls and names of all Springsteen tours
  
  base_url = 'http://brucebase.wikidot.com'
  url = paste0(base_url, '/stats:tour-statistics')
  html = rvest::read_html(url)
  
  ## find all tours
  
  tours = html %>%
    html_table() %>%
    purrr::pluck(1) %>%
    slice(2:nrow(.)) %>%
    row_to_names(1) %>%
    clean_names() %>%
    bind_cols(., html %>%
                html_nodes(xpath = "//td/a") %>% 
                html_attr("href") %>%
                as_tibble() %>%
                filter(grepl("shows",value)) %>%
                rename('url' = 'value')) %>%
    rename('years' = 'year_s',
           'tour' = 'shows_on_each_tour',
           'tour_url' = 'url') %>%
    select(-songs_on_each_tour) %>%
    separate_rows(years)
  
}

get_tour_gigs <- function(tour = 'Springsteen on Broadway',
                          tour_url = '/stats:shows-sob-tour'){
  
  ### function used to scrape all concerts associated with a given
  ### Springsteen tour 
  ###
  ### inputs : tour - name of tour (only for aestethics)
  ###          tour_url - brucebase url value associated with a tour
  ###                     e.g., '/stats:shows-sob-tour'
  ###
  ### outputs : tibble with urls of all concerts for a given tour
  
  base_url = 'http://brucebase.wikidot.com'
  html = rvest::read_html(paste0(base_url, tour_url))
  
  links = html %>%
    html_elements('div.yui-content')  %>%
    html_nodes('a') %>%
    html_attr('href')
  
  concerts = tibble(gig_url = links, tour = rep(tour, length(links)))
  return(concerts)
}

get_songs <- function(){
  
  ### function used to scrape details of all songs performed by Springsteen
  ###
  ### outputs : tibble with urls and names of all songs performed by Springsteen
  
  url = paste0(base_url, '/stats:songs')
  html = rvest::read_html(url)
  
  titles = html %>%
    html_elements('div.list-pages-box') %>%
    html_elements('li') %>%
    html_elements('a') %>%
    html_text()
  
  links = html %>%
    html_elements('div.list-pages-box') %>%
    html_elements('li') %>%
    html_elements('a') %>%
    html_attr('href')
  
  tibble(links, titles)
  
}

get_lyrics_and_album = function(song_url = '/song:born-to-run'){
  
  ### function to scrape the lyrics and album details of every song
  ### performed by Springsteen over the years
  ###
  ### input : song_url - brucebase url associated with any song played by
  ###                    Springsteen e.g., '/song:born-to-run"
  ### 
  ### output : get song lyrics and details of album it appeared on
  ###          returned as a list.
  ###
  
  html = rvest::read_html(paste0(base_url, song_url))
  
  table_titles = html %>% 
    html_elements('ul.yui-nav') %>% 
    html_text() %>% 
    str_split('\n') %>% 
    purrr::pluck(1)
  
  lyrics = html %>%
    html_elements(paste0("[id$='wiki-tab-0-", 
                         which(table_titles == 'Lyrics')-1, "']")) %>%
    html_elements('p') %>%
    html_text() %>%
    paste(collapse = ' ') %>%
    str_replace_all('\n', ' ')
  
  if(lyrics == " "){# strange case of a video at the top
    lyrics = html %>%
      html_elements("[id$='wiki-tab-0-6']") %>%
      html_elements('p') %>%
      html_text() %>%
      paste(collapse = ' ') %>%
      str_replace_all('\n', ' ')    
  }
  
  album = html %>%
    html_elements("[id$='wiki-tab-0-0']") %>%
    html_elements('em') %>%
    html_text()
  
  if(grepl('Performed|lineup', album[1])){
    album = ''
  }
  return(c(lyrics = lyrics[[1]], album = album[1]))
}

csv_update_check <- function(df, file_location){
  
  ### checks if a df is the same as the one found in the csv
  ### at file location, and if not it replaces the csv with df
  
  csv_df <- readr::read_csv(file_location,
                            col_types = readr::cols(.default = "c"))
  if(!all_equal(df, csv_df)){
    readr::write_csv(df, file_location)
  }
}
