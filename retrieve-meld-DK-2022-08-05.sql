/*
Retrieve patients admitted to Houston with MELD-Na score >= 21.

Andrew.Zimolzak@va.gov
2022-08-05 and later
*/

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

-- Freddie. N = 7047 admits currently. 18 sec.
-- Disha. N = 18670 / 16 mo (< 1 sec !)

select m.*, s.PatientName, s.PatientSSN from #meld_output as m
left join SPatient.SPatient as s
on m.PatientSID = s.PatientSID
where meld >= 21 order by meld desc

-- Freddie. N = 821. 8 sec.
-- Disha. N = 2,086. 20 sec.

--For export, seems best to do this:
-- select all
-- copy with headers
-- paste into Notepad
-- save as txt
-- into Excel as TSV
