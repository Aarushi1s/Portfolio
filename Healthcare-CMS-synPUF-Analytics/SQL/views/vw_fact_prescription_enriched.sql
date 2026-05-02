Use HealthcareDB;

/*Creating a view of Prescription drug table to have the data be extracted by year.*/

CREATE OR ALTER VIEW vw_fact_prescription_enriched AS
SELECT
f.PrescriptionDrugEventID,
f.BeneficiaryID,
f.ServiceDate,
TRY_CAST(
	CONCAT(
		LEFT(f.ServiceDate, 4), '-',
		SUBSTRING(f.ServiceDate, 5, 2), '-',
		RIGHT(f.ServiceDate, 2)
		) AS Date
	) AS ServiceDateClean,
TRY_CAST(LEFT(f.ServiceDate, 4) AS INT) AS ServiceYear,
f.ProductServiceID,
f.QuantityDispensedNumber,
f.DaysSupplyNumber,
f.PatientPayAmount,
f.GrossDrugCost,

b.beneficiary_year_key,
b.DOB,
b.DOD,
b.Gender,
b.Race,
b.State,
b.County,
b.Age,
b.Has_Alzheimer,
b.Has_HeartFailure,
b.Has_KidneyDisease,
b.Has_Cancer,
b.Has_COPD,
b.Has_Depression,
b.Has_Diabetes,
b.Has_IschemicHeart,
b.Has_Osteoporosis,
b.Has_RA_OA,
b.Has_StrokeTIA,
b.PartA_Months,
b.PartB_Months,
b.Plan_Coverage_Months,
b.MEDREIMB_CAR,
b.BENRES_CAR,
b.PPPYMT_CAR

FROM fact_prescription_drug f
LEFT JOIN dim_beneficiary_yearly b
	ON f.BeneficiaryID = b.BeneficiaryID
	AND TRY_CAST(LEFT(f.ServiceDate, 4) AS INT) = b.Year;

/*Validating the view now.*/

SELECT COUNT(*) AS view_row_count FROM vw_fact_prescription_enriched;
SELECT COUNT(*) AS source_row_count FROM fact_prescription_drug;

SELECT TOP 10
	PrescriptionDrugEventID,
	BeneficiaryID,
	ServiceDate,
	ServiceDateClean,
	ServiceYear,
	State,
	Age,
	Has_Diabetes,
	GrossDrugCost
FROM vw_fact_prescription_enriched
ORDER BY GrossDrugCost DESC;