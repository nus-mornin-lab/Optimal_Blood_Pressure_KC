DROP TABLE IF EXISTS ventilation CASCADE;
CREATE TABLE ventilation as
WITH t1 AS
  (SELECT DISTINCT patientunitstayid, respcarestatusoffset,
                   max(CASE
                           WHEN airwaytype IN ('Oral ETT', 'Nasal ETT', 'Tracheostomy') THEN 1
                           ELSE NULL
                       END) AS airway -- either invasive airway or NULL
   FROM public.respiratorycare
   WHERE respcarestatusoffset BETWEEN -1440 AND 1440
   GROUP BY patientunitstayid, respcarestatusoffset),
     t2 AS
  (SELECT DISTINCT patientunitstayid, respchartoffset, 
                   1 AS ventilator
   FROM public.respiratorycharting rc
   WHERE 
     (respchartvalue ILIKE '%ventilator%'
     OR respchartvalue ILIKE'%vent%'
     OR respchartvalue ILIKE '%bipap%'
     OR respchartvalue ILIKE '%840%'
     OR respchartvalue ILIKE '%cpap%'
     OR respchartvalue ILIKE '%drager%'
     OR respchartvalue ILIKE 'mv%'
     OR respchartvalue ILIKE '%servo%'
     OR respchartvalue ILIKE '%peep%')
     AND respchartoffset BETWEEN 0 AND 1440
   GROUP BY patientunitstayid, respchartoffset
   ORDER BY patientunitstayid ASC),
     t3 AS
  (SELECT DISTINCT patientunitstayid, treatmentoffset,
                   max(CASE
                           WHEN treatmentstring IN ('pulmonary|ventilation and oxygenation|mechanical ventilation', 'pulmonary|ventilation and oxygenation|tracheal suctioning', 'pulmonary|ventilation and oxygenation|ventilator weaning', 'pulmonary|ventilation and oxygenation|mechanical ventilation|assist controlled', 'pulmonary|radiologic procedures / bronchoscopy|endotracheal tube', 'pulmonary|ventilation and oxygenation|oxygen therapy (> 60%)', 'pulmonary|ventilation and oxygenation|mechanical ventilation|tidal volume 6-10 ml/kg', 'pulmonary|ventilation and oxygenation|mechanical ventilation|volume controlled', 'surgery|pulmonary therapies|mechanical ventilation', 'pulmonary|surgery / incision and drainage of thorax|tracheostomy', 'pulmonary|ventilation and oxygenation|mechanical ventilation|synchronized intermittent', 'pulmonary|surgery / incision and drainage of thorax|tracheostomy|performed during current admission for ventilatory support', 'pulmonary|ventilation and oxygenation|ventilator weaning|active', 'pulmonary|ventilation and oxygenation|mechanical ventilation|pressure controlled', 'pulmonary|ventilation and oxygenation|mechanical ventilation|pressure support', 'pulmonary|ventilation and oxygenation|ventilator weaning|slow', 'surgery|pulmonary therapies|ventilator weaning', 'surgery|pulmonary therapies|tracheal suctioning', 'pulmonary|radiologic procedures / bronchoscopy|reintubation', 'pulmonary|ventilation and oxygenation|lung recruitment maneuver', 'pulmonary|surgery / incision and drainage of thorax|tracheostomy|planned', 'surgery|pulmonary therapies|ventilator weaning|rapid', 'pulmonary|ventilation and oxygenation|prone position', 'pulmonary|surgery / incision and drainage of thorax|tracheostomy|conventional', 'pulmonary|ventilation and oxygenation|mechanical ventilation|permissive hypercapnea', 'surgery|pulmonary therapies|mechanical ventilation|synchronized intermittent', 'pulmonary|medications|neuromuscular blocking agent', 'surgery|pulmonary therapies|mechanical ventilation|assist controlled', 'pulmonary|ventilation and oxygenation|mechanical ventilation|volume assured', 'surgery|pulmonary therapies|mechanical ventilation|tidal volume 6-10 ml/kg', 'surgery|pulmonary therapies|mechanical ventilation|pressure support', 'pulmonary|ventilation and oxygenation|non-invasive ventilation', 'pulmonary|ventilation and oxygenation|non-invasive ventilation|face mask', 'pulmonary|ventilation and oxygenation|non-invasive ventilation|nasal mask', 'pulmonary|ventilation and oxygenation|mechanical ventilation|non-invasive ventilation', 'pulmonary|ventilation and oxygenation|mechanical ventilation|non-invasive ventilation|face mask', 'surgery|pulmonary therapies|non-invasive ventilation', 'surgery|pulmonary therapies|non-invasive ventilation|face mask', 'pulmonary|ventilation and oxygenation|mechanical ventilation|non-invasive ventilation|nasal mask', 'surgery|pulmonary therapies|non-invasive ventilation|nasal mask', 'surgery|pulmonary therapies|mechanical ventilation|non-invasive ventilation', 'surgery|pulmonary therapies|mechanical ventilation|non-invasive ventilation|face mask') THEN 1
                           ELSE NULL
                       END) AS interface -- either ETT/NiV or NULL
FROM treatment
   WHERE treatmentoffset BETWEEN 0 AND 1440
   GROUP BY patientunitstayid, treatmentoffset
   ORDER BY patientunitstayid)
SELECT pt.patientunitstayid, t1.respcarestatusoffset, t2.respchartoffset, t3.treatmentoffset
       ,1 AS mechvent
FROM patient pt
LEFT OUTER JOIN t1 ON t1.patientunitstayid=pt.patientunitstayid
LEFT OUTER JOIN t2 ON t2.patientunitstayid=pt.patientunitstayid
LEFT OUTER JOIN t3 ON t3.patientunitstayid=pt.patientunitstayid
WHERE t1.airway IS NOT NULL
  OR t2.ventilator IS NOT NULL
  OR t3.interface IS NOT NULL
ORDER BY pt.patientunitstayid