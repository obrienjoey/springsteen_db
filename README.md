# springsteen_db

The springsteen_db repository contains a collection of `R` scripts which are used to collect a large collection of data describing the career of Bruce Springsteen from the fan website [Brucebase](http://brucebase.wikidot.com/). 

## Datasets

The scripts collect four separate datasets

-- songs - describes information about songs played by or associated with Springsteen, including, in some cases, the album and lyrics.

-- concerts - describes all concerts that he has played since 1973, including the name of the venue, location, and date.

-- setlists - describes the songs which make up the setlists performed at each show.

-- tours - describes which tour was associated with each show.

## Data storage

The data is stored two ways: 

1. The four tables are stored in a sqllite database found in `database\springsteen_data.sqlite`.

2. Each table is also stored in a csv file in `csv\`.

## Automation

Each night the website is also automatically checked to see if any new shows have been added for the current calendar year. If so, the database and corresponding spreadsheets are also updated.

## spRingsteen

Note that this data makes up that found in the [spRingsteen](https://github.com/obrienjoey/spRingsteen) R package which presents the data in a tidy format for easy analysis.
