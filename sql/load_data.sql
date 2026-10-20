CREATE TABLE raw_layoffs AS
SELECT * FROM read_csv_auto('data/layoffs.csv');
