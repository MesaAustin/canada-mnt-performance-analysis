USE CanadianFooty_MNT
;

---Creating Views for different perspective anlysis

-- View for year on year comparisons 

GO
CREATE VIEW yearly_summary AS							
SELECT
    YEAR(match_date) AS match_year,
    COUNT(*) AS matches_played,
    SUM(CASE WHEN results = 'Win' THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN results = 'Draw' THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN results = 'Loss' THEN 1 ELSE 0 END) AS losses,
    ROUND(100.0 * SUM(CASE WHEN results = 'Win' THEN 1 ELSE 0 END) / COUNT(*), 1) AS win_pct,
    SUM(canada_score) AS goals_for,
    SUM(opponent_score) AS goals_against,
    SUM(canada_score) - SUM(opponent_score) AS goal_diff
FROM canada_matches
GROUP BY YEAR(match_date);
GO

SELECT * 
FROM yearly_summary ;

SELECT * 				-- the yearly_summary view is already in order from 1
FROM yearly_summary 
ORDER BY match_year;

SELECT	match_year,		--just looking for win pct and goal dif
		win_pct, 
		goal_diff 
FROM yearly_summary 
ORDER BY match_year;


-- View for Can Men's team performance in diferent competition analysis

GO
CREATE VIEW competition_comparison AS
SELECT
    competition,
    COUNT(*) AS matches_played,
    ROUND(100.0 * SUM(CASE WHEN results = 'Win' THEN 1 ELSE 0 END) / COUNT(*), 1) AS win_pct,
    ROUND(AVG(CAST(canada_score AS FLOAT)), 2) AS avg_goals_for,
    ROUND(AVG(CAST(opponent_score AS FLOAT)), 2) AS avg_goals_against
FROM canada_matches
GROUP BY competition;
GO

SELECT *						--looks good
FROM competition_comparison;

SELECT * 
FROM competition_comparison 
ORDER BY matches_played DESC;

--yearly ranking view

GO
CREATE VIEW yearly_ranking AS
WITH RankedYears AS
(	SELECT
        YEAR(rank_date) AS ranking_year,
        rank_date,
        rank_pos,

        ROW_NUMBER() OVER
        (PARTITION BY YEAR(rank_date)
            ORDER BY rank_date ) AS start_row,

        ROW_NUMBER() OVER
        (PARTITION BY YEAR(rank_date)
            ORDER BY rank_date DESC ) AS end_row

    FROM canada_rankings	)
SELECT
    ranking_year,

    MAX(CASE WHEN start_row = 1 THEN rank_pos END) AS year_start_rank,

    MAX(CASE WHEN end_row = 1 THEN rank_pos END) AS year_end_rank,

    MAX(CASE WHEN start_row = 1 THEN rank_pos END)
      - MAX(CASE WHEN end_row = 1 THEN rank_pos END) AS rank_change,

    ROUND(AVG(CAST(rank_pos AS FLOAT)),1) AS avg_rank,

    MIN(rank_pos) AS best_rank,

    MAX(rank_pos) AS worst_rank

FROM RankedYears
GROUP BY ranking_year;

GO

--Verifying view is as requirements needed

SELECT * FROM yearly_ranking;	

SELECT * FROM yearly_ranking 
ORDER BY ranking_year;

-- Creating view for Canadas oponents rankings 

GO
CREATE VIEW results_vs_opponent_strength AS
SELECT
    cm.match_date,
    cm.opponent,
    cm.results,
    r.rank_pos AS opponent_rank_at_match_time
FROM canada_matches AS cm
LEFT JOIN country_name_mapping m
    ON cm.opponent = m.match_country
LEFT JOIN pure_ranking AS r
	ON r.country_full = COALESCE(m.ranking_country, cm.opponent)
    AND r.rank_date = (
        SELECT MAX(r2.rank_date) FROM pure_ranking AS r2
        WHERE r2.country_full = cm.opponent AND r2.rank_date <= cm.match_date
    );
GO

-- After taking a look at the view I think including wether its a friendly or not should be factored. So i will add macth type. 
--also adding home-field advantage indicator column, opponent rank on matchday column, tournament/competition column and home soil vs opp soil column

