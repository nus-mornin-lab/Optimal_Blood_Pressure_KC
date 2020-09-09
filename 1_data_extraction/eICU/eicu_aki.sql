CREATE MATERIALIZED VIEW AKI as (
with temp_base as 
(SELECT patientunitstayid,labname,labresultoffset,labresult,
           ROW_NUMBER() OVER (PARTITION BY patientunitstayid, labname ORDER BY labresultoffset ASC) AS POSITION_base
           FROM eicu.lab
           WHERE ((labname) = 'creatinine')
           AND labresultoffset BETWEEN -720 AND 720 -- first creat available value between -12 and +12h from admission\
           ORDER BY patientunitstayid, labresultoffset
           ),

base_creat as (
SELECT patientunitstayid,
max(CASE WHEN (labname) = 'creatinine' AND POSITION_base =1 THEN labresult ELSE NULL END) AS creat1,
max(CASE WHEN (labname) = 'creatinine' AND POSITION_base =1 THEN labresultoffset ELSE NULL END) AS creat1offset
FROM temp_base
GROUP BY patientunitstayid
ORDER BY patientunitstayid
),

temp_7d as (
select patientunitstayid, labresultoffset AS peakcreat7d_offset, labresult AS peakcreat7d,
Row_number() OVER (partition BY patientunitstayid ORDER BY lab.labresult DESC) AS position_7d
FROM eicu.lab WHERE labname LIKE 'creatinine%' AND labresultoffset >= 0 AND labresultoffset <= 10080 
GROUP BY patientunitstayid, labresultoffset, labresult 
ORDER BY patientunitstayid, labresultoffset
),

c_7d as (
SELECT pt.patientunitstayid, peakcreat7d, peakcreat7d_offset, (pt.unitdischargeoffset - peakcreat7d_offset) AS peakcreat7d_to_discharge_offsetgap 
FROM   eicu.patient pt LEFT OUTER JOIN temp_7d 
ON temp_7d.patientunitstayid = pt.patientunitstayid
where temp_7d.position_7d = 1
ORDER BY pt.patientunitstayid

),

temp_48h AS(
SELECT patientunitstayid,labresultoffset AS peakcreat48h_offset,labresult AS peakcreat48h,
Row_number() OVER (PARTITION BY patientunitstayid ORDER BY lab.labresult DESC) AS POSITION_48h
FROM eicu.lab
WHERE labname LIKE 'creatinine%' AND labresultoffset >= 0 AND labresultoffset <= (48 * 60) --Within 48hrs
GROUP BY patientunitstayid,labresultoffset,labresult
ORDER BY patientunitstayid,labresultoffset,labresult
),

c_48h as (
SELECT patientunitstayid, peakcreat48h_offset, peakcreat48h
FROM temp_48h
WHERE temp_48h.POSITION_48h = 1
),

exclude_chronic as (
SELECT DISTINCT treatment.patientunitstayid
FROM eicu.treatment
WHERE
  LOWER(treatment.treatmentstring) LIKE ANY ('{%rrt%,%dialysis%,%ultrafiltration%,%cavhd%,%cvvh%,%sled%}')
  AND 
  LOWER(treatment.treatmentstring) LIKE '%chronic%'
)

,
creat_temp as (

select base_creat.patientunitstayid, base_creat.creat1, c_7d.peakcreat7d, c_48h.peakcreat48h
from base_creat left join c_7d
on base_creat.patientunitstayid = c_7d.patientunitstayid
left join c_48h
on base_creat.patientunitstayid = c_48h.patientunitstayid
where base_creat.patientunitstayid is not null and (c_7d.patientunitstayid is not null or c_48h.patientunitstayid is not null)
),

creat_temp1 as (
select patientunitstayid,
case when peakcreat7d is not null and (peakcreat7d/creat1)>1.5 then 1 else 0 end as c_7d,
case when peakcreat48h is not null and (peakcreat48h-creat1)>0.3 then 1 else 0 end as c_48h
from creat_temp),

raw_aki as (
select patientunitstayid, 
case when (creat_temp1.c_7d +creat_temp1.c_48h)>=1 then 1 else 0 end as AKI
from creat_temp1
)

select * from raw_aki where raw_aki.patientunitstayid NOT IN (select patientunitstayid from exclude_chronic)
order by raw_aki.patientunitstayid
)