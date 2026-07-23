USE CanadianFooty_MNT
;

---Bulk inserting FIFA match results table 

BULK INSERT raw_results
FROM 'C:\Users\igbuk\OneDrive\Documents\SQL Server Management Studio\Beginner Projects\Canadian Mens NT Football Proj\results.csv'
WITH (
    FIRSTROW = 2,        
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
	MAXERRORS = 100
);

---Bulk inserting FIFA Rankings table 


BULK INSERT raw_rankings_1992_Pres
FROM 'C:\Users\igbuk\OneDrive\Documents\SQL Server Management Studio\Beginner Projects\Canadian Mens NT Football Proj\fifa_ranking 1992-2024( update2026-04-01.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
	MAXERRORS = 1500
);

---Also Used IMPORT FLAT FILE OPTION(Pure_Ranking), to compare as against raw_ranking as 69848 rows inserted but original CSV file had 70194. 
---IMPORT FLAT FILE retrieved every row, and matches original CSV. Will proceed using Pure_ranking