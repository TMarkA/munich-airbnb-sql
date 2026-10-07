-- Reference tables: Oktoberfest dates and official district names

DROP TABLE IF EXISTS ref.oktoberfest CASCADE;

CREATE TABLE ref.oktoberfest (
    year       int  PRIMARY KEY,
    start_date date NOT NULL,
    end_date   date NOT NULL
);

-- 2020 and 2021 cancelled (COVID)
INSERT INTO ref.oktoberfest (year, start_date, end_date) VALUES
    (2011, '2011-09-17', '2011-10-03'),
    (2012, '2012-09-22', '2012-10-07'),
    (2013, '2013-09-21', '2013-10-06'),
    (2014, '2014-09-20', '2014-10-05'),
    (2015, '2015-09-19', '2015-10-04'),
    (2016, '2016-09-17', '2016-10-03'),
    (2017, '2017-09-16', '2017-10-03'),
    (2018, '2018-09-22', '2018-10-07'),
    (2019, '2019-09-21', '2019-10-06'),
    (2022, '2022-09-17', '2022-10-03'),
    (2023, '2023-09-16', '2023-10-03'),
    (2024, '2024-09-21', '2024-10-06'),
    (2025, '2025-09-20', '2025-10-05'),
    (2026, '2026-09-19', '2026-10-04');

COMMENT ON TABLE ref.oktoberfest IS 'Published Oktoberfest dates (2020 and 2021 cancelled)';

-- filled from ref/districts.csv by etl/transform.py
CREATE TABLE IF NOT EXISTS ref.districts (
    district_no  smallint PRIMARY KEY,
    district     text NOT NULL UNIQUE,
    source_name  text NOT NULL UNIQUE
);

COMMENT ON TABLE ref.districts IS 'Official names and numbers of the 25 city districts';
