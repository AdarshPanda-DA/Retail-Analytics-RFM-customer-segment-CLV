SELECT * FROM consumer360.dates;

describe consumer360.dates;

-- typecast
alter table consumer360.dates
modify column date date;

-- typecast
alter table consumer360.dates
modify column month_name varchar(50);

-- typecast
alter table consumer360.dates
modify column quarter varchar(50) ;