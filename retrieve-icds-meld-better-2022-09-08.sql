/*
Retrieve patients admitted to Houston with MELD-Na score >= 21
AND who have multiple prior visits coded w/ cirrhosis.

Andrew.Zimolzak@va.gov
2022-09-08
*/




-- Calculate MELDs upon admission

if (OBJECT_ID('tempdb.dbo.#closest_na') is not null) drop table #closest_na
if (OBJECT_ID('tempdb.dbo.#closest_cr') is not null) drop table #closest_cr
if (OBJECT_ID('tempdb.dbo.#closest_inr') is not null) drop table #closest_inr
if (OBJECT_ID('tempdb.dbo.#closest_tb') is not null) drop table #closest_tb
if (OBJECT_ID('tempdb.dbo.#meld_output') is not null) drop table #meld_output

declare @adm_start datetime2(0) = '2021-04-01 00:00:00';
declare @adm_end datetime2(0) = '2022-07-31 23:59:59';

-- In past I set these to adm_start minus 1 mo, and adm_end plus 1 mo.
declare @lab_start datetime2(0) = '2021-03-01 23:59:59';
declare @lab_end datetime2(0) = '2022-08-31 23:59:59';

-- NOTE: must run all of the following 4, otherwise those scalar vars don't persist
-- example for all 4 labs: 4:44, about 20k rows * 4, for 16 months.
-- 18 sec per month, assuming linear.

-- Sodium (retrieve only last value prior to admit, for each admit encounter in Houston)
-- example (sodium only): 20 sec, 20,311 rows, for 16 months.
SELECT distinct
inpatientsid, inp.PatientSID, AdmitDateTime, AdmitDiagnosis, 
first_value(LabChemResultNumericValue) over (partition by inp.inpatientsid  -- fixed bug. Changed to partition by inp.inpatientsid, not inp.PatientSID
	order by abs(DATEDIFF(minute, admitdatetime, LabChemSpecimenDateTime)) asc) as na
INTO #closest_na
FROM [CDWWork].[Inpat].[Inpatient] as inp
left join chem.labchem as na
on inp.patientsid = na.patientsid
  where inp.sta3n = 580
  and AdmitDateTime > @adm_start
  and AdmitDateTime < @adm_end
  and LabChemSpecimenDateTime > @lab_start and LabChemSpecimenDateTime < @lab_end
  and LabChemTestSID  = 1000062046

-- Creatinine
SELECT distinct inpatientsid,
first_value(LabChemResultNumericValue) over (partition by inp.inpatientsid 	order by abs(DATEDIFF(minute, admitdatetime, LabChemSpecimenDateTime)) asc)
as cr
INTO #closest_cr
FROM [CDWWork].[Inpat].[Inpatient] as inp left join chem.labchem as na on inp.patientsid = na.patientsid
WHERE inp.sta3n = 580  and AdmitDateTime > @adm_start  and AdmitDateTime < @adm_end  and LabChemSpecimenDateTime > @lab_start and LabChemSpecimenDateTime < @lab_end
  and LabChemTestSID  = 1000041974

-- INR
SELECT distinct inpatientsid,
first_value(LabChemResultNumericValue) over (partition by inp.inpatientsid 	order by abs(DATEDIFF(minute, admitdatetime, LabChemSpecimenDateTime)) asc)
as inr
INTO #closest_inr
FROM [CDWWork].[Inpat].[Inpatient] as inp left join chem.labchem as na on inp.patientsid = na.patientsid
WHERE inp.sta3n = 580  and AdmitDateTime > @adm_start  and AdmitDateTime < @adm_end  and LabChemSpecimenDateTime > @lab_start and LabChemSpecimenDateTime < @lab_end
  and LabChemTestSID  =   1000055581

-- Total bilirubin
SELECT distinct inpatientsid,
first_value(LabChemResultNumericValue) over (partition by inp.inpatientsid 	order by abs(DATEDIFF(minute, admitdatetime, LabChemSpecimenDateTime)) asc)
as tb
INTO #closest_tb
FROM [CDWWork].[Inpat].[Inpatient] as inp left join chem.labchem as na on inp.patientsid = na.patientsid
WHERE inp.sta3n = 580  and AdmitDateTime > @adm_start  and AdmitDateTime < @adm_end  and LabChemSpecimenDateTime > @lab_start and LabChemSpecimenDateTime < @lab_end
  and LabChemTestSID  =   1000043163

/*
Join 4 lab tables.
Perform corrections.
Calculate MELD_i.
Calculate MELD.

Basic source: https://optn.transplant.hrsa.gov/media/1575/policynotice_20151101.pdf

MELD-Na = MELD Score - Na - 0.025 x MELD x (140-Na) + 140 (don't use this formula, use the optn below)

MELD(i) = 0.957 * ln(Cr) + 0.378 * ln(bilirubin) + 1.120 * ln(INR) + 0.643
Then, round to the tenth decimal place and multiply by 10. 
If MELD(i) > 11, perform additional MELD calculation as follows:
    MELD = MELD(i) + 1.32 * (137 – Na) –  [ 0.033 * MELD(i) * (137 – Na) ]

Additional rules:
All values in US units (Cr and bilirubin in mg/dL, Na in mEq/L, and INR unitless).
If bilirubin, Cr, or INR is <1.0, use 1.0.
If any of the following is true, use Cr 4.0:
Cr >4.0.
 >= 2 dialysis treatments within the prior 7 days.
24 hours of continuous veno-venous hemodialysis (CVVHD) within the prior 7 days.
If Na <125 mmol/L, use 125. If Na >137 mmol/L, use 137.
Maximum MELD = 40.
*/

select *,
iif(meldi > 11, meldi + 1.32 * (137 - nacorr) - (0.033 * meldi * (137 - nacorr)), meldi) as meld
into #meld_output
from (
	select *,
	round((0.957 * log(crcorr) +
		0.378 * log(tbcorr) + 
		1.120 * log(inrcorr) + 0.643), 1) * 10 as meldi
	from (
		select a.*, b.cr, c.inr, d.tb,
		iif(na < 125, 125, iif(na > 137, 137, na)) as nacorr,
		iif(inr < 1.0, 1.0, inr) as inrcorr,
		iif(tb < 1.0, 1.0, tb) as tbcorr,
		iif(cr < 1.0, 1.0, iif(cr > 4.0, 4.0, cr)) as crcorr
		from #closest_na a
		inner join #closest_cr b on a.InpatientSID=b.InpatientSID
		inner join #closest_inr c on a.InpatientSID=c.InpatientSID
		inner join #closest_tb d on a.InpatientSID=d.InpatientSID
	) as addcorr
) as addmeldi

-- All of the above took 2:47. {20k 20k 19k 20k 19k rows}




-- ICD

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




-- JOIN

select top 10 * from #meld_output  -- PatientSID, n=18700
select top 10 * from #has_cirrhosis  -- inSID, outSID (patient), n=1577

if (OBJECT_ID('tempdb.dbo.#meld_plus_icd') is not null) drop table #meld_plus_icd
select s.PatientName, s.PatientSSN, c.*, m.*
into #meld_plus_icd
from #has_cirrhosis as c
left join #meld_output as m
on c.inSID = m.PatientSID
left join SPatient.SPatient as s
on m.PatientSID = s.PatientSID
--1997 rows?

select
PatientName, PatientSSN, AdmitDateTime, meld, AdmitDiagnosis, total_visits, na, cr, inr, tb
from #meld_plus_icd
where meld >= 21
order by AdmitDateTime

/*
Standard export procedure:

select all
copy with headers
paste into Notepad
save as txt
import into Excel as TSV
*/
