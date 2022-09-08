declare @dx_before datetime2(0) = '2021-04-01 00:00:00';
declare @icd10_start datetime2(0) = '2015-10-01 00:00:00';

-- ICD Inpatient

if (OBJECT_ID('tempdb.dbo.#inpatient_cirrhosis') is not null) drop table #inpatient_cirrhosis
select count(patientsid) as inpatient_cirrhosis_visits,
	[PatientSID]
INTO #inpatient_cirrhosis
from Inpat.InpatientDischargeDiagnosis
where AdmitDateTime < @dx_before
and AdmitDateTime > @icd10_start
and ICD10SID in (
  1001548148,
  1001548149,
  1001548162,
  1001548179,
  1001548180,
  1001548181,
  1001548182,
  1001548183
)
group by PatientSID




-- ICD outpatient

if (OBJECT_ID('tempdb.dbo.#outpatient_cirrhosis') is not null) drop table #outpatient_cirrhosis
select 
count(patientsid) as outpatient_cirrhosis_visits,
	[PatientSID]
INTO #outpatient_cirrhosis
from Outpat.VDiagnosis
where VisitDateTime < @dx_before
and VisitDateTime > @icd10_start
and ICD10SID in (
  1001548148,
  1001548149,
  1001548162,
  1001548179,
  1001548180,
  1001548181,
  1001548182,
  1001548183
)
group by PatientSID




-- ICD join inpat + outpat

if (OBJECT_ID('tempdb.dbo.#has_cirrhosis') is not null) drop table #has_cirrhosis
select * 
into #has_cirrhosis
from (
	select 
		i.PatientSID as inSID, 
		o.PatientSID as outSID, 
		i.inpatient_cirrhosis_visits, 
		o.outpatient_cirrhosis_visits,
		(inpatient_cirrhosis_visits + outpatient_cirrhosis_visits) as total_visits
	from #inpatient_cirrhosis as i
	FULL JOIN #outpatient_cirrhosis as o
	on i.PatientSID = o.PatientSID
) as x
where x.total_visits > 1

-- all 3 of these steps take 20 sec. 1976 rows, 4066 rows, 1577 rows

