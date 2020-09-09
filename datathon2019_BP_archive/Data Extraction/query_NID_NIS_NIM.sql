SELECT vap.patientunitstayid AS pid, vap.observationoffset AS off, vap.noninvasivesystolic AS NIS, vap.noninvasivediastolic AS NID, vap.noninvasivemean AS NIM
FROM `physionet-data.eicu_crd.vitalaperiodic` vap
WHERE vap.noninvasivesystolic IS NOT NULL AND  vap.noninvasivediastolic IS NOT NULL AND vap.noninvasivemean IS NOT NULL
ORDER BY vap.patientunitstayid
