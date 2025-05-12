WITH atorvastatin_exposure AS (
 SELECT
   person_id,
   drug_exposure_start_date,
   days_supply,
   drug_concept_id,
   ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY drug_exposure_start_date) AS rx_order,
   LAG(drug_exposure_start_date) OVER (PARTITION BY person_id ORDER BY drug_exposure_start_date) AS previous_start,
   LAG(days_supply) OVER (PARTITION BY person_id ORDER BY drug_exposure_start_date) AS previous_days_supply
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
 WHERE
   drug_concept_id IN (
     SELECT drug_concept_id FROM `mimic-iv-459422.statin_analysis.atorvastatin_tablet_ids`
   )
)


SELECT
 person_id,
 drug_exposure_start_date,
 previous_start,
 previous_days_supply,
 DATE_DIFF(drug_exposure_start_date, DATE_ADD(previous_start, INTERVAL IFNULL(previous_days_supply, 0) DAY), DAY) AS refill_gap_days
FROM
 atorvastatin_exposure
WHERE
 rx_order > 1
ORDER BY
 person_id, drug_exposure_start_date;


QUery for late_refiller flag > 20% 
SELECT
 person_id,
 COUNT(*) AS total_refills,
 SUM(CASE WHEN refill_gap_days > 30 THEN 1 ELSE 0 END) AS late_refills,
 SAFE_DIVIDE(SUM(CASE WHEN refill_gap_days > 30 THEN 1 ELSE 0 END), COUNT(*)) AS late_refill_rate,
 CASE
   WHEN SAFE_DIVIDE(SUM(CASE WHEN refill_gap_days > 30 THEN 1 ELSE 0 END), COUNT(*)) > 0.2 THEN 1
   ELSE 0
 END AS low_adherence_flag
FROM
 `mimic-iv-459422.statin_analysis.refill_gaps`
GROUP BY person_id
