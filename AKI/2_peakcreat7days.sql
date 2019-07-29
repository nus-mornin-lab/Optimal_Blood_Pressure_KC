WITH peakcr 
     AS (SELECT * 
         FROM   (SELECT patientunitstayid, 
                        labresultoffset AS peakcreat7d_offset, 
                        labresult AS peakcreat7d, 
                        Row_number() 
                          OVER ( 
                            partition BY patientunitstayid 
                            ORDER BY lab.labresult DESC) AS position 
                 FROM   lab 
                 WHERE  labname LIKE 'creatinine%' 
                        AND labresultoffset >= 0 
                        AND labresultoffset <= 10080 
                 GROUP  BY patientunitstayid, 
                           labresultoffset, 
                           labresult 
                 ORDER  BY patientunitstayid, 
                           labresultoffset) AS temp 
         WHERE  position = 1) 
SELECT pt.patientunitstayid, 
       peakcreat7d, 
       peakcreat7d_offset, 
       ( pt.unitdischargeoffset - peakcreat7d_offset ) AS 
       peakcreat7d_to_discharge_offsetgap 
FROM   patient pt 
       LEFT OUTER JOIN peakcr 
                    ON peakcr.patientunitstayid = pt.patientunitstayid 
ORDER  BY pt.patientunitstayid 
