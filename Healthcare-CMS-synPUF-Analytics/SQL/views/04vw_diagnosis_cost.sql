Use HealthcareDB;

/*Creating View Diagnosis Cost. Goal: Most common diagnosis, most expensive overall, high cost per case.*/

CREATE OR ALTER VIEW vw_diagnosis_cost AS
WITH all_diagnosis AS (
	/*Inpatient*/
	SELECT
		ClaimID,
		Diagnosis_Code,
		Total_Claim_Amount AS amount
	FROM fact_inpatient_claim
	WHERE Diagnosis_Code IS NOT NULL
		AND LTRIM(RTRIM(Diagnosis_Code)) <> ''
	UNION ALL
	/*Carrier Claim Line*/
	SELECT
		ClaimID,
		LineICD9diagnosisCode AS Diagnosis_Code,
		COALESCE(cl.LineNCHPaymentAmount, 0) +
		COALESCE(cl.LineBenePartBDeductibleAmount, 0) +
		COALESCE(cl.LineCoinsuranceAmount, 0) AS amount
	FROM fact_carrier_claim_line cl
	WHERE LineICD9diagnosisCode IS NOT NULL
		AND LTRIM(RTRIM(LineICD9diagnosisCode)) <> ''
),
/*Cleaned to add Diagnosis Code Descriptions.*/
cleaned AS (
	SELECT
		ClaimID,
		UPPER(LTRIM(RTRIM(Diagnosis_Code))) AS Diagnosis_Code,
		amount
		FROM all_diagnosis
)
SELECT
	CASE
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '001' AND '139' THEN 'Infectious Diseases'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '140' AND '239' THEN 'Neoplasms'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '240' AND '279' THEN 'Endocrine Disorders'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '280' AND '289' THEN 'Blood Diseases'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '290' AND '319' THEN 'Mental Disorders'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '320' AND '389' THEN 'Nervous System'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '390' AND '459' THEN 'Circulatory System'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '460' AND '519' THEN 'Respiratory Diseases'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '520' AND '579' THEN 'Digestive System'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '580' AND '629' THEN 'Genitourinary'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '680' AND '709' THEN 'Skin Diseases'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '710' AND '739' THEN 'Musculoskeletal'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '780' AND '799' THEN 'Symptoms & Signs'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '800' AND '999' THEN 'Injury & Poisoning'
		WHEN Diagnosis_Code LIKE 'V%' THEN 'Supplementary Factors'
		WHEN Diagnosis_Code LIKE 'E%' THEN 'External Causes'
		ELSE 'Other'
	END AS Disease_Category,
	COUNT(*) AS claim_count,
	AVG(amount) AS avg_amount,
	SUM(amount) AS total_amount
FROM cleaned
GROUP BY
	CASE
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '001' AND '139' THEN 'Infectious Diseases'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '140' AND '239' THEN 'Neoplasms'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '240' AND '279' THEN 'Endocrine Disorders'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '280' AND '289' THEN 'Blood Diseases'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '290' AND '319' THEN 'Mental Disorders'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '320' AND '389' THEN 'Nervous System'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '390' AND '459' THEN 'Circulatory System'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '460' AND '519' THEN 'Respiratory Diseases'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '520' AND '579' THEN 'Digestive System'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '580' AND '629' THEN 'Genitourinary'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '680' AND '709' THEN 'Skin Diseases'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '710' AND '739' THEN 'Musculoskeletal'
        WHEN LEFT(Diagnosis_Code,3) BETWEEN '780' AND '799' THEN 'Symptoms & Signs'
		WHEN LEFT(Diagnosis_Code,3) BETWEEN '800' AND '999' THEN 'Injury & Poisoning'
		WHEN Diagnosis_Code LIKE 'V%' THEN 'Supplementary Factors'
		WHEN Diagnosis_Code LIKE 'E%' THEN 'External Causes'
		ELSE 'Other'
	END;

SELECT TOP 20 *
FROM vw_diagnosis_cost
ORDER BY total_amount DESC;

/* Created View Diagnosis Cost.*/