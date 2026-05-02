Use HealthcareDB;

/*Creating View Cost by Demographics. Goal: Segregating the data as per the demography.*/

CREATE OR ALTER VIEW vw_cost_by_demographics AS
WITH total_cost AS(
	SELECT BeneficiaryID, ClaimYear, SUM(cost) AS total_Cost
	FROM (
		/*Inpatient*/
		SELECT BeneficiaryID, YEAR(AdmissionDate) AS ClaimYear,
			SUM(Total_Claim_Amount) AS cost
		FROM fact_inpatient_claim
		GROUP BY BeneficiaryID, YEAR(AdmissionDate)
		UNION ALL
		/*Outpatient*/
		SELECT BeneficiaryID, Year(o.ClaimStartDate) AS ClaimYear,
			SUM(
			COALESCE(o.ClaimPaymentAmount, 0)+
			COALESCE(o.PrimaryPayerAmount, 0)+
			COALESCE(o.PartBDeductibleAmount, 0)+
			COALESCE(o.PartBCoinsuranceAmount, 0)
		) AS cost
		FROM fact_outpatient_claim o
		JOIN dim_beneficiary_yearly b
			ON o.beneficiary_year_key = b.beneficiary_year_key
		GROUP BY b.BeneficiaryID, YEAR(o.ClaimStartDate)
		UNION ALL
		/*Carrier(line-level)*/
		SELECT 
			c.BeneficiaryID, 
			YEAR(c.ClaimStartDate) AS ClaimYear,
			SUM(
			COALESCE(l.LineNCHPaymentAmount, 0)+
			COALESCE(l.LineBenePartBDeductibleAmount, 0)+
			COALESCE(l.LineCoinsuranceAmount, 0)
		) AS cost
		FROM fact_carrier_claim_line l
		JOIN fact_carrier_claim c
			ON l.ClaimID = c.ClaimID
		GROUP BY c.BeneficiaryID, YEAR (c.ClaimStartDate)
	) t
	GROUP BY BeneficiaryID, ClaimYear
)
SELECT b.State,
	b.Year,
	CASE
		WHEN b.Age BETWEEN 25 AND 45 THEN '25-45'
		WHEN b.Age BETWEEN 46 AND 60 THEN '46-60'
		WHEN b.Age BETWEEN 61 AND 75 THEN '61-75'
		ELSE '76+'
	END as age_bucket,
	b.Has_Diabetes,
	b.Has_HeartFailure,
	b.Has_COPD,
	b.Has_Alzheimer,
    b.Has_Depression,
    b.Has_IschemicHeart,
    b.Has_Osteoporosis,
    b.Has_RA_OA,
    b.Has_StrokeTIA,
    b.Has_Cancer,
    b.Has_KidneyDisease,
	SUM(t.total_cost) AS total_cost,
	COUNT(DISTINCT t.BeneficiaryID) AS patient_count
FROM total_cost t
JOIN dim_beneficiary_yearly b
	ON t.BeneficiaryID = b.BeneficiaryID
	AND t.ClaimYear = b.Year
GROUP BY b.Year,
b.State,
CASE
	WHEN b.Age BETWEEN 25 AND 45 THEN '25-45'
	WHEN b.Age BETWEEN 46 AND 60 THEN '46-60'
	WHEN b.Age BETWEEN 61 AND 75 THEN '61-75'
	ELSE '76+'
END,
b.Has_Diabetes,
b.Has_HeartFailure,
b.Has_COPD,
b.Has_Alzheimer,
b.Has_Depression,
b.Has_IschemicHeart,
b.Has_Osteoporosis,
b.Has_RA_OA,
b.Has_StrokeTIA,
b.Has_Cancer,
b.Has_KidneyDisease;

/*Created Cost by demographics View.*/
