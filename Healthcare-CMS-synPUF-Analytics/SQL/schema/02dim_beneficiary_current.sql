USE HealthcareDB;

/* Making dim_beneficiary_current table for all the patient wise latest records to create a master list of beneficiaries.*/

/* Using the Row_NUMBER() function to only take the latest records available of Beneficiaries by Year. */
SELECT *,
	ROW_NUMBER() OVER (ORDER BY BeneficiaryID) AS beneficiary_key
INTO dim_beneficiary_current
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY BeneficiaryID
            ORDER BY Year DESC
        ) AS rn
    FROM dim_beneficiary_yearly
) t
WHERE rn = 1;

/* Validating the table. */
SELECT COUNT(*) FROM dim_beneficiary_current;

ALTER TABLE dim_beneficiary_current
DROP COLUMN rn;

SELECT TOP 5 beneficiary_key, BeneficiaryID
FROM dim_beneficiary_current;

SELECT COUNT(*) FROM dim_beneficiary_current;
SELECT COUNT(DISTINCT BeneficiaryID)
FROM dim_beneficiary_current;
