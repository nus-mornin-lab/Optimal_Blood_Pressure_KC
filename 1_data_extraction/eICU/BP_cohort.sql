DROP MATERIALIZED VIEW IF EXISTS BP_cohort;
CREATE MATERIALIZED VIEW BP_cohort AS

with BP_filter_raw as(
select patientunitstayid, chartoffset,ibp_systolic,ibp_diastolic,ibp_mean,
Row_number() OVER (PARTITION BY patientunitstayid
                             ORDER BY pivoted_vital.chartoffset ASC) AS POSITION
from public.pivoted_vital

order by patientunitstayid, chartoffset
),

max_min_position_BP as (
select distinct patientunitstayid,
max(position) as max_pos,
min(position) as min_pos
from BP_filter_raw
where ibp_systolic is not null or ibp_diastolic is not null or ibp_mean is not null
group by patientunitstayid
),


offset_time as (
select max_min_position_BP.patientunitstayid, max_pos, min_pos, 
case when max_pos = POSITION then chartoffset else null end as max_offset,

case when min_pos = POSITION then chartoffset else null end as min_offset

from max_min_position_BP left join BP_filter_raw
on max_min_position_BP.patientunitstayid = BP_filter_raw.patientunitstayid
),

BP_cohort_raw as (
select patientunitstayid, 
max(max_offset) as max_offset, max(min_offset) as min_offset
from offset_time
group by patientunitstayid
order by patientunitstayid
),

--criteria1: Time last reading – Time first reading > 24 hours

criteria1 as (
select patientunitstayid, min_offset 
from BP_cohort_raw
where min_offset <=1440 and (max_offset-min_offset)>=1440
),

filter24h as(
select patientunitstayid, chartoffset,ibp_systolic,ibp_diastolic,ibp_mean,
Row_number() OVER (PARTITION BY patientunitstayid
                             ORDER BY pivoted_vital.chartoffset ASC) AS POSITION_24h
from public.pivoted_vital
where chartoffset <= 1440
order by patientunitstayid, chartoffset
),

exist_12BP as (
select distinct patientunitstayid, max(POSITION_24h) as max_pos24h
from filter24h
where ibp_systolic is not null or ibp_mean is not null
group by patientunitstayid
),

-- criteria2: At least 12 readings in 24 hours
criteria2 as (
select patientunitstayid, max_pos24h
from exist_12BP
where max_pos24h >=12
),

-- criteria3 Invasive BP reading in the 1st 24h, have systolic and diastolic readings or have a mean reading
criteria3_raw as (
select patientunitstayid,
    case
        when ibp_mean is not null or (ibp_systolic is not null and ibp_diastolic is not null) 
        then 1 else 0 
        end as cc3   
from filter24h
),

criteria3 as (
    select distinct patientunitstayid,
    max(cc3) as BP_value_exist
    from criteria3_raw
    group by patientunitstayid
),

final_cohort as (
select c3.patientunitstayid
from criteria3 c3
inner join criteria2 c2 on c3.patientunitstayid = c2.patientunitstayid
inner join criteria1 c1 on c3.patientunitstayid = c1.patientunitstayid
where c3.BP_value_exist = 1
order by patientunitstayid
)


select p.patientunitstayid, p.unitadmityear, p.unitadmittime24, p.unitadmittime, 
    p.unitdischargeyear, p.unitdischargetime24, p.unitdischargetime,i.unitdischargeoffset,i.admissionweight AS weight,
    r.max_offset, r.min_offset
from final_cohort f
    inner join eicu.patient p
    on p.patientunitstayid=f.patientunitstayid
    inner join public.icustay_detail i
    on i.patientunitstayid=f.patientunitstayid
    inner join BP_cohort_raw r
    on r.patientunitstayid=f.patientunitstayid;




