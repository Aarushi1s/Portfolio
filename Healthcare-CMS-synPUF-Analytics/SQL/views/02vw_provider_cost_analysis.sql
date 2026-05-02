Use HealthcareDB;

/*Creating a Provider Cost Analysis View (mainly for Fraud detection). Goal: Looking for anomalies, expensive providers, total money billed by each provider.*/

CREATE OR ALTER VIEW vw_provider_cost_analysis AS
WITH provider_agg AS(
	SELECT
		p.ProviderID,
		COUNT(*) AS total_claims,
		SUM(f.Total_Claim_Amount) AS total_paid,
		AVG(f.LOS) AS avg_los,
		AVG(f.Total_Claim_Amount) AS avg_claim_amount,
		STDEV(f.Total_Claim_Amount) AS stddev_claim_amount
	FROM fact_inpatient_claim f
	JOIN dim_provider p
		ON f.Provider_key = p.Provider_key
	GROUP BY p.ProviderID
)
SELECT *,
	CASE
		WHEN avg_claim_amount > 2* AVG(avg_claim_amount) OVER () /*If 2x compared to the global average then sus.*/
		THEN 1 ELSE 0
	END AS is_suspicious /*Used the 2x rule to quickly find Providers that are way more expensive than normal.*/
FROM provider_agg;

/*Created the View Provider Cost Analysis.*/