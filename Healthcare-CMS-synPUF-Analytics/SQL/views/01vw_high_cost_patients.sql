Use HealthcareDB;

/*Creating View High Cost Patients. Goal: Total cost per patient + rank + demographics*/

/*Since in the view we will be binning ages, Doing a bit of EDA on the age of my beneficiaries here.*/

SELECT 
    Age,
    COUNT(*) AS patient_count
FROM dim_beneficiary_current
GROUP BY Age
ORDER BY Age; /*There's no data for below 26. I've decided on binning here 25-45, 46-60, 61-75, 76+ */

CREATE OR ALTER VIEW vw_high_cost_patients AS

WITH inpatient_cost AS(
	SELECT
		BeneficiaryID,
		SUM(Total_Claim_Amount) as Cost
	FROM fact_inpatient_claim
	GROUP BY BeneficiaryID
),
outpatient_cost AS(
	SELECT
		b.BeneficiaryID,
		SUM(
			COALESCE(o.ClaimPaymentAmount, 0) +
			COALESCE(o.PrimaryPayerAmount, 0) +
			COALESCE(o.PartBDeductibleAmount, 0) +
			COALESCE(o.PartBCoinsuranceAmount, 0) +
			COALESCE(o.BloodDeductibleAmount, 0)
		) AS cost
	FROM fact_outpatient_claim o
	JOIN dim_beneficiary_yearly b
		ON o.beneficiary_year_key = b.beneficiary_year_key
	GROUP BY b.BeneficiaryID
),
carrier_cost AS(
	SELECT
		c.BeneficiaryID,
		SUM(
			COALESCE(l.LineNCHPaymentAmount, 0) + 
			COALESCE(l.LineBenePartBDeductibleAmount, 0) +
			COALESCE(l.LineCoinsuranceAmount, 0)
		) AS cost
	FROM fact_carrier_claim_line l
	INNER JOIN fact_carrier_claim c
		ON l.ClaimID = c.ClaimID
	GROUP BY c.BeneficiaryID
),
total_cost AS(
	SELECT BeneficiaryID, SUM(cost) AS total_claim_amount
	FROM (
		SELECT * FROM inpatient_cost
		UNION ALL
		SELECT * FROM outpatient_cost
		UNION ALL
		SELECT * FROM carrier_cost
	) t
	GROUP BY BeneficiaryID
), /*All the aggregation has been done so far here and saved as : inpatient_cost, outpatient_cost, carrier_cost, total_cost. */
comorbidity AS(
	SELECT
		BeneficiaryID,
		/*Presence across ANY year*/
		MAX(COALESCE(Has_Diabetes, 0))+
		MAX(COALESCE(Has_HeartFailure, 0))+
		MAX(COALESCE(Has_COPD, 0)) +
        MAX(COALESCE(Has_KidneyDisease, 0)) +
        MAX(COALESCE(Has_Cancer, 0)) +
        MAX(COALESCE(Has_StrokeTIA, 0)) +
        MAX(COALESCE(Has_IschemicHeart, 0)) +
        MAX(COALESCE(Has_Alzheimer, 0)) +
        MAX(COALESCE(Has_Depression, 0)) +
        MAX(COALESCE(Has_Osteoporosis, 0)) +
        MAX(COALESCE(Has_RA_OA, 0)) AS comorbidity_score
	FROM dim_beneficiary_yearly
	GROUP BY BeneficiaryID
), /*Created a comorbidity score to count the no. of diseases in patients.*/
chronic_conditions AS(
	SELECT
		BeneficiaryID,
		RTRIM(CONCAT(
				CASE WHEN MAX(Has_Diabetes) = 1 THEN 'Diabetes, ' ELSE '' END,
				CASE WHEN MAX(Has_HeartFailure) = 1 THEN 'Heart Failure, ' ELSE '' END,
				CASE WHEN MAX(Has_COPD) = 1 THEN 'COPD, ' ELSE '' END,
				CASE WHEN MAX(Has_KidneyDisease) = 1 THEN 'Kidney Disease, ' ELSE '' END,
				CASE WHEN MAX(Has_Cancer) = 1 THEN 'Cancer, ' ELSE '' END,
				CASE WHEN MAX(Has_StrokeTIA) = 1 THEN 'Stroke/TIA, ' ELSE '' END,
				CASE WHEN MAX(Has_IschemicHeart) = 1 THEN 'Ischemic Heart, ' ELSE '' END,
				CASE WHEN MAX(Has_Alzheimer) = 1 THEN 'Alzheimer, ' ELSE '' END,
				CASE WHEN MAX(Has_Depression) = 1 THEN 'Depression, ' ELSE '' END,
				CASE WHEN MAX(Has_Osteoporosis) = 1 THEN 'Osteoporosis, ' ELSE '' END,
				CASE WHEN MAX(Has_RA_OA) = 1 THEN 'RA/OA, ' ELSE '' END
			), ', ') AS chronic_conditions /*taking in patients' chronic conditions.*/
FROM dim_beneficiary_yearly
GROUP BY BeneficiaryID
),
latest_demo AS(
	SELECT *
	FROM (
		SELECT *,
		ROW_NUMBER() OVER (PARTITION BY BeneficiaryID ORDER BY Year DESC
	) AS rn
	FROM dim_beneficiary_yearly
)t
WHERE rn = 1
) /*Demographics (Latest Snapshot)*/
SELECT
	t.BeneficiaryID,
	t.total_claim_amount,
	RANK() OVER (ORDER BY t.total_claim_amount DESC) AS cost_rank,
	d.State,
	CASE
		WHEN d.Age BETWEEN 25 AND 45 THEN '25-45'
		WHEN d.Age BETWEEN 46 AND 60 THEN '46-60'
		WHEN d.Age BETWEEN 61 AND 75 THEN '61-75'
		ELSE '76+'
	END AS age_bucket, /*binned the ages for easier analysis.*/
	c.comorbidity_score,
	cc.chronic_conditions
FROM total_cost t
LEFT JOIN comorbidity c
	ON t.BeneficiaryID = c.BeneficiaryID
LEFT JOIN chronic_conditions cc
	ON t.BeneficiaryID = cc.BeneficiaryID
LEFT JOIN latest_demo d
	ON t.BeneficiaryID = d.BeneficiaryID;

/*Created the View High Cost Patients.*/