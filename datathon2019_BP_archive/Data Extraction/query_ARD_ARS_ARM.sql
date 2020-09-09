SELECT vp.patientunitstayid AS qid, vp.observationoffset AS ooff, vp.heartrate AS hr, vp.systemicsystolic AS ARS, vp.systemicdiastolic AS ARD, vp.systemicmean AS ARM
FROM `physionet-data.eicu_crd.vitalperiodic` vp
WHERE vp.systemicsystolic IS NOT NULL AND vp.systemicdiastolic IS NOT NULL AND vp.systemicmean IS NOT NULL
ORDER BY vp.patientunitstayid
