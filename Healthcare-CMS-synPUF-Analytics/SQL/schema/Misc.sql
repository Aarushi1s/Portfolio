Use HealthcareDB;

/*Making the necessary changes to connect the schema using FK and PK.*/

ALTER TABLE dim_beneficiary_current
ADD CONSTRAINT PK_dim_beneficiary_current
PRIMARY KEY (BeneficiaryID);

ALTER TABLE dim_beneficiary_current
ALTER COLUMN BeneficiaryID VARCHAR(50) NOT NULL;

SELECT COUNT(*) 
FROM dim_provider
WHERE ProviderID IS NULL; /*check for any nulls*/

ALTER TABLE dim_provider
ADD CONSTRAINT PK_dim_provider
PRIMARY KEY (ProviderID); /*Alter col to not null.*/

ALTER TABLE dim_provider
ALTER COLUMN ProviderID VARCHAR(20) NOT NULL;

SELECT COUNT(*)
FROM dim_beneficiary_yearly
WHERE beneficiary_year_key IS NULL;

ALTER TABLE dim_beneficiary_yearly
ALTER COLUMN beneficiary_year_key BIGINT NOT NULL;

ALTER TABLE dim_beneficiary_yearly
ADD CONSTRAINT PK_dim_beneficiary_yearly
PRIMARY KEY (beneficiary_year_key);

ALTER TABLE fact_carrier_claim
ALTER COLUMN CLM_ID VARCHAR(50) NOT NULL;

ALTER TABLE fact_carrier_claim
ADD CONSTRAINT PK_fact_carrier_claim
PRIMARY KEY (CLM_ID);

ALTER TABLE fact_prescription_drug
ALTER COLUMN pde_id VARCHAR(80) NOT NULL;

ALTER TABLE fact_prescription_drug
ADD CONSTRAINT PK_fact_pde
PRIMARY KEY (pde_id);

ALTER TABLE fact_inpatient_claim
ADD CONSTRAINT FK_inpatient_beneficiary
FOREIGN KEY (beneficiary_year_key)
REFERENCES dim_beneficiary_yearly (beneficiary_year_key);

ALTER TABLE dim_beneficiary_current
DROP CONSTRAINT PK_dim_beneficiary_current;

ALTER TABLE dim_beneficiary_current
ALTER COLUMN beneficiary_key BIGINT NOT NULL;

ALTER TABLE dim_beneficiary_current
ADD CONSTRAINT PK_dim_beneficiary_current
PRIMARY KEY (beneficiary_key);

ALTER TABLE fact_outpatient_claim
ADD CONSTRAINT FK_outpatient_beneficiary_year
FOREIGN KEY (beneficiary_year_key)
REFERENCES dim_beneficiary_yearly (beneficiary_year_key);

ALTER TABLE fact_outpatient_claim
ADD CONSTRAINT FK_outpatient_beneficiary
FOREIGN KEY (beneficiary_key)
REFERENCES dim_beneficiary_current (beneficiary_key);

SELECT DISTINCT f.beneficiary_key
FROM fact_outpatient_claim f
LEFT JOIN dim_beneficiary_current d
    ON f.beneficiary_key = d.beneficiary_key
WHERE d.beneficiary_key IS NULL; /*56295*/

SELECT DISTINCT COUNT (*) beneficiary_key
FROM fact_outpatient_claim /*779537*/

SELECT name
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('dim_beneficiary_current')
  AND type = 'PK';

ALTER TABLE fact_carrier_claim
ADD CONSTRAINT FK_carrier_beneficiary_year
FOREIGN KEY (beneficiary_year_key)
REFERENCES dim_beneficiary_yearly (beneficiary_year_key);

ALTER TABLE fact_carrier_claim_line
ADD CONSTRAINT FK_carrier_claim
FOREIGN KEY (clm_id)
REFERENCES fact_carrier_claim (CLM_ID);

ALTER TABLE bridge_carrier_diagnosis
ADD CONSTRAINT FK_carrier_claim_diagnosis
FOREIGN KEY (ClaimID)
REFERENCES fact_carrier_claim (CLM_ID);

