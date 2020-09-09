with creat as (

select base.patientunitstayid, base.creat1, peak.peakcreat7d, peak_48.peakcreat48h 
from `team02bloodpressure.datathon.creat_baseline` as base left join
`team02bloodpressure.datathon.creat7d_peak` as peak
on base.patientunitstayid = peak.patientunitstayid 
left join `team02bloodpressure.datathon.creat48h_peak` as peak_48 
on base.patientunitstayid =peak_48.patientunitstayid 
where base.patientunitstayid is not null
and (peak.patientunitstayid is not null
or peak_48.patientunitstayid is not null
)
),
temp as (
select patientunitstayid,
case when peakcreat7d is not null and (peakcreat7d/creat1)>1.5 then 1 else 0 end as c_7d,
case when peakcreat48h is not null and (peakcreat48h-creat1)>0.3 then 1 else 0 end as c_48h
from creat),

raw as (
select patientunitstayid , 
case when (c_7d +c_48h)>=1 then 1 else 0 end as AKI
from temp
order by patientunitstayid 
)
select * from 
raw where
patientunitstayid NOT IN (select patientunitstayid from `team02bloodpressure.datathon.aki_exclude`)
