
create table station_list(
 code int unsigned not null primary key,
 id varchar(16) unique,
 name varchar(64) not null,
 name_kana varchar(64) not null,
 lon double not null,
 lat double not null,
 prefecture tinyint unsigned not null,
 attr varchar(16),
 postal_code varchar(16),
 address varchar(128),
 closed tinyint unsigned not null
 );

load data local infile "/Users/skaor/Documents/station_database/out/csv/station.csv" into table station_list fields terminated by ',' ignore 1 lines;

create table line_list(
 code int unsigned not null primary key,
 id varchar(16) unique,
 name varchar(64) not null,
 name_kana varchar(64) not null,
 station_size int unsigned not null,
 company_code int unsigned not null,
 color varchar(16),
 symbol varchar(16),
 closed tinyint unsigned not null
 );
 
load data local infile "/Users/skaor/Documents/station_database/out/csv/line.csv" into table line_list fields terminated by ',' ignore 1 lines;

create table station_line(
    station_code int unsigned not null,
    line_code int unsigned not null,
    list_index int unsigned not null,
    numbering varchar(64)
);

load data local infile "/Users/skaor/Documents/station_database/out/csv/station-line.csv" into table station_line fields terminated by ',' ignore 1 lines;
