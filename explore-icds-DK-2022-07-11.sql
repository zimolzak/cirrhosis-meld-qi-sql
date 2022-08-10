SELECT *
  FROM [CDWWork].[Dim].[ICD10]
  where sta3n = 580 and ICD10Code like 'K7%'
  -- N = 63

/*
K70  Alcoholic liver disease
K71  Toxic liver disease
K72  Hepatic failure, not elsewhere classified
K73  Chronic hepatitis, not elsewhere classified
K74  Fibrosis and cirrhosis of liver
K75  Other inflammatory liver diseases
K76  Other diseases of liver
K77  Liver disorders in diseases classified elsewhere

This makes it look like cirrhosis limited to K74 but it's in K70 too. But then that has etoh hepatitits & fatty liver & ....

So do include:
k70
K71 has one.
k74 should get limited to filter out fibrosis k74.0 and sclerosis and combo k74.1 k74.2

IGNORE: K72 has NONE. also ignore k73. k75 none. k76. k77.

decent final list (of 8):

K70.30 etoh cirrh without ascites
K70.31 " " with ascites
K71.7 (prob rare, drug induced) Toxic liver disease with fibrosis and cirrhosis of liver
K74.3 pbc
K74.4 sec bili cirrh
K74.5 unspec bili cirrh
K74.60 unspec cirrh
K74.69 other cirrh
*/

SELECT * FROM [CDWWork].[Dim].[ICD10] where sta3n = 580 and (
  ICD10Code = 'K70.30' or
  ICD10Code = 'K70.31' or
  ICD10Code = 'K71.7' or
  ICD10Code = 'K74.3' or
  ICD10Code = 'K74.4' or
  ICD10Code = 'K74.5' or
  ICD10Code = 'K74.60' or
  ICD10Code = 'K74.69'
  )

/*
ICD10SID:

1001548148
1001548149
1001548162
1001548179
1001548180
1001548181
1001548182
1001548183
*/

select top 15 * from dim.ICD10DescriptionVersion
select top 15 * from dim.ICD10DiagnosisVersion

select * from dim.ICD10DescriptionVersion
where ICD10SID in (
  1001548148,
  1001548149,
  1001548162,
  1001548179,
  1001548180,
  1001548181,
  1001548182,
  1001548183
)
order by ICD10SID -- looking good. Confirmed that they all have the cirrhosis description text.

select * from dim.ICD10DescriptionVersion
where sta3n = 580 and ICD10Description like '%cirrh%'
order by ICD10SID
-- The string search approach found a technically novel one, SID = 1001149302, which is Congenital cirrhosis (of liver)
-- probably P78.81

select * from dim.ICD10 where ICD10SID = 1001149302
-- highly weird, that doesn't seem to retrieve the right ICD10.
-- I think I will ignore: doubt congenital is common at all.





/********* Start looking at visits *********/

-- adm_start in the other sql file is CURRENTLY = 2021-04-01 00:00:00
-- ICD10 looks like took effect 2015-10-01

if (OBJECT_ID('tempdb.dbo.#inpatient_cirrhosis') is not null) drop table #inpatient_cirrhosis
declare @dx_before datetime2(0) = '2021-04-01 00:00:00';
declare @icd10_start datetime2(0) = '2015-10-01 00:00:00';
select count(patientsid) as inpatient_cirrhosis_visits,
	--[InpatientDischargeDiagnosisSID],
	--[InpatientSID],
	[PatientSID]
	--,
	--[ICD10SID]
INTO #inpatient_cirrhosis
from Inpat.InpatientDischargeDiagnosis
where AdmitDateTime < @dx_before
and AdmitDateTime > @icd10_start
-- and sta3n = 580  -- Those ICD10SID should ONLY happen in 580.
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
-- very fast, 1 sec, 168 rows, for April 2022 - present. AKA 4 mo or 131 days.
-- 7 sec, 1976 rows, for 2015 to 2021. To be exact, 5.5 years, or 2009 days.

select top 10 * from #inpatient_cirrhosis

-- select top 10 * from con.Consult

go;






/******* Outpatient diagnoses now ********/

select * from INFORMATION_SCHEMA.COLUMNS
where TABLE_SCHEMA = 'Outpat' and
COLUMN_NAME like 'ICD10S%'
-- this seems to confirm that VDiagnosis is the way to go.

select * from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'VDiagnosis' and
COLUMN_NAME like '%Date%'
-- probably VDiagnosisDateTime
-- but also VisitDateTime
-- Although I don't know what EventDateTime is for sure??

select top 10 VisitDateTime, VDiagnosisDateTime from Outpat.VDiagnosis
where sta3n = 580
and VisitDateTime < '2020-04-01 00:00:00'
and VisitDateTime > '2020-01-01 00:00:00'
-- seems like VDiagnosisDateTime very likely equal to VisitDateTime
-- tried this several times.
-- Decision: will go with VisitDateTime




if (OBJECT_ID('tempdb.dbo.#outpatient_cirrhosis') is not null) drop table #outpatient_cirrhosis
declare @dx_before datetime2(0) = '2021-04-01 00:00:00';
declare @icd10_start datetime2(0) = '2015-10-01 00:00:00';
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
-- 13 sec, 4067 rows, over the same 5.5 years, 2009 days.
