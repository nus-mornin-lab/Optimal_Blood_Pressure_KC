DROP MATERIALIZED VIEW IF EXISTS AKI_creat;
CREATE MATERIALIZED VIEW AKI_creat AS

WITH tempo AS
  ( SELECT patientunitstayid,
           labname,
           labresultoffset,
           labresult,
           ROW_NUMBER() OVER (PARTITION BY patientunitstayid, labname ORDER BY labresultoffset ASC) AS POSITION
   FROM eicu.lab
   WHERE ((labname) = 'creatinine')
     AND labresultoffset BETWEEN -720 AND 720 -- first creat available value between -12 and +12h from admission 
     ORDER BY patientunitstayid, labresultoffset ),
     
base_creat as (
SELECT patientunitstayid,
       max(CASE WHEN (labname) = 'creatinine' AND POSITION =1 THEN labresult ELSE NULL END) AS creat1,
       max(CASE WHEN (labname) = 'creatinine' AND POSITION =1 THEN labresultoffset ELSE NULL END) AS creat1offset
FROM tempo
GROUP BY patientunitstayid
ORDER BY patientunitstayid
),

peakcr AS (SELECT * 
         FROM   (SELECT patientunitstayid, 
                        labresultoffset AS peakcreat7d_offset, 
                        labresult AS peakcreat7d, 
                        Row_number() 
                          OVER ( 
                            partition BY patientunitstayid 
                            ORDER BY lab.labresult DESC) AS position 
                 FROM   eicu.lab 
                 WHERE  labname LIKE 'creatinine%' 
                        AND labresultoffset >= 0 
                        AND labresultoffset <= 10080 
                 GROUP  BY patientunitstayid, 
                           labresultoffset, 
                           labresult 
                 ORDER  BY patientunitstayid, 
                           labresultoffset) AS temp 
         WHERE  position = 1),
         
peak_7d as (SELECT pt.patientunitstayid, 
       peakcreat7d, 
       peakcreat7d_offset, 
       ( pt.unitdischargeoffset - peakcreat7d_offset ) AS 
       peakcreat7d_to_discharge_offsetgap 
FROM   eicu.patient pt 
       LEFT OUTER JOIN peakcr 
                    ON peakcr.patientunitstayid = pt.patientunitstayid 
ORDER  BY pt.patientunitstayid ),

peakcr_48 AS
  (SELECT patientunitstayid,
          labresultoffset AS peakcreat48h_offset,
          labresult AS peakcreat48h,
          Row_number() OVER (PARTITION BY patientunitstayid
                             ORDER BY lab.labresult DESC) AS POSITION
   FROM eicu.lab
   WHERE labname LIKE 'creatinine%'
     AND labresultoffset >= 0
     AND labresultoffset <= (48 * 60) --Within 48hrs

   GROUP BY patientunitstayid,
            labresultoffset,
            labresult
   ORDER BY patientunitstayid,
            labresultoffset),
            
peak_48h as (
SELECT patientunitstayid
, peakcreat48h_offset
, peakcreat48h
FROM peakcr_48
WHERE POSITION = 1
),

exclude_chronic as (
SELECT
  DISTINCT treatment.patientunitstayid
FROM
  eicu.treatment
WHERE
  LOWER(treatment.treatmentstring) LIKE ANY ('{%rrt%,%dialysis%,%ultrafiltration%,%cavhd%,%cvvh%,%sled%}')
  AND 
  LOWER(treatment.treatmentstring) LIKE '%chronic%'
),

creat_final as (
select base_creat.patientunitstayid, base_creat.creat1, peak_7d.peakcreat7d, peak_48h.peakcreat48h

from base_creat left join peak_7d
on base_creat.patientunitstayid =peak_7d.patientunitstayid

left join peak_48h
on base_creat.patientunitstayid =peak_48h.patientunitstayid

where base_creat.patientunitstayid is not null and (peak_7d.patientunitstayid is not null or 
peak_48h.patientunitstayid is not null) 
),

raw as (
select creat_final.patientunitstayid, creat_final.creat1, creat_final.peakcreat7d,creat_final.peakcreat48h
, case when peakcreat7d is not null and (peakcreat7d/creat1)>1.5 then 1 else 0 end as c_7d
, case when peakcreat48h is not null and (peakcreat48h-creat1)>0.3 then 1 else 0 end as c_48h
from creat_final
),

aki_raw as (
select raw.patientunitstayid, raw.c_7d, raw.c_48h,
case when (c_7d +c_48h)>=1 then 1 else 0 end as AKI
from raw
order by patientunitstayid
)

select aki_raw.patientunitstayid, aki_raw.aki
from aki_raw
where aki_raw.patientunitstayid NOT IN (select exclude_chronic.patientunitstayid from exclude_chronic);