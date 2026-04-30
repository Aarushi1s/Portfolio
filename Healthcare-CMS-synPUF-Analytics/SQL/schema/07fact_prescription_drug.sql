Use HealthcareDB;

/*Creating Fact Prescription Drug table.*/

CREATE TABLE fact_prescription_drug(
	desynpuf_id VARCHAR(20),
	pde_id VARCHAR(20),
	srvc_dt VARCHAR(8),     
	prod_srvc_id VARCHAR(20),
	qty_dspnsd_num DECIMAL(10,3),
	days_suply_num INT,
	ptnt_pay_amt DECIMAL(10,2),
	tot_rx_cst_amt DECIMAL(10,2)
);

INSERT INTO fact_prescription_drug (
  pde_id, desynpuf_id, prod_srvc_id, srvc_dt,
  qty_dspnsd_num, days_suply_num, ptnt_pay_amt, tot_rx_cst_amt
)
SELECT
  PDE_ID,
  DESYNPUF_ID,
  PROD_SRVC_ID,
  CAST(SRVC_DT AS DATE),           
  QTY_DSPNSD_NUM,
  DAYS_SUPLY_NUM,
  PTNT_PAY_AMT,
  TOT_RX_CST_AMT
FROM dbo.pde_s1
WHERE PDE_ID IS NOT NULL
  AND DESYNPUF_ID IS NOT NULL;