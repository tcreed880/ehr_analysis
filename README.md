# 🩺 Statin Adherence and Cardiovascular Readmission Analysis (OMOP + BigQuery)

This project explores how medication adherence to **atorvastatin** relates to **readmissions for cardiovascular conditions** using synthetic EHR data formatted in the **OMOP Common Data Model**.

All data comes from the **CMS Synthetic Patient Dataset**, hosted publicly in **BigQuery**.

---

## 📌 Objectives

- Identify patients prescribed atorvastatin
- Quantify statin adherence using prescription refill patterns
- Define clinically relevant 30-day readmissions
- Model the association between non-adherence and CVD-related readmissions
- Adjust for demographics and comorbidities using OMOP fields

---

## 🧪 Methods

### 🧍 1. Cohort Definition
- Patients with ≥2 prescriptions for **oral, single-ingredient atorvastatin tablets**
### 🧮 2. Adherence Measures
- **Late refill** defined as a gap > 30 days between expected vs. actual refill date
- Flags:
  - `low_adherence_flag`: any refill gap > 30 days or >20% late refills
  - `late_refill_rate`: percent of refills that were late

### 💔 3. Readmission Outcome
- Used `condition_occurrence` to identify **cardiovascular-related diagnoses**:
  - e.g., hypercholesterolemia, CAD, chest pain, MI, stroke
- Patients flagged as `readmitted_within_30d_for_CVD` if a qualifying diagnosis occurred within 30 days of a previous one

### 🧾 4. Covariates
- Extracted from `person`, `condition_occurrence`, and `drug_exposure`
- Included:
  - `age` at first statin fill
  - `gender`, `race`, `ethnicity` (joined from concept table)
  - Comorbidities: `has_diabetes`, `has_ckd`, `has_heart_disease`
  - `num_unique_meds` as proxy for polypharmacy

---

## 📁 Key Tables

| Table | Description |
|-------|-------------|
| `atorvastatin_tablet_ids` | Cleaned list of drug_concept_ids for eligible statin prescriptions |
| `late_refiller` | Adherence metrics per patient |
| `readmittance` | Adds 30-day readmission outcome |
| `final_analysis_table` | Combined table with outcome + covariates for modeling |

---

## 🧠 Planned Analysis

Using the final patient-level dataset:

```python
logit(P(readmitted_within_30d_for_CVD)) ~ low_adherence_flag + age + gender + race + comorbidities + num_unique_meds
Models will be built in Python using pandas, statsmodels, and scikit-learn.

📦 Tech Stack
SQL / BigQuery (OMOP CDM v5.3)

Python (Jupyter)

CMS Synthetic Patient Data (2008–2010)

OMOP vocabulary tables: concept, drug_exposure, condition_occurrence, person

📍 Next Steps
Export final table from BigQuery to Python

Run logistic regression and interpret adjusted odds ratios

(Optional) Expand to 60/90-day readmissions or time-to-event modeling

👤 Author
[Your Name]
📫 Contact: [your.email@example.com]
🎓 Project developed to demonstrate real-world EHR analysis skills using OMOP + SQL + Python.
