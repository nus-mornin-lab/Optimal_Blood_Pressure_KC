with cohort as (
select distinct (patientunitstayid) from `team02bloodpressure.datathon.selectedstay_new`
),

vasso_duration as (
select patientunitstayid,
(max(infusionoffset)-min(infusionoffset))/60 as duration_hour
from `team02bloodpressure.datathon.Vasopressor`
group by patientunitstayid
),

final as (


select cohort.patientunitstayid, demo.gender, demo.age, demo.bmi , demo.ethnicity,
hist.COPD, hist.angina ,hist.atrial_fibrillation ,hist.cancer ,hist.chf ,hist.coronary ,hist.diabetes ,hist.hypertension ,hist.myocardial_infarction ,hist.renal_failure , stay.apache_iv ,stay.unittype, fluid.nettotal,vasso.vaso_binary , hours.hour ,ar_bp.medianHR,  ar_bp.f0_ as ar_bp_sys
,ar_bp.f1_ as  ar_bp_di, ar_bp.f2_ as ar_bp_mean, ni_bp.f0_ as ni_bp_sys, ni_bp.f1_ as ni_bp_di, ni_bp.f2_ as ni_bp_mean ,apache.actualiculos, apache.actualicumortality ,apache.actualhospitalmortality ,apache.actualhospitallos, aki_data.AKI, apa_grp.apachedxgroup,
case when apachedxgroup = "Sepsis" then 1 else 0 end as sepsis_binary

from cohort left join
`team02bloodpressure.datathon.gender_age_ethnicity_bmi` as demo
on cohort.patientunitstayid = demo.patientunitstayid
left join
`team02bloodpressure.datathon.pasthistory` as hist
on cohort.patientunitstayid = hist.patientunitstayid
left join
`team02bloodpressure.datathon.icustay` as stay
on cohort.patientunitstayid =stay.patientunitstayid
left join
`team02bloodpressure.datathon.fluid_nettotal`  as fluid
on cohort.patientunitstayid =fluid.patientunitstayid
left join
`team02bloodpressure.datathon.Vasopressor` as vasso
on cohort.patientunitstayid =vasso.patientunitstayid

left join
`team02bloodpressure.datathon.vasso_hour` as hours
on cohort.patientunitstayid =hours.patientunitstayid


left join `team02bloodpressure.datathon.AR_bphr_median_72h`   as ar_bp
on cohort.patientunitstayid =ar_bp.qid

left join `team02bloodpressure.datathon.NI_bp_median`  as ni_bp
on cohort.patientunitstayid =ni_bp.pid

left join `physionet-data.eicu_crd.apachepatientresult` as apache
on cohort.patientunitstayid =apache.patientunitstayid

left join `team02bloodpressure.datathon.AKI` as aki_data
on cohort.patientunitstayid =aki_data.patientunitstayid

left join  `team02bloodpressure.datathon.apache_group` as apa_grp
on cohort.patientunitstayid =apa_grp.patientunitstayid 
),

final_1 as (
SELECT
      *,
      ROW_NUMBER()
          OVER (PARTITION BY patientunitstayid)
          row_number
  FROM final
),


final_2 as (
SELECT *
FROM final_1
WHERE row_number = 1
),

 ff as (
select * from final_2
where age != '> 89'
and age is not null
)

select * from ff
where cast(age as INT64)>17 and cast(age as INT64)<89

