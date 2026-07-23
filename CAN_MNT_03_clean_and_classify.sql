USE CanadianFooty_MNT
;


--- Removing duplicates from raw resuls

WITH CTE AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY match_date, home_team, away_team, home_score, away_score,
                            tournament, city, country, neutral
               ORDER BY (SELECT NULL)
           ) AS DuplicateCount
    FROM raw_results
)
DELETE
FROM CTE
WHERE DuplicateCount > 1;

---checking for duplicates, none found.

SELECT COUNT(*) FROM raw_results;

--- checking for duplicates in rankings table
WITH CTE AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY rank_numbering, rank_pos, country_full, country_abrv, total_points, 
							previous_points, rank_change, confederation, rank_date
               ORDER BY (SELECT NULL)
           ) AS DuplicateCount
    FROM Pure_ranking
)
DELETE
FROM CTE
WHERE DuplicateCount > 1;

---checking for duplicates, none found and matches csv
SELECT COUNT(*) FROM Pure_ranking;

--- Data filtering for the matches within applicable time period and cleaning.

SELECT
	match_date,
    home_team,
    away_team,
    home_score,
    away_score,
    tournament,
    city,
    country,
    neutral,  
	CASE WHEN home_team = 'Canada' THEN 'Home' ELSE 'Away' END AS canada_venue,
    CASE WHEN home_team = 'Canada' THEN away_team ELSE home_team END AS opponent,
    CASE WHEN home_team = 'Canada' THEN home_score ELSE away_score END AS canada_score,
    CASE WHEN home_team = 'Canada' THEN away_score ELSE home_score END AS opponent_score
INTO Canada_Matches
FROM raw_results
WHERE (home_team = 'Canada' OR away_team = 'Canada')
  AND match_date >= '2010-01-01';

---Checking for Dupes in Canada_matches table

  SELECT match_date,
		 opponent,
		 canada_score, 
		 opponent_score, 
		 COUNT(*)
  FROM canada_matches
  GROUP BY match_date, opponent, canada_score, opponent_score
  HAVING COUNT(*) > 1;

-- No dupes, but my total matches since 2010 total 169, google says matches should be 180-184. Will press on with what I have but note taken.

--adding home ground advantage, i.e canadian soil or not column

ALTER TABLE canada_matches
ADD venue_type NVARCHAR(30);

UPDATE canada_matches
SET venue_type =
    CASE
        WHEN country = 'Canada' THEN 'Home Soil'
        WHEN country = opponent THEN 'Opponent Soil'
        ELSE 'Neutral Site'
    END;

-- Adding competetive vs friendly match category column

ALTER TABLE canada_matches
ADD match_type NVARCHAR(50);

-- Providing row entries for match_type column based on tournament ie friendly or not

UPDATE Canada_Matches
SET match_type = CASE
					WHEN competition = 'Friendly' THEN 'Friendly' ELSE 'Competetive'
				END;

--Checkingtable for new column. since Adding entries

Select top 30*			
FROM Canada_Matches;

--Adding a results column, i.e wins vs losses

ALTER TABLE canada_matches
ADD results NVARCHAR (10);

-- Providing row entries for results column.
UPDATE canada_matches
SET results = CASE
			WHEN canada_score > opponent_score THEN 'Win'
			WHEN canada_score < opponent_score THEN 'Loss'
		ELSE 'Draw'
END;

---Cleaning & filtering data and creating a canada rankings table

SELECT
    rank_date,
    rank_pos,
    total_points,
    rank_change
INTO canada_rankings
FROM pure_ranking
WHERE country_full = 'Canada'
  AND rank_date >= '2010-01-01';

  SELECT *				--- Quick Check on new ranking table  
  FROM canada_rankings
  ORDER BY rank_date;


ALTER TABLE canada_rankings						--limiting total points to 4 decimal places, 8 seems ungainly.
ALTER COLUMN total_points DECIMAL(10,4);

INSERT INTO canada_rankings							-- added FIFA ranking for Jun 11th, World cup start date (Sourced from FIFA website)
(
    rank_date, rank_pos, total_points, rank_change
)
VALUES
(
    '2026-06-11', 30,    1786,    0
);





