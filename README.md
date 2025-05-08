# EHR Readmission Analysis Project

This project simulates a real-world healthcare analytics workflow to identify patterns and risk factors for hospital readmissions using synthetic EHR (Electronic Health Records) data. It's designed to showcase skills relevant to data analyst roles in healthcare, including data wrangling, exploratory analysis, predictive modeling, and dashboard creation in Tableau.

## 🚀 Project Goals

* Use simulated EHR data to analyze hospital readmissions
* Build a simple predictive model to identify high-risk patients
* Create visualizations and dashboards to communicate insights
* Demonstrate Tableau skills for real-world healthcare data scenarios

## 📁 Project Structure

```
EHR-Readmission-Analysis/
├── data/                          # Raw data (synthetic or downloaded) — not tracked by Git
│   ├── demographics.csv
│   ├── encounters.csv
│   └── conditions.csv
├── output/                        # Outputs for Tableau or reports — not tracked by Git
│   └── patient_summary_for_tableau.csv
├── ehr_readmission_project.ipynb # Main analysis notebook
├── README.md                     # Project description (this file)
├── .gitignore                    # Files to exclude from version control
└── physionet.org/                # (Optional) Download directory — not tracked by Git
```

## 📊 Tools Used

* **Python (Pandas, Scikit-learn, Matplotlib)** — for data wrangling and modeling
* **Tableau** — for interactive dashboards
* **GitHub** — for version control and project showcase

## 📈 Example Questions to Explore

* What demographic factors are most associated with readmission?
* How do readmission rates vary by hospital department or condition?
* Can we build a simple model to flag high-risk patients for follow-up?

## ✅ How to Run

1. Clone or download the repo
2. Download the MIMIC-IV demo data from [here](https://physionet.org/content/mimiciv-demo/2.2/)
3. Move the contents of the `2.2/` folder into your project's `data/` directory:

   ```bash
   mv physionet.org/files/mimic-iv-demo/2.2/* data/
   ```
4. Navigate into the `data/` directory and unzip the `.csv.gz` files:

   ```bash
   cd data
   find . -name "*.csv.gz" -exec gunzip {} \;
   ```
5. Return to the project root and run the Jupyter notebook: `ehr_readmission_project.ipynb`
6. Explore the output CSV in Tableau to create dashboards

## 🧪 Sample Analysis Starter Code (MIMIC-IV Demo)

To identify hospital readmissions:

```python
import pandas as pd

# Load hospital admission and patient data
adm = pd.read_csv("data/hosp/admissions.csv")
pat = pd.read_csv("data/hosp/patients.csv")

# Merge admissions with patient demographics
df = adm.merge(pat, on="subject_id")

# Sort by patient and admission time
df = df.sort_values(by=["subject_id", "admittime"])

# Flag readmissions within 30 days
df['prev_dischtime'] = df.groupby('subject_id')['dischtime'].shift(1)
df['days_since_last_discharge'] = (
    pd.to_datetime(df['admittime']) - pd.to_datetime(df['prev_dischtime'])
).dt.days
df['readmitted_within_30'] = df['days_since_last_discharge'] <= 30

# Basic summary
readmission_rate = df['readmitted_within_30'].mean()
print(f"Readmission rate: {readmission_rate:.2%}")
```

## 🌍 Public Data Sources

* [Synthea EHR Simulator](https://synthetichealth.github.io/synthea/): Fully synthetic, realistic patient records with demographics, labs, meds, and diagnoses. Great for prototyping.
* [CMS Readmissions Data](https://data.cms.gov/): Real, aggregated hospital-level readmission rates. Good for dashboards and benchmarking but not suitable for patient-level modeling.
* [MIMIC-IV Demo](https://physionet.org/content/mimiciv-demo/2.2/): Real de-identified ICU patient data. Requires understanding of clinical schemas and CSV relationships. Demo version is downloadable without credentialing.

**Note:** If using MIMIC-IV demo, you'll need to decompress `.csv.gz` files (e.g., with `gunzip`) and selectively work with tables like `patients.csv.gz`, `admissions.csv.gz`, and `diagnoses_icd.csv.gz`. To unzip all at once, run:

```bash
cd data
find . -name "*.csv.gz" -exec gunzip {} \;
```

Use `brew install wget` if `wget` is not recognized in your terminal.

## 🛡️ What’s Not Tracked by Git

This repository excludes sensitive or bulky files using a `.gitignore` file. These folders are **not pushed to GitHub**:

* `data/` — raw or synthetic datasets
* `output/` — analysis outputs or dashboard inputs
* `physionet.org/` — download directory from PhysioNet

These folders must be created and populated manually on your local machine using the instructions above.

## 🎯 Showcase Your Work

* Publish your Tableau dashboard to Tableau Public
* Add screenshots or GIFs of dashboards to this repo
* Share your GitHub link in job applications or your portfolio!

## 🙋‍♀️ About

This project was created to build experience in clinical data analytics and improve job readiness for data analyst roles in healthcare. Created by \[Your Name].
