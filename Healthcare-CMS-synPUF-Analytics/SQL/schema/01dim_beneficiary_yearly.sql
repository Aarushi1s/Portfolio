Use HealthcareDB;

 /* Inserting raw data into staging table with their respective years for each row.*/
SELECT * INTO stg_beneficiary_all_years
FROM (
	SELECT *, 2008 AS Year
	FROM dbo.bene_2008_s1
	UNION ALL
	SELECT *, 2009 AS Year
	FROM dbo.bene_2009_s1
	UNION ALL
	SELECT *, 2010 AS Year
	FROM dbo.bene_2010_s1
	) t;


 /* Validating staging table Data by retrieving no. of rows grouped by each year.*/
SELECT Year, COUNT(*)
FROM dbo.stg_beneficiary_all_years
GROUP BY Year;


 /* Transforming Data and adding it into dim_beneficiary_yearly table.*/
 /* Using the ROW_NUMBER() function to assign a number to each row as a surrogate key. */
 /* Changed the data types and handled Null values. */
SELECT
	ROW_NUMBER() OVER (ORDER BY DESYNPUF_ID, Year) AS beneficiary_year_key,
	DESYNPUF_ID AS BeneficiaryID,
	Year,
	CAST(BENE_BIRTH_DT AS date) AS DOB,
	CAST(NULLIF(BENE_DEATH_DT, '') AS date) AS DOD,

	CASE
		WHEN BENE_SEX_IDENT_CD = 1 THEN 'Male'
		WHEN BENE_SEX_IDENT_CD = 2 THEN 'Female'
		ELSE 'Unknown'
	END AS Gender,

	BENE_RACE_CD AS Race,
	SP_STATE_CODE AS State,
	BENE_COUNTY_CD AS County,
	Year - CAST(LEFT(BENE_BIRTH_DT, 4) AS INT) AS Age,
	BENE_HI_CVRAGE_TOT_MONS AS PartA_Months,
	BENE_SMI_CVRAGE_TOT_MONS AS PartB_Months,
	BENE_HMO_CVRAGE_TOT_MONS AS HMO_Months,
	PLAN_CVRG_MOS_NUM AS Plan_Coverage_Months,

	CASE WHEN SP_ALZHDMTA = 1 THEN 1 ELSE 0 END AS Has_Alzheimer,
	CASE WHEN SP_CHF = 1 THEN 1 ELSE 0 END AS Has_HeartFailure,
	CASE WHEN SP_CHRNKIDN = 1 THEN 1 ELSE 0 END AS Has_KidneyDisease,
	CASE WHEN SP_CNCR = 1 THEN 1 ELSE 0 END AS Has_Cancer,
	CASE WHEN SP_COPD = 1 THEN 1 ELSE 0 END AS Has_COPD,
	CASE WHEN SP_DEPRESSN = 1 THEN 1 ELSE 0 END AS Has_Depression,
	CASE WHEN SP_DIABETES = 1 THEN 1 ELSE 0 END AS Has_Diabetes,
	CASE WHEN SP_ISCHMCHT = 1 THEN 1 ELSE 0 END AS Has_IschemicHeart,
	CASE WHEN SP_OSTEOPRS = 1 THEN 1 ELSE 0 END AS Has_Osteoporosis,
	CASE WHEN SP_RA_OA = 1 THEN 1 ELSE 0 END AS Has_RA_OA,
	CASE WHEN SP_STRKETIA = 1 THEN 1 ELSE 0 END AS Has_StrokeTIA,

	MEDREIMB_IP,
	BENRES_IP,
	PPPYMT_IP,
	MEDREIMB_OP,
	BENRES_OP,
	PPPYMT_OP,
	MEDREIMB_CAR,
	BENRES_CAR,
	PPPYMT_CAR
INTO dim_beneficiary_yearly
FROM dbo.stg_beneficiary_all_years;

/*Validating Data.*/
SELECT TOP 10 * FROM dbo.dim_beneficiary_yearly;