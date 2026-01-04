Time from Hospital Admission to First Antibiotic Administration

Project Overview

Timely administration of antibiotics is an important component of inpatient clinical workflows and is commonly used as a process and quality metric, particularly in time-sensitive clinical contexts such as sepsis. Measuring the interval between hospital admission and antibiotic administration can provide insight into care processes and workflow variability.
This project uses the MIMIC-IV Clinical Database (demo) to measure the time from hospital admission to first antibiotic administration. The primary goal is to demonstrate clinical informatics reasoning around cohort definition, time anchoring, event identification, and workflow measurement.

Data Source and Tools

Data were obtained from the MIMIC-IV Clinical Database (demo), using the admissions and emar tables. PostgreSQL was used for data storage and querying, with DBeaver as the database software.
Each row in the final analytic dataset represents a single de-identified hospital admission, identified by a unique hospital admission identifier (hadm_id) and a unique patient identifier (subject_id).

Methods

The unit of analysis for this project was a single hospital admission. Hospital admission time (admittime) from the admissions table was used as the time anchor, representing the start of the inpatient encounter.
Medication administration time was obtained from the emar table using charttime, which represents the documented time of medication administration at the bedside. This field was used as a proxy for the timing of antibiotic administration.
Medication administration events were restricted to records where event_txt indicated "Administered" or "Started", in order to capture actual or initiated medication delivery and exclude non-administration events (e.g., “Not Given,” “Stopped,” or “Assessed”).


Antibiotics were identified using medication name pattern matching based on common antibiotic prefixes (e.g., cef%, vanc%, pip%, mero%). This list was not exhaustive and was intended to only capture commonly used inpatient antibiotics.
For each hospital admission, at most one antibiotic administration time was identified. Specifically, the earliest qualifying antibiotic administration (earliest_admin) was selected per hadm_id. Admissions without any qualifying antibiotic administration were retained in the dataset with a null administration time.
An indicator (abx_flag) was created to identify whether antibiotics were administered during the admission (1) or not (0).


Time to antibiotic administration (time_to_abx) was calculated as the difference between earliest_admin and admittime, expressed in minutes. Some admissions had negative values, indicating antibiotics administered prior to the recorded admission time (e.g., during emergency department care). These values were retained in the dataset for transparency but were excluded from summary timing statistics.
Summary statistics for time to antibiotic administration were reported using the median and interquartile range (IQR) to account for the skewed distribution of timing values.

Results

Among 275 hospital admissions in the demo dataset, 32% (88 admissions) received at least one qualifying antibiotic. Of these, 19 admissions had negative time-to-antibiotic values and were excluded from timing summaries.
Among the remaining 69 admissions, the median time from admission to first antibiotic administration was 1,220 minutes (~20.3 hours), with an interquartile range of 354 minutes (~5.9 hours) to 4,604 minutes (~3.2 days). The shortest observed time to antibiotic administration was 1 minute, and the longest was 22,607 minutes (~15.7 days).

Limitations

Several limitations should be considered when interpreting these results. First, this analysis used the MIMIC-IV demo dataset, which is limited in size and may not reflect real-world hospital workflows. Second, antibiotic identification relied on text-based medication name matching, which may result in false positives or missed medications. Third, clinical indication for antibiotic use (e.g., sepsis, prophylaxis, or treatment of hospital-acquired infection) was not available, limiting clinical context for the observed timing patterns.
As a result, findings should be interpreted as descriptive measurements of inpatient workflow rather than benchmarks of care quality or indicators of clinical performance.

