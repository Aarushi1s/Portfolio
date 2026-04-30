Use HealthcareDB;

/* Extracting the dim_provider table from the fact Inpatient table.*/

SELECT 
	DISTINCT ProviderID
INTO dim_provider
FROM dbo.fact_inpatient_claim;
 
 /*Validating.*/
SELECT COUNT(*) FROM dim_provider;
SELECT COUNT(DISTINCT ProviderID) FROM dim_provider;

ALTER TABLE dim_provider
ADD Provider_key INT IDENTITY(1,1); /*Adding Surrogate Key*/

SELECT COUNT(*)
FROM dbo.fact_inpatient_claim f
LEFT JOIN dim_provider d
	ON f.ProviderID = d.ProviderID
WHERE d.ProviderID IS NULL; /*Checking if compared to dim_provider there are any other NULL ProviderIDs in the fact table before adjusting the surrogate key into the fact table as a JOIN. Because if (INNER) JOINED with NULL values, important data (with NULLS) rows might get removed. */

/*Fixing dim_provider as it has certain NULLs which caused issues while building stg_outpatient_filtered table. */

SELECT DISTINCT o.PRVDR_NUM
FROM stg_outpatient_filtered o
LEFT JOIN dim_provider p
	ON o.PRVDR_NUM = p.ProviderID
WHERE p.ProviderID IS NULL; /*Identifying missing provider IDs (unique) = 4123.*/

INSERT INTO dim_provider(ProviderID)
SELECT DISTINCT o.PRVDR_NUM
FROM stg_outpatient_filtered o
LEFT JOIN dim_provider p
	ON o.PRVDR_NUM = p.ProviderID
WHERE p.ProviderID IS NULL; /* Inserted the missing provider IDs into the dim_provider.*/