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
)

select * from BP_cohort_raw
where min_offset <=24*60 and (max_offset-min_offset)>=24*60;
