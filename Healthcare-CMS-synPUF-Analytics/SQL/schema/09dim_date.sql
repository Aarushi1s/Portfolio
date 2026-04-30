Use HealthcareDB;

/*Creating DIM DATE table.*/

/*checking for the first and last dates in the dataset.*/

SELECT MIN(date_val) AS min_date
FROM (
    SELECT TRY_CAST(ServiceDate AS DATE) FROM fact_prescription_drug
    UNION ALL
    SELECT AdmissionDate FROM fact_inpatient_claim
    UNION ALL
    SELECT DischargeDate FROM fact_inpatient_claim
    UNION ALL
    SELECT ClaimStartDate FROM fact_outpatient_claim
    UNION ALL
    SELECT ClaimEndDate FROM fact_outpatient_claim
    UNION ALL
    SELECT CLM_FROM_DT FROM fact_carrier_claim
    UNION ALL
    SELECT CLM_THRU_DT FROM fact_carrier_claim
    UNION ALL
    SELECT DOB FROM dim_beneficiary_yearly
    UNION ALL
    SELECT DOD FROM dim_beneficiary_yearly
) t(date_val);	/*Minimum date in my dataset.*/

SELECT MAX(date_val) AS max_date
FROM (
    SELECT TRY_CAST(ServiceDate AS DATE) FROM fact_prescription_drug
    UNION ALL
    SELECT AdmissionDate FROM fact_inpatient_claim
    UNION ALL
    SELECT DischargeDate FROM fact_inpatient_claim
    UNION ALL
    SELECT ClaimStartDate FROM fact_outpatient_claim
    UNION ALL
    SELECT ClaimEndDate FROM fact_outpatient_claim
    UNION ALL
    SELECT CLM_FROM_DT FROM fact_carrier_claim
    UNION ALL
    SELECT CLM_THRU_DT FROM fact_carrier_claim
    UNION ALL
    SELECT DOB FROM dim_beneficiary_yearly
    UNION ALL
    SELECT DOD FROM dim_beneficiary_yearly
) t(date_val);	/*Maximum date in my dataset.*/

/*creating the Dim Date.*/

CREATE TABLE dim_date(
	date_key INT PRIMARY KEY,
	full_date DATE,
	day INT,
	month INT,
	year INT,
	day_name VARCHAR(10),
	month_name VARCHAR(10),
	quarter INT,
	week_of_year INT,
	is_weekend BIT
);

/*Populating the dim_date*/

WITH DateCTE AS (
	SELECT CAST('1909-01-01' AS DATE) AS full_date
	UNION ALL
	SELECT DATEADD(DAY, 1, full_date)
	FROM DateCTE
	WHERE full_date < '2010-12-31'
)
INSERT INTO dim_date(
	date_key,
	full_date,
	day,
	month,
	year,
	day_name,
	month_name,
	quarter,
	week_of_year,
	is_weekend
)
SELECT
	CONVERT (INT, FORMAT(full_date, 'yyyyMMdd')),
	full_date,
	DAY(full_date),
	MONTH(full_date),
	YEAR(full_date),
	DATENAME(WEEKDAY, full_date),
	DATENAME(MONTH, full_date),
	DATEPART(QUARTER, full_date),
	DATEPART(WEEK, full_date),
	CASE
		WHEN DATENAME(WEEKDAY, full_date) IN ('Saturday', 'Sunday') THEN 1
		ELSE 0
	END
	FROM DateCTE
	OPTION (MAXRECURSION 0); /*Maxrecursion 0 because default value is 100 which means it'd stop at 100 rows when our table needs around 37K rows.*/

