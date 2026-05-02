Use HealthcareDB;

/*Creating View High Risk Claims. Goal: fidning sus/abnormal/High-risk inpatient claims.*/

CREATE OR ALTER VIEW vw_high_risk_claims AS
WITH avg_by_diagnosis AS (
	SELECT
		Diagnosis_Code,
		AVG(Total_Claim_amount) AS avg_amount
	FROM fact_inpatient_claim
	GROUP BY Diagnosis_Code
)
SELECT
	f.ClaimID,
	f.BeneficiaryID,
	f.Diagnosis_Code,
	f.Total_Claim_Amount,
	f.Medicare_Paid_Amount,
	f.LOS,
	CASE
		WHEN f.LOS > 30 THEN 'Long Stay'
		WHEN f.Total_Claim_Amount > 3 * d.avg_amount THEN 'High vs Diagnosis Avg'
		WHEN f.Medicare_Paid_Amount = 0 AND f.Total_Claim_Amount > 10000 THEN 'Zero Medicare Payment'
		ELSE 'Normal'
	END AS risk_reason
FROM fact_inpatient_claim f
JOIN avg_by_diagnosis d
	ON f.Diagnosis_Code = d.Diagnosis_Code

WHERE
	f.LOS > 30
	OR f.Total_Claim_Amount > 3 * d.avg_amount
	OR (f.Medicare_paid_amount = 0 AND f.Total_Claim_Amount > 10000);

/* Created View High Risk Claims.*/
