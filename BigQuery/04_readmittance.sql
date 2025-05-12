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