ALTER TABLE dbo.dim_provider
DROP CONSTRAINT PK_dim_provider;

ALTER TABLE dbo.dim_provider
ADD CONSTRAINT PK_dim_provider
PRIMARY KEY (Provider_key);

ALTER TABLE fact_inpatient_claim
ADD CONSTRAINT FK_inpatient_provider
FOREIGN KEY (Provider_key)
REFERENCES dim_provider;

ALTER TABLE fact_outpatient_claim
ADD CONSTRAINT FK_outpatient_provider
FOREIGN KEY (Provider_key)
REFERENCES dim_provider;

/*Renaming some cols.*/

EXEC sp_rename 'dbo.fact_prescription_drug.desynpuf_id', 'BeneficiaryID', 'COLUMN';
EXEC sp_rename 'dbo.fact_prescription_drug.pde_id', 'PrescriptionDrugEventID', 'COLUMN';
EXEC sp_rename 'dbo.fact_prescription_drug.srvc_dt', 'ServiceDate', 'COLUMN';
EXEC sp_rename 'dbo.fact_prescription_drug.prod_srvc_id', 'ProductServiceID', 'COLUMN';
EXEC sp_rename 'dbo.fact_prescription_drug.qty_dspnsd_num', 'QuantityDispensedNumber', 'COLUMN';
EXEC sp_rename 'dbo.fact_prescription_drug.days_suply_num', 'DaysSupplyNumber', 'COLUMN';
EXEC sp_rename 'dbo.fact_prescription_drug.ptnt_pay_amt', 'PatientPayAmount', 'COLUMN';
EXEC sp_rename 'dbo.fact_prescription_drug.tot_rx_cst_amt', 'GrossDrugCost', 'COLUMN';

ALTER TABLE dbo.fact_prescription_drug
ADD beneficiary_year_key INT;

ALTER TABLE dbo.fact_prescription_drug
ADD ServiceYear INT;

UPDATE fact_prescription_drug
SET ServiceYear = TRY_CAST(LEFT(ServiceDate, 4) AS INT);

UPDATE f
SET f.beneficiary_year_key = b.beneficiary_year_key
FROM fact_prescription_drug f
JOIN dim_beneficiary_yearly b
	ON f.BeneficiaryID = b.BeneficiaryID
	AND f.ServiceYear = b.Year;

SELECT
	COUNT(*) AS total_rows,
	SUM(CASE WHEN beneficiary_year_key IS NULL THEN 1 ELSE 0 END) AS unmatched_rows
FROM fact_prescription_drug; /*Validating the column*/

ALTER TABLE fact_prescription_drug
ALTER COLUMN beneficiary_year_key BIGINT NOT NULL;

ALTER TABLE fact_prescription_drug
ADD CONSTRAINT FK_fact_rx_beneficiary_year
FOREIGN KEY(beneficiary_year_key)
REFERENCES dim_beneficiary_yearly (beneficiary_year_key);

ALTER TABLE fact_prescription_drug
DROP COLUMN ServiceDate; /*Dropping the column since it has corrupted data and re-inserting it.*/

ALTER TABLE fact_prescription_drug
ADD ServiceDate DATE;

UPDATE f
SET f.ServiceDate = s.SRVC_DT
FROM fact_prescription_drug f
JOIN dbo.pde_s1 s
	ON f.BeneficiaryID = s.DESYNPUF_ID;

SELECT TOP 10 ServiceDate
FROM fact_prescription_drug;

ALTER TABLE fact_prescription_drug
ADD service_date_key INT;

UPDATE fact_prescription_drug
SET service_date_key = 
	CONVERT(INT, FORMAT(ServiceDate, 'yyyyMMdd'));

ALTER TABLE fact_prescription_drug
ADD CONSTRAINT FK_prescription_date
FOREIGN KEY (service_date_key)
REFERENCES dim_date(date_key);

ALTER TABLE fact_inpatient_claim
ADD admission_date_key INT,
	discharge_date_key INT;

