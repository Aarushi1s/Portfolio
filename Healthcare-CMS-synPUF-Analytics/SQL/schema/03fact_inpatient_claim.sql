Use HealthcareDB;

/*Creating the staging table.*/

CREATE TABLE stg_inpatient_raw (
	DESYNPUF_ID VARCHAR (50),
	CLM_ID BIGINT,
	CLM_FROM_DT DATE,
	CLM_THRU_DT DATE,
	PRVDR_NUM VARCHAR(20),
	CLM_PMT_AMT FLOAT,
	NCH_PRMRY_PYR_CLM_PD_AMT FLOAT,
	ADMTNG_ICD9_DGNS_CD VARCHAR(10)
	);

INSERT INTO stg_inpatient_raw (
    DESYNPUF_ID,
    CLM_ID,
    CLM_FROM_DT,
    CLM_THRU_DT,
    PRVDR_NUM,
    CLM_PMT_AMT,
    NCH_PRMRY_PYR_CLM_PD_AMT,
    ADMTNG_ICD9_DGNS_CD
)
SELECT 
    DESYNPUF_ID,
    CLM_ID,
    CLM_FROM_DT,
    CLM_THRU_DT,
    PRVDR_NUM,
    CLM_PMT_AMT,
    NCH_PRMRY_PYR_CLM_PD_AMT,
    ADMTNG_ICD9_DGNS_CD
FROM inpatient_s1;

/*Checking the no. of rows in the staging table.*/
SELECT COUNT(*) FROM dbo.stg_inpatient_raw

/* Renaming and cleaning in staging.*/
SELECT 
	CLM_ID as ClaimID,
	DESYNPUF_ID as BeneficiaryID,
	CLM_FROM_DT as AdmissionDate,
	CLM_THRU_DT as DischargeDate,
	PRVDR_NUM as ProviderID,
	CLM_PMT_AMT as Medicare_paid_amount,
	ISNULL (NCH_PRMRY_PYR_CLM_PD_AMT, 0) as Other_paid_amount,
	
	(CLM_PMT_AMT + ISNULL(NCH_PRMRY_PYR_CLM_PD_AMT, 0)) as Total_Claim_Amount,
	ADMTNG_ICD9_DGNS_CD as Diagnosis_Code

INTO stg_inpatient_clean
FROM dbo.stg_inpatient_raw;

 /*Adding Surrogate key now from dim_beneficiary_current table using JOIN and making the staging table "inpatient_enriched".*/

SELECT
	s.*,
	d.beneficiary_key
INTO stg_inpatient_enriched
FROM dbo.stg_inpatient_clean s
JOIN dim_beneficiary_current d
	ON s.BeneficiaryID = d.BeneficiaryID;

/* Validating the data. */

SELECT ClaimID, COUNT(*) AS row_count
FROM dbo.stg_inpatient_enriched
GROUP BY ClaimID
HAVING COUNT(*) > 1; /* 68 ClaimIds duplicated twice. Need to fix this. */

SELECT *
FROM dbo.stg_inpatient_enriched
WHERE ClaimID IN (
	SELECT ClaimID
	FROM dbo.stg_inpatient_enriched
	GROUP BY ClaimID
	HAVING COUNT(*) > 1
)
ORDER BY ClaimID; /* This one gave us VERY IMPORTANT data insight : The data is dirty or fake. Now we'll handle cleaning this particular data.*/

SELECT * 
INTO stg_inpatient_cleanv2
FROM dbo.stg_inpatient_enriched
WHERE AdmissionDate != '1900-01-01'; /*Removing all the fake/dirty data from the table and addign it into another staging named 'stg_inpatient_cleanv2' */

SELECT COUNT (*) FROM stg_inpatient_cleanv2;
SELECT COUNT (DISTINCT ClaimID) FROM stg_inpatient_cleanv2; /*Making sure that the distinct values match the number of total rows to avoid duplication. */

/* Turning it into the fact table by counting Length of Stay from Admission Date to Discharge Date. */

SELECT
	ClaimID,
	beneficiary_key,
	BeneficiaryID,
	AdmissionDate,
	DischargeDate,
	ProviderID,
	Total_Claim_Amount,
	Medicare_paid_amount,
	Other_paid_amount,
	Diagnosis_Code,

	DATEDIFF(DAY, AdmissionDate, DischargeDate) AS LOS /*Length of Stay*/

INTO fact_inpatient_claim
FROM stg_inpatient_cleanv2;

/*Validating the table.*/

SELECT TOP 5 * FROM dbo.fact_inpatient_claim;

SELECT ClaimID, COUNT(*)
FROM dbo.fact_inpatient_claim
GROUP BY ClaimID
HAVING COUNT(*) > 1;

/* Updating the Inpatient FACT Claim table with Provider_key.*/

SELECT
	f.ClaimID,
	f.beneficiary_key,
	f.BeneficiaryID,
	f.AdmissionDate,
	f.DischargeDate,
	d.Provider_key,
	f.Total_Claim_Amount,
	f.Medicare_paid_amount,
	f.Other_paid_amount,
	f.Diagnosis_Code,
	f.LOS
INTO fact_inpatient_claimv2
FROM dbo.fact_inpatient_claim f
JOIN dim_provider d
	ON f.ProviderID = d.ProviderID;

DROP TABLE IF EXISTS dbo.fact_inpatient_claim;
EXEC sp_rename 'fact_inpatient_claimv2', 'fact_inpatient_claim'; /*Renaming the table.*/

/*Adding keys.*/
ALTER TABLE dbo.fact_inpatient_claim
ALTER COLUMN ClaimID BIGINT NOT NULL; /*The column ClaimID was set to 'NULLABLE' which wouldn't allow it to be a Primary Key. So, we changed it to 'Not Nullable'.*/

ALTER TABLE dbo.fact_inpatient_claim
ADD fact_inpatient_claim_key INT IDENTITY(1,1);

ALTER TABLE fact_inpatient_claim
ADD CONSTRAINT PK_fact_inpatient_claim PRIMARY KEY (fact_inpatient_claim_key); /*Primary Key*/

/* Adding beneficiary_year_key column in the table to connect it to the Yearly bene table.*/

ALTER TABLE fact_inpatient_claim
ADD beneficiary_year_key BIGINT;

UPDATE f
SET f.beneficiary_year_key = d.beneficiary_year_key
FROM fact_inpatient_claim f
JOIN dim_beneficiary_yearly d
	ON f.BeneficiaryID = d.BeneficiaryID
	AND YEAR (f.AdmissionDate) = d.Year;

ALTER TABLE fact_inpatient_claim
ADD CONSTRAINT FK_inpatient_beneficiary
FOREIGN KEY (beneficiary_year_key)
REFERENCES dim_beneficiary_yearly (beneficiary_year_key);
