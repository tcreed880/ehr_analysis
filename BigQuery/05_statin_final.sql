-- joins covariates, low_adherence/late_refiller, readmission data into one table

-- Step 1: Cohort of statin users (already in readmittance)
WITH cohort AS (
 SELECT person_id FROM `mimic-iv-459422.statin_analysis.readmittance`
),


-- Step 2: First atorvastatin fill per patient
first_fill AS (
 SELECT
   person_id,
   MIN(drug_exposure_start_date) AS first_fill_date
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
 WHERE
   drug_concept_id IN (
     SELECT drug_concept_id FROM `mimic-iv-459422.statin_analysis.atorvastatin_tablet_ids`
   )
   AND person_id IN (SELECT person_id FROM cohort)
 GROUP BY person_id
),


-- Step 3: Demographics with labels and correct age
demographics AS (
 SELECT
   p.person_id,
   EXTRACT(YEAR FROM f.first_fill_date) - p.year_of_birth AS age,
   g.concept_name AS gender,
   r.concept_name AS race,
   e.concept_name AS ethnicity
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.person` p
 JOIN
   first_fill f ON p.person_id = f.person_id
 LEFT JOIN
   `bigquery-public-data.cms_synthetic_patient_data_omop.concept` g ON p.gender_concept_id = g.concept_id
 LEFT JOIN
   `bigquery-public-data.cms_synthetic_patient_data_omop.concept` r ON p.race_concept_id = r.concept_id
 LEFT JOIN
   `bigquery-public-data.cms_synthetic_patient_data_omop.concept` e ON p.ethnicity_concept_id = e.concept_id
),
-- Step 3: Comorbidities
comorbidities AS (
 SELECT
   person_id,
   MAX(CASE WHEN condition_concept_id = 201826 THEN 1 ELSE 0 END) AS has_diabetes,       -- Type 2 diabetes
   MAX(CASE WHEN condition_concept_id = 443597 THEN 1 ELSE 0 END) AS has_ckd,            -- CKD stage 3
   MAX(CASE WHEN condition_concept_id IN (315295, 42872402) THEN 1 ELSE 0 END) AS has_heart_disease
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
 WHERE person_id IN (SELECT person_id FROM cohort)
 GROUP BY person_id
),


-- Step 4: Polypharmacy (unique drugs per patient)
polypharmacy AS (
 SELECT
   person_id,
   COUNT(DISTINCT drug_concept_id) AS num_unique_meds
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
 WHERE person_id IN (SELECT person_id FROM cohort)
 GROUP BY person_id
)


-- Step 5: Join everything to your main readmittance table
SELECT
 r.person_id,
 r.total_refills,
 r.late_refills,
 r.late_refill_rate,
 r.low_adherence_flag,
 r.readmitted_within_30d_for_CVD,
 d.age,
 d.gender,
 d.race,
 d.ethnicity,
 c.has_diabetes,
 c.has_ckd,
 c.has_heart_disease,
 p.num_unique_meds
FROM
 `mimic-iv-459422.statin_analysis.readmittance` r
LEFT JOIN
 demographics d USING (person_id)
LEFT JOIN
 comorbidities c USING (person_id)
LEFT JOIN
 polypharmacy p USING (person_id);
