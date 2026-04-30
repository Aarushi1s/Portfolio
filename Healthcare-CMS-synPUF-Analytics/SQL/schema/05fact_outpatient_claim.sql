Use HealthcareDB;

/*Creating the raw staging table.*/

CREATE TABLE stg_outpatient_raw (
    DESYNPUF_ID VARCHAR(50),
    CLM_ID BIGINT,
    SEGMENT INT,
    CLM_FROM_DT DATE,
    CLM_THRU_DT DATE,
    PRVDR_NUM VARCHAR(20),
    CLM_PMT_AMT FLOAT,
    NCH_PRMRY_PYR_CLM_PD_AMT FLOAT,
    AT_PHYSN_NPI VARCHAR(20),
    OP_PHYSN_NPI VARCHAR(20),
    OT_PHYSN_NPI VARCHAR(20),
    NCH_BENE_BLOOD_DDCTBL_LBLTY_AM FLOAT,
    NCH_BENE_PTB_DDCTBL_AMT FLOAT,
    NCH_BENE_PTB_COINSRNC_AMT FLOAT
);

INSERT INTO dbo.stg_outpatient_raw (
	DESYNPUF_ID,
	CLM_ID,
	SEGMENT,
	CLM_FROM_DT,
	CLM_THRU_DT,
	PRVDR_NUM,
	CLM_PMT_AMT,
	NCH_PRMRY_PYR_CLM_PD_AMT,
	AT_PHYSN_NPI,
	OP_PHYSN_NPI,
	OT_PHYSN_NPI,
	NCH_BENE_BLOOD_DDCTBL_LBLTY_AM,
	NCH_BENE_PTB_DDCTBL_AMT,
	NCH_BENE_PTB_COINSRNC_AMT
)
SELECT
	DESYNPUF_ID,
	CLM_ID,
	SEGMENT,
	CLM_FROM_DT,
	CLM_THRU_DT,
	PRVDR_NUM,
	CLM_PMT_AMT,
	NCH_PRMRY_PYR_CLM_PD_AMT,
	AT_PHYSN_NPI,
	OP_PHYSN_NPI,
	OT_PHYSN_NPI,
	NCH_BENE_BLOOD_DDCTBL_LBLTY_AM,
	NCH_BENE_PTB_DDCTBL_AMT,
	NCH_BENE_PTB_COINSRNC_AMT
FROM dbo.outpatient_s1

/*Checking for duplicates. Validating Data: */

SELECT CLM_ID , COUNT(*)
FROM stg_outpatient_raw
GROUP BY CLM_ID
HAVING COUNT(*) > 1; /* 10975 CLM_IDs are repeated twice in the dataset.*/

SELECT *
FROM dbo.stg_outpatient_raw
WHERE CLM_ID IN (
	SELECT CLM_ID
	FROM dbo.stg_outpatient_raw
	GROUP BY CLM_ID
	HAVING COUNT(*) > 1
)
ORDER BY CLM_ID  /*Shows what exactly is repeated within the dataset. We have dirty data on "Segment = 2" columns, which we'll remove.*/

/*Removing duplicates*/

/*Re-validating data: */

SELECT *
INTO stg_outpatient_filtered
FROM stg_outpatient_raw
WHERE SEGMENT = 1;

SELECT CLM_ID, COUNT(*)
FROM stg_outpatient_filtered
GROUP BY CLM_ID
HAVING COUNT(*) > 1; /*Checked for duplicates again. 0 duplicates.*/

/* Joining Outpatient claims with their respective beneficiary_year_key and provider_key */

SELECT
	o.CLM_ID,
	b.beneficiary_year_key,
	p.Provider_key,
	o.SEGMENT,
	o.CLM_FROM_DT,
	o.CLM_THRU_DT,
	o.CLM_PMT_AMT,
	o.NCH_PRMRY_PYR_CLM_PD_AMT,
	o.AT_PHYSN_NPI,
	o.OP_PHYSN_NPI,
	o.OT_PHYSN_NPI,
	o.NCH_BENE_BLOOD_DDCTBL_LBLTY_AM,
	o.NCH_BENE_PTB_DDCTBL_AMT,
	o.NCH_BENE_PTB_COINSRNC_AMT

INTO stg_outpatient_enriched
FROM stg_outpatient_filtered o
LEFT JOIN dim_beneficiary_current b
	ON o.DESYNPUF_ID = b.BeneficiaryID
LEFT JOIN dim_provider p
	ON o.PRVDR_NUM = p.ProviderID;

/*Validating data.*/

SELECT COUNT(*)
FROM stg_outpatient_enriched
WHERE beneficiary_year_key IS NULL; /* Missing beneficiaries = 0 */

SELECT COUNT(*)
FROM stg_outpatient_enriched
WHERE provider_key IS NULL; /* Missing providers = 444759 : which means that there are values that do not match the dim_provider.*/

/*Fixed the dim_provider in the 04dim_provider.sql file.*/

DROP TABLE IF EXISTS stg_outpatient_enriched; /*Because it has nulls in provider id and we have fixed it now. So, need to refresh/remake the table*/

/*Creating the final Fact Outpatienct Claim table.*/

CREATE TABLE fact_outpatient_claim (
	fact_outpatient_claim_key INT IDENTITY(1,1) PRIMARY KEY,

	ClaimID BIGINT NOT NULL,
	beneficiary_key BIGINT,
	Provider_key INT,
	ClaimSegment INT,
	ClaimStartDate DATE,
	ClaimEndDate DATE,
	ClaimPaymentAmount FLOAT,
	PrimaryPayerAmount FLOAT,
	AttendingPhysicianNPI VARCHAR(20),
	OperatingPhysicianNPI VARCHAR(20),
	OtherPhysicianNPI VARCHAR(20),
	BloodDeductibleAmount FLOAT,
	PartBDeductibleAmount FLOAT,
	PartBCoinsuranceAmount FLOAT
);

INSERT INTO fact_outpatient_claim (
	ClaimID,
	beneficiary_key,
	Provider_key,
	ClaimSegment,
	ClaimStartDate,
	ClaimEndDate,
	ClaimPaymentAmount,
	PrimaryPayerAmount,
	AttendingPhysicianNPI,
	OperatingPhysicianNPI,
	OtherPhysicianNPI,
	BloodDeductibleAmount,
	PartBDeductibleAmount,
	PartBCoinsuranceAmount
)
SELECT
	CLM_ID,
	beneficiary_year_key,
	Provider_key,
	SEGMENT,
	CLM_FROM_DT,
	CLM_THRU_DT,
	CLM_PMT_AMT,
	NCH_PRMRY_PYR_CLM_PD_AMT,
	AT_PHYSN_NPI,
	OP_PHYSN_NPI,
	OT_PHYSN_NPI,
	NCH_BENE_BLOOD_DDCTBL_LBLTY_AM,
	NCH_BENE_PTB_DDCTBL_AMT,
	NCH_BENE_PTB_COINSRNC_AMT
FROM stg_outpatient_enriched;

/*Validating the data.*/

SELECT COUNT(*) FROM stg_outpatient_enriched;
SELECT COUNT(*) FROM fact_outpatient_claim;

SELECT ClaimID, COUNT(*)
FROM fact_outpatient_claim
GROUP BY ClaimID
HAVING COUNT(*) > 1;

SELECT COUNT(*)
FROM fact_outpatient_claim
WHERE beneficiary_year_key IS NULL
OR Provider_key IS NULL;