UPDATE fact_inpatient_claim
SET admission_date_key = CONVERT(INT, FORMAT(AdmissionDate, 'yyyyMMdd')),
	discharge_date_key = CONVERT(INT, FORMAT(DischargeDate, 'yyyyMMdd'));

SELECT *
FROM fact_inpatient_claim f
LEFT JOIN dim_date d
	ON f.admission_date_key = d.date_key
WHERE d.date_key IS NULL;

ALTER TABLE fact_inpatient_claim
ADD CONSTRAINT FK_inpatient_admission_date
FOREIGN KEY (admission_date_key)
REFERENCES dim_date(date_key);

ALTER TABLE fact_inpatient_claim
ADD CONSTRAINT FK_inpatient_discharge_date
FOREIGN KEY (discharge_date_key)
REFERENCES dim_date(date_key); 

ALTER TABLE fact_outpatient_claim
ADD claim_start_date_key INT,
	claim_end_date_key INT;

UPDATE fact_outpatient_claim
SET claim_start_date_key = CONVERT(INT, FORMAT(ClaimStartDate, 'yyyyMMdd')),
	claim_end_date_key = CONVERT(INT, FORMAT(ClaimEndDate, 'yyyyMMdd'));

SELECT *
FROM fact_outpatient_claim f
LEFT JOIN dim_date d1 ON f.claim_start_date_key = d1.date_key
LEFT JOIN dim_date d2 ON f.claim_end_date_key = d2.date_key
WHERE d1.date_key IS NULL
OR d2.date_key IS NULL;

ALTER TABLE fact_outpatient_claim
ADD CONSTRAINT FK_outpatient_start_date
FOREIGN KEY (claim_start_date_key)
REFERENCES dim_date(date_key);

ALTER TABLE fact_outpatient_claim
ADD CONSTRAINT FK_outpatient_end_date
FOREIGN KEY (claim_end_date_key)
REFERENCES dim_date(date_key);

ALTER TABLE fact_carrier_claim
ADD claim_from_date_key INT,
	claim_thru_date_key INT;

UPDATE fact_carrier_claim
SET claim_from_date_key = CONVERT(INT, FORMAT(CLM_FROM_DT, 'yyyyMMdd')),
	claim_thru_date_key = CONVERT(INT, FORMAT(CLM_THRU_DT, 'yyyyMMdd'));

SELECT *
FROM fact_carrier_claim f
LEFT JOIN dim_date d1 ON f.claim_from_date_key = d1.date_key
LEFT JOIN dim_date d2 ON f.claim_thru_date_key = d2.date_key
WHERE d1.date_key IS NULL
OR d2.date_key IS NULL;

ALTER TABLE fact_carrier_claim
ADD CONSTRAINT FK_carrier_from_date
FOREIGN KEY (claim_from_date_key)
REFERENCES dim_date(date_key);

ALTER TABLE fact_carrier_claim
ADD CONSTRAINT FK_carrier_thru_date
FOREIGN KEY (claim_thru_date_key)
REFERENCES dim_date(date_key);

/*Renaming some cols.*/

EXEC sp_rename 'fact_carrier_claim_line.prf_physn_npi', 'ProviderPhysicianNPI', 'COLUMN';
EXEC sp_rename 'fact_carrier_claim_line.line_nch_pmt_amt', 'LineNCHPaymentAmount', 'COLUMN';
EXEC sp_rename 'fact_carrier_claim_line.line_alowd_chrg_amt', 'LineAllowedChargeAmount', 'COLUMN';
EXEC sp_rename 'fact_carrier_claim_line.line_bene_ptb_ddctbl_amt', 'LineBenePartBDeductibleAmount', 'COLUMN';
EXEC sp_rename 'fact_carrier_claim_line.line_coinsrnc_amt', 'LineCoinsuranceAmount', 'COLUMN';
EXEC sp_rename 'fact_carrier_claim_line.line_icd9_dgns_cd', 'LineICD9diagnosisCode', 'COLUMN';