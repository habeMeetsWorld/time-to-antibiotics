/*
Project: Time from hospital admission to first antibiotic administation
Dataset: MIMIC-IV Clinical Database Demo 
Author: Habib Olagoke
Platform: PostgreSQL

Output: 
	- View: public.admission_abx_timing
	  One row per admission with:
	 - hadm_id: unique identifier for each patient hospitalization 
	 - subject_id: unique identifier which specifies an individual patient
	 - admittime: date and time the patient was admitted to the hospital
	 - earliest_admin: first qualifying antibiotic administration time (may contain null values)
	 - abx_flag: 1 if antibiotics found, else 0
	 - time_to_abx: minutes from admittime to earliest_admin (may contain null and negative values)

Notes: 
	- Uses admissions.admittime as time anchor.
	- Uses emar.charttime as administration proxy.
	- Administration events limited to 'Administered' and 'Started' in 	emar.event_txt.
	- Antibiotics indentified via medication name pattern matching (not exhaustive).
	- Negative time_to_abx are preserved but excluded from time summaries.
 */


-- 0. Setup / schema fixes (Run setup once; comment out after initial build.) --

-- Fix varchar length issues for demo imports 
alter table public.prescriptions 
alter column prod_strength type TEXT; 

alter table public.emar 
alter column medication type TEXT;

-- Ensure timestamps are real timestamps (required for time math)
alter table public.admissions 
alter column admittime type TIMESTAMP 
using admittime::timestamp; 

alter table public.emar 
alter column charttime type TIMESTAMP 
using charttime::timestamp;

-- 1. Create admission-level view: admission_abx_timing -- 

CREATE OR REPLACE VIEW public.admission_abx_timing AS 
SELECT 
	a.hadm_id, 
	a.subject_id,
	a.admittime,
	s1.earliest_admin,
	CASE 
		WHEN s1.earliest_admin IS NULL THEN 0
		ELSE 1
	END AS abx_flag,
	CASE
		WHEN s1.earliest_admin IS NOT NULL 
			THEN EXTRACT (EPOCH FROM (s1.earliest_admin -  a.admittime))/60.0
		ELSE NULL
	END AS time_to_abx
FROM public.admissions AS a
LEFT JOIN (SELECT e.hadm_id, MIN(charttime) AS earliest_admin
FROM public.emar AS e
WHERE 
	e.charttime IS NOT NULL 
	AND e.hadm_id IS NOT null
	-- Administration-like events (proxy for dose administered/started)
	AND e.event_txt IN ('Administered', 'Started')
	-- Antibiotics indentified via medication name pattern matching (not exhaustive)
	AND (
	 e.medication ILIKE 'cef%' -- ceftriaxone, cefepime, etc.
	 OR e.medication ILIKE 'vanc%' -- vancomycin
	 OR e.medication ILIKE 'pip%' -- piperacillin
	 OR e.medication ILIKE 'mero%' -- meropenem
	 OR e.medication ILIKE 'metro%' -- metronidazole
	 OR e.medication ILIKE 'levoflox%' -- levofloxacin
	 OR e.medication ILIKE 'cipro%' -- ciprofloxacin
	 OR e.medication ILIKE 'amox%' -- amoxicillin (incl amox-clav)
	 OR e.medication ILIKE 'azith%' -- azithromycin
	 OR e.medication ILIKE 'doxy%' -- doxycycline
	 OR e.medication ILIKE 'clinda%' -- clindamycin
	 OR e.medication ILIKE 'bactrim%' -- Trimethoprim/sulfamethoxazole
)	
GROUP BY e.hadm_id
) AS s1
ON a.hadm_id = s1.hadm_id; 

-- 2. Summary stats (leave commneted out; uncomment and run as needed) --

-- View of admission_abx_timing
-- SELECT *
-- FROM public.admission_abx_timing
-- LIMIT 20;

-- Cohort size and antibiotic receipt rate
-- SELECT 
--	COUNT(*) as admission_count,
--	SUM(abx_flag) as abx_admission_count,
--	SUM(abx_flag)::numeric / COUNT(*) * 100 as abx_admission_pct
-- FROM public.admission_abx_timing;

-- Count of negative time_to_abx values 
-- SELECT 
--	COUNT(*) as negative_abx_time_count
-- FROM public.admission_abx_timing
-- WHERE time_to_abx < 0;

-- Timing summaries (excluding negative time_to_abx and null values)
-- SELECT 
--	COUNT(*) AS nonneg_time_to_abx_count,
-- 	MIN(time_to_abx) AS min_time_to_abx,
-- 	MAX(time_to_abx) AS max_time_to_abx,
-- 	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY time_to_abx) AS p25,
-- 	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY time_to_abx) AS median,
-- 	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY time_to_abx) AS p75
-- FROM public.admission_abx_timing
-- WHERE time_to_abx >= 0;

-- 3. Additional exploration -- 

-- Should equal total admissions
-- SELECT COUNT(*) FROM public.admission_abx_timing;

-- No duplicate hadm_id
-- SELECT hadm_id, COUNT(*) 
-- FROM public.admission_abx_timing
-- GROUP BY hadm_id
-- HAVING COUNT(*) > 1;

-- Nulls exist (admissions without antibiotics)
-- SELECT COUNT(*) 
-- FROM public.admission_abx_timing
-- WHERE earliest_admin IS NULL;

-- Inspect event types available in emar table
 -- SELECT e.event_txt, COUNT(*) AS n
 -- FROM public.emar e
 -- GROUP BY e.event_txt
 -- ORDER BY n DESC;

-- Inspect antibiotic names captured by the pattern list
-- SELECT DISTINCT e.medication
-- FROM public.emar e
-- WHERE e.event_txt IN ('Administered', 'Started')
--    AND e.charttime IS NOT NULL
--   AND e.hadm_id IS NOT NULL
--   AND (
--     e.medication ILIKE 'cef%'
--     OR e.medication ILIKE 'vanc%'
--     OR e.medication ILIKE 'pip%'
--     OR e.medication ILIKE 'mero%'
--     OR e.medication ILIKE 'metro%'
--     OR e.medication ILIKE 'levoflox%'
--     OR e.medication ILIKE 'cipro%'
--     OR e.medication ILIKE 'amox%'
--     OR e.medication ILIKE 'azith%'
--     OR e.medication ILIKE 'doxy%'
--     OR e.medication ILIKE 'clinda%'
--     OR e.medication ILIKE 'bactrim%'
--  )
-- ORDER BY e.medication;