GO
ALTER VIEW results_vs_opponent_strength AS
SELECT
    cm.match_date,
    cm.opponent,
	cm.match_type,
    cm.results,
    r.rank_pos AS opponent_rank_at_match_time,
	cm.canada_venue,
	cm.venue_type, 
	cm.competition
FROM canada_matches AS cm
LEFT JOIN country_name_mapping AS m
    ON cm.opponent = m.match_country
LEFT JOIN Pure_ranking as r
	ON r.country_full = COALESCE(m.ranking_country, cm.opponent)
    AND r.rank_date = (
        SELECT MAX(r2.rank_date) FROM pure_ranking AS r2
        WHERE r2.country_full = cm.opponent AND r2.rank_date <= cm.match_date
    );
GO

-- added goal diff and ranking tiers for power bi visualizations

GO
ALTER VIEW results_vs_opponent_strength AS
SELECT
    cm.match_date,
    cm.opponent,
	cm.match_type,
    cm.results,
	cm.canada_score - cm.opponent_score AS goal_diff,
    r.rank_pos AS opponent_rank_at_match_time,
	CASE
        WHEN r.rank_pos <= 25 THEN '1-25'
        WHEN r.rank_pos BETWEEN 26 AND 50 THEN '26-50'
        WHEN r.rank_pos BETWEEN 51 AND 100 THEN '51-100'
        WHEN r.rank_pos > 100 THEN '101+'
        ELSE 'Unranked/Unknown'
    END AS opponent_tier,
	cm.canada_venue,
	cm.venue_type, 
	cm.competition
FROM canada_matches AS cm
LEFT JOIN country_name_mapping AS m
    ON cm.opponent = m.match_country
LEFT JOIN pure_ranking AS r
    ON r.country_full = COALESCE(m.ranking_country, cm.opponent)
   AND r.rank_date =
   (    SELECT MAX(r2.rank_date)
        FROM pure_ranking AS r2
        WHERE r2.country_full = COALESCE(m.ranking_country, cm.opponent)
          AND r2.rank_date <= cm.match_date);
GO


SELECT TOP 30 *							--taking a look at the view, there are nulls. I will investigate
FROM results_vs_opponent_strength
ORDER BY match_date;

SELECT distinct *								-- Finding all the nulls, there are 32 in total 
FROM results_vs_opponent_strength
WHERE opponent_rank_at_match_time IS NULL
ORDER BY match_date;

SELECT *					--using some of the null outputs from above, checking values from source table			
FROM Pure_ranking
Where country_full like '%United States%'
ORDER BY rank_date;

SELECT *								
FROM Pure_ranking
Where country_full like '%St Kitts and Nevis%'
ORDER BY rank_date;

-- Why are there nulls, is it just a naming misnomer?
SELECT DISTINCT opponent
FROM canada_matches
ORDER BY opponent;

SELECT DISTINCT country_full
FROM pure_ranking
ORDER BY country_full;

--the issue is naming, will create mapping table to account. 
/*
Data Standardization

Different datasets use different country naming conventions.
To ensure successful joins between match results and FIFA rankings,
the opponent names in canada_matches were added to a mapping table for 
standardized matching to the country names used in the FIFA rankings dataset.

Examples:
- United States ? USA	- Saint Lucia ? St Lucia	- Saint Kitts and Nevis ? St Kitts and Nevis
Guadeloupe and Martinique remain NULL because they are not FIFA-ranked nations.
*/


--use joins to confirm which country names are miss-matched between can_matches and pure_rankings
SELECT DISTINCT cm.opponent				
FROM canada_matches cm
LEFT JOIN pure_ranking pr
    ON cm.opponent = pr.country_full
WHERE pr.country_full IS NULL
ORDER BY cm.opponent;

--finding above querry opponent name list in source pure_ranking table

SELECT DISTINCT country_full			
FROM pure_ranking
WHERE country_full LIKE '%US%';

SELECT DISTINCT country_full
FROM pure_ranking
WHERE country_full LIKE '%US Virgin%';

SELECT DISTINCT country_full
FROM pure_ranking
WHERE country_full LIKE '%Korea%';

SELECT DISTINCT country_full
FROM pure_ranking
WHERE country_full LIKE '%lucia%';

