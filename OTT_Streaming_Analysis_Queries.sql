-- OTT Streaming Content Trend Analysis
-- SQL dialect: SQLite
-- Import netflix_titles.csv into a table named netflix_titles.
-- Each row represents one title. These queries use only columns in the supplied dataset.

-- 1. Overall catalogue size
SELECT COUNT(*) AS total_titles
FROM netflix_titles;

-- 2. Movies vs TV Shows
SELECT type, COUNT(*) AS title_count
FROM netflix_titles
GROUP BY type
ORDER BY title_count DESC;

-- 3. Titles by release year and type
SELECT release_year, type, COUNT(*) AS title_count
FROM netflix_titles
GROUP BY release_year, type
ORDER BY release_year, type;

-- 4. Titles by content rating
SELECT COALESCE(rating, 'Not specified') AS content_rating,
       COUNT(*) AS title_count
FROM netflix_titles
GROUP BY COALESCE(rating, 'Not specified')
ORDER BY title_count DESC;

-- 5. Titles added by year (SQLite date parsing)
SELECT CAST(substr(date_added, -4) AS INTEGER) AS year_added,
       COUNT(*) AS titles_added
FROM netflix_titles
WHERE date_added IS NOT NULL
  AND date_added <> ''
  AND length(date_added) >= 4
GROUP BY substr(date_added, -4)
ORDER BY year_added;

-- 6. Average and median-like duration summary for movies.
-- SQLite supports AVG. Median requires an ordered window/query. This returns average.
SELECT AVG(CAST(REPLACE(duration, ' min', '') AS REAL)) AS average_movie_minutes
FROM netflix_titles
WHERE type = 'Movie'
  AND duration LIKE '%min';

-- 7. TV Shows by number of seasons
SELECT CAST(REPLACE(REPLACE(duration, ' Seasons', ''), ' Season', '') AS INTEGER) AS seasons,
       COUNT(*) AS show_count
FROM netflix_titles
WHERE type = 'TV Show'
  AND duration IS NOT NULL
GROUP BY seasons
ORDER BY seasons;

-- 8. Genre counts (SQLite recursive split of comma-separated listed_in values)
WITH RECURSIVE genre_split(show_id, remaining, genre) AS (
    SELECT show_id,
           listed_in || ',',
           ''
    FROM netflix_titles
    WHERE listed_in IS NOT NULL
    UNION ALL
    SELECT show_id,
           substr(remaining, instr(remaining, ',') + 1),
           trim(substr(remaining, 1, instr(remaining, ',') - 1))
    FROM genre_split
    WHERE remaining <> ''
)
SELECT genre, COUNT(DISTINCT show_id) AS title_count
FROM genre_split
WHERE genre <> ''
GROUP BY genre
ORDER BY title_count DESC
LIMIT 10;

-- 9. Country counts (titles can have multiple production countries)
WITH RECURSIVE country_split(show_id, remaining, country) AS (
    SELECT show_id,
           country || ',',
           ''
    FROM netflix_titles
    WHERE country IS NOT NULL
    UNION ALL
    SELECT show_id,
           substr(remaining, instr(remaining, ',') + 1),
           trim(substr(remaining, 1, instr(remaining, ',') - 1))
    FROM country_split
    WHERE remaining <> ''
)
SELECT country, COUNT(DISTINCT show_id) AS title_count
FROM country_split
WHERE country <> ''
GROUP BY country
ORDER BY title_count DESC
LIMIT 10;
