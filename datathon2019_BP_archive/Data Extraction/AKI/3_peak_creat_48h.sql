WITH peakcr AS
  (SELECT patientunitstayid,
          labresultoffset AS peakcreat48h_offset,
          labresult AS peakcreat48h,
          Row_number() OVER (PARTITION BY patientunitstayid
                             ORDER BY lab.labresult DESC) AS POSITION
   FROM lab
   WHERE labname LIKE 'creatinine%'
     AND labresultoffset >= 0
     AND labresultoffset <= (48 * 60) --Within 48hrs

   GROUP BY patientunitstayid,
            labresultoffset,
            labresult
   ORDER BY patientunitstayid,
            labresultoffset)
SELECT patientunitstayid
, peakcreat48h_offset
, peakcreat48h
FROM peakcr
WHERE POSITION = 1