SELECT DISTINCT country_full
FROM pure_ranking
WHERE country_full LIKE '%Kitts%' ;

SELECT DISTINCT country_full
FROM pure_ranking
WHERE country_full LIKE '%ivoire%' ;

SELECT DISTINCT country_full
FROM pure_ranking
WHERE country_full LIKE '%gu%ana%';

SELECT DISTINCT country_full
FROM pure_ranking
WHERE country_full LIKE '%czech%';

SELECT DISTINCT country_full
FROM pure_ranking
WHERE country_full LIKE '%cura%ao%';

--Creating mapping table

CREATE TABLE country_name_mapping (
    match_country NVARCHAR(100) PRIMARY KEY,
    ranking_country NVARCHAR(100) NOT NULL);

-- inserting names into mapping table

INSERT INTO country_name_mapping
(match_country, ranking_country)
VALUES
('United States', 'USA'),
('United States Virgin Islands', 'US Virgin Islands'),
('Saint Lucia', 'St Lucia'),
('Saint Kitts and Nevis', 'St Kitts and Nevis'),
('South Korea', 'Korea Republic'),
('Ivory Coast', 'Côte d''Ivoire'),
('Czech Republic', 'Czechia'), 
('French Guiana', 'Guyana'),    
('Cura?ºao', 'Curaçao');    

--Verifying Mapping table is as needed
select *
from country_name_mapping;

select *									--- checking to seee only non FIFA ranked countries return NULLs in the view. Curacoa is still affected, it shouldnt be.
from results_vs_opponent_strength
where opponent_rank_at_match_time is NULL;

SELECT *							--confirming Curacoa's specific spelling in the tables being joined
FROM country_name_mapping
WHERE match_country LIKE '%Cura%';

SELECT *
FROM pure_ranking
WHERE country_full LIKE '%Cura%';

SELECT *
FROM pure_ranking
WHERE country_full = 'Curaçao'
ORDER BY rank_date;

SELECT *
FROM country_name_mapping
WHERE match_country LIKE '%Cura%';

SELECT DISTINCT country_full
FROM pure_ranking
WHERE country_full LIKE '%Cura%';

SELECT							--closer look at the curacoa null issue in mapping table
    cm.opponent,
    m.match_country,
    m.ranking_country
FROM canada_matches cm
LEFT JOIN country_name_mapping m
ON cm.opponent = m.match_country
WHERE cm.opponent LIKE '%Cura%';

SELECT							--checking for hidden character and leading or trailing spaces
    opponent,
    LEN(opponent),
    DATALENGTH(opponent)
FROM canada_matches
WHERE opponent LIKE '%Cura%';

SELECT
    match_country,
    LEN(match_country),
    DATALENGTH(match_country)
FROM country_name_mapping
WHERE match_country LIKE '%Cura%';

SELECT										--confirming Curacoa was ranked during applicable period
    MIN(rank_date) AS first_rank,
    MAX(rank_date) AS last_rank
FROM pure_ranking
WHERE country_full = 'Curaçao';


SELECT													-- comparing specific spellings in both tables
    cm.opponent,
    m.match_country,
    CASE
        WHEN cm.opponent = m.match_country THEN 'Equal'
        ELSE 'Not Equal'
    END AS comparison
FROM canada_matches cm
CROSS JOIN country_name_mapping m
WHERE cm.opponent LIKE '%Cura%'
  AND m.match_country LIKE '%Cura%';



DELETE FROM country_name_mapping								-- now that spelling(unique characters used in both tables) has been confirmed to  be the issue, 
WHERE ranking_country = 'Curaçao';								--i will delete incorrect spelling and replace it with the correct one

INSERT INTO country_name_mapping (match_country, ranking_country)
SELECT DISTINCT
    opponent,
    'Curaçao'
FROM canada_matches
WHERE opponent LIKE '%Cura%';

SELECT									--verifying the corrections worked. it did.
    cm.opponent,
    m.match_country,
    m.ranking_country
FROM canada_matches cm
LEFT JOIN country_name_mapping m
    ON cm.opponent = m.match_country
WHERE cm.opponent LIKE '%Cura%';

--- Data can now be visualized and patterns can be highlighted.