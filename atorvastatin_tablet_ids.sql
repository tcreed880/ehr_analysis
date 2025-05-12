WITH single_ingredient_drugs AS (
 SELECT
   drug_concept_id
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.drug_strength`
 GROUP BY
   drug_concept_id
 HAVING
   COUNT(DISTINCT ingredient_concept_id) = 1
),


atorvastatin_tablets AS (
 SELECT
   ds.drug_concept_id,
   c.concept_name,
   ds.amount_value,
   c.vocabulary_id
 FROM
   `bigquery-public-data.cms_synthetic_patient_data_omop.drug_strength` ds
 JOIN
   `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
   ON ds.drug_concept_id = c.concept_id
 WHERE
   ds.ingredient_concept_id = 1545958  -- standard concept ID for atorvastatin
   AND ds.drug_concept_id IN (
     SELECT drug_concept_id FROM single_ingredient_drugs
   )
   AND LOWER(c.concept_name) LIKE '%tablet%'  -- optional: only keep tablets
)


SELECT *
FROM atorvastatin_tablets
ORDER BY concept_name;
