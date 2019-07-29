-- Chronic patients with AKI receiving rrt prior to ICU admission
-- Criteria A
SELECT
  DISTINCT treatment.patientunitstayid
FROM
  eicu_crd_v2.treatment
WHERE
  LOWER(treatment.treatmentstring) LIKE ANY ('{%rrt%,%dialysis%,%ultrafiltration%,%cavhd%,%cvvh%,%sled%}')
  AND 
  LOWER(treatment.treatmentstring) LIKE '%chronic%'
-- Criteria B
-- we don't want to be so strict with the exclusion criteria so we only exclude those patients found with Criteria A
/*
UNION  
  SELECT
  DISTINCT apacheapsvar.patientunitstayid
FROM
  eicu_crd_v2.apacheapsvar
WHERE
  apacheapsvar.dialysis = 1 -- chronic dialysis prior to hospital adm
*/