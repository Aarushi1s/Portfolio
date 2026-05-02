USE HealthcareDB;

/* High Cost Patient Analysis.
Which state + age groups drive Highest Cost?
Answer: State code 08 and 09 in the age group of 46-60 drive the highest cost.   */

SELECT TOP 20 * FROM vw_high_cost_patients
ORDER BY total_claim_amount DESC;

SELECT 
	State, 
	age_bucket,
	COUNT(*) AS patient_count,
	AVG(total_claim_amount) AS avg_cost
FROM vw_high_cost_patients
GROUP BY State, age_bucket
ORDER BY avg_cost DESC;





/*Diagnosis Cost Burden
Which diseases dominate healthcare spending?
Answer: Symptoms & Signs category dominates the healthcare spending by 19.8%. */

SELECT TOP 10 * FROM vw_diagnosis_cost
ORDER BY total_amount DESC;

SELECT
	Disease_Category, total_amount,
	total_amount * 100.0 /SUM(total_amount) OVER () AS contribution_pct
FROM vw_diagnosis_cost
ORDER BY total_amount DESC;





/*Fraud/Suspicious Claims Analysis
How many claims are risky?
Answer: 3,131 which forms the  ~4.7% of the total claims.
What's their financial Impact?
Answer: High Risk Claims account for 11,70,85,050 with an average claim size of ~37,395.
Comment: Only ~4.7% of claims are flagged as high-risk, but they account for a disproportionately high average cost (~4.3x higher), indicating concentrated financial risk.*/

SELECT
	CASE
		WHEN hr.ClaimID IS NOT NULL THEN 1
		ELSE 0
	END AS suspicious_flag,
	COUNT(*) AS claim_count,
	AVG(fc.Total_Claim_Amount) AS avg_amount,
	SUM(fc.Total_Claim_Amount) AS total_amount
FROM fact_inpatient_claim fc
LEFT JOIN vw_high_risk_claims hr
	ON fc.ClaimID = hr.ClaimID
GROUP BY
	CASE
		WHEN hr.ClaimID IS NOT NULL THEN 1
		ELSE 0
	END;

SELECT 
    100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_inpatient_claim) AS risky_percentage
FROM vw_high_risk_claims; /*Percent.*/





/*Age Wise Cost Contribution
Which age segment costs the system the most?
Answer: People of the age group 76+ cost the system the most with a total cost of 67,94,47,680 and an average cost of 18,466.26  */

SELECT
	age_bucket,
	COUNT(*) AS claims,
	SUM(total_cost) AS Total_Claim_Cost,
	AVG(total_cost) AS avg_cost
FROM vw_cost_by_demographics
GROUP BY age_bucket
ORDER BY Total_Claim_Cost DESC;





/*State-wise Healthcare Spend
Geographic cost distribution?
Answer: Healthcare spending is highly concentrated in a few states, with states 05, 10, 45 contributing the highest total spend. This is due to Higher patient Volumes.
Average spend per patient remains relatively consistent (12k-16k range), indicating the cost intensity is similar across regiosn.
However, a few states(e.g., 31,21,28) show higher-than-average per patient costs, suggesting localized drivers such as higher severity, treatment intensity, or healthcare pricing differences.*/

SELECT
	State,
	Count(*) AS patient_count,
	SUM(total_claim_amount) AS Total_Spend,
	AVG(total_claim_amount) AS avg_spend
FROM vw_high_cost_patients
GROUP BY State
ORDER BY Total_Spend DESC;