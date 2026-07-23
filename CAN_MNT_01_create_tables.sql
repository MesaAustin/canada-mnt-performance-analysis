USE CanadianFooty_MNT
;

--- Creating staging tables 
-- Fifa match results

CREATE TABLE raw_results (
    match_date      DATE,
    home_team       NVARCHAR(100),
    away_team       NVARCHAR(100),
    home_score      INT,
    away_score      INT,
    tournament      NVARCHAR(150),
    city            NVARCHAR(100),
    country         NVARCHAR(100),
    neutral         NVARCHAR(150)
);

--FIFA rankings
CREATE TABLE raw_rankings_1992_Pres (
	rank_numbering  INT,
    rank_pos        INT,
    country_full    NVARCHAR(100),
    country_abrv    NVARCHAR(10),
    total_points    DECIMAL(10,2),
    previous_points DECIMAL(10,2),
    rank_change     INT,
    confederation   NVARCHAR(50),
    rank_date       DATE
);






