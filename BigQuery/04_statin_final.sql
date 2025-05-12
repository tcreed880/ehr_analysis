-- joins covariates, low_adherence/late_refiller, readmission data into one table
WITH statin_related_conditions AS (
 SELECT
   person_id,
   condition_start_date,
   condition_concept_id,
   LAG(condition_start_date) OVER (PARTITION BY person_id ORDER BY condition_start_date) AS previous_condition_date
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
 WHERE
   condition_concept_id IN (
     437827,     -- Pure hypercholesterolemia
     42872402,   -- Coronary arteriosclerosis in native artery
     77670,      -- Chest pain
     314659,     -- Myocardial infarction (optional)
     314378,     -- Ischemic heart disease
     372924,     -- Stroke
     315295      -- Atherosclerotic heart disease
   )
),


-- Step 2: Flag readmissions within 30 days
readmission_flags AS (
 SELECT
   person_id,
   DATE_DIFF(condition_start_date, previous_condition_date, DAY) AS days_between
 FROM
   statin_related_conditions
 WHERE
   previous_condition_date IS NOT NULL
   AND DATE_DIFF(condition_start_date, previous_condition_date, DAY) BETWEEN 1 AND 30
),


-- Step 3: Collapse to per-patient readmission status
per_patient_readmission AS (
 SELECT
   person_id,
   1 AS readmitted_within_30d_for_CVD
 FROM
   readmission_flags
 GROUP BY person_id
)


-- Step 4: Join to your late_refiller table
SELECT
 lr.person_id,
 lr.total_refills,
 lr.late_refills,
 lr.late_refill_rate,
 lr.low_adherence_flag,
 IF(r.person_id IS NOT NULL, 1, 0) AS readmitted_within_30d_for_CVD
FROM
 `mimic-iv-459422.statin_analysis.late_refiller` lr
LEFT JOIN
 per_patient_readmission r
ON
 lr.person_id = r.person_id;


Final Full Table with Covariates for Patients in readmittance:
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
