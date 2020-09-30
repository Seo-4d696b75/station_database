
create table if not exists station_list(
 code int unsigned not null primary key,
 id varchar(16) unique,
 name varchar(64) not null,
 name_kana varchar(64) not null,
 lat double not null,
 lng double not null,
 prefecture tinyint unsigned not null,
 postal_code varchar(16),
 address varchar(128),
 closed tinyint unsigned not null,
 open_date date default null,
 closed_date date default null,
 impl tinyint unsigned not null,
 attr varchar(16),
    fulltext key(name) with parser ngram,
    fulltext key(name_kana) with parser ngram
);

load data local infile "/Users/skaor/Documents/ekimemo/station_database/src/station.csv" into table station_list fields terminated by ',' ignore 1 lines;

create table if not exists line_list(
 code int unsigned not null primary key,
 id varchar(16) unique,
 name varchar(64) not null,
 name_kana varchar(64) not null,
 name_formal varchar(64),
 station_size int unsigned not null,
 company_code int unsigned,
 color varchar(16),
 symbol varchar(16),
 closed tinyint unsigned not null,
 closed_date date default null,
 impl tinyint unsigned not null
);
 
load data local infile "/Users/skaor/Documents/ekimemo/station_database/src/line.csv" into table line_list fields terminated by ',' ignore 1 lines;

create table if not exists register(
    station_code int unsigned not null,
    line_code int unsigned not null,
    list_index int unsigned not null,
    numbering varchar(64)
);

load data local infile "/Users/skaor/Documents/ekimemo/station_database/src/register.csv" into table register fields terminated by ',' ignore 1 lines;
