-- identify occurence concepts that are linked to statin use, concepts related to cardiovascular disease

WITH first_statin_fill AS (
 SELECT
   person_id,
   MIN(drug_exposure_start_date) AS first_fill_date
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
 WHERE
   drug_concept_id IN (
     SELECT drug_concept_id FROM `mimic-iv-459422.statin_analysis.atorvastatin_tablet_ids`
   )
 GROUP BY person_id
),


linked_conditions AS (
 SELECT
   c.person_id,
   c.condition_concept_id,
   c.condition_start_date
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` c
 JOIN
   first_statin_fill f
 ON
   c.person_id = f.person_id
 WHERE
   DATE_DIFF(f.first_fill_date, c.condition_start_date, DAY) BETWEEN 0 AND 7
)


SELECT
 lc.condition_concept_id,
 COUNT(*) AS count,
 co.concept_name
FROM
 linked_conditions lc
JOIN
 `bigquery-public-data.cms_synthetic_patient_data_omop.concept` co
 ON lc.condition_concept_id = co.concept_id
GROUP BY
 lc.condition_concept_id,
 co.concept_name
ORDER BY
 count DESC;
