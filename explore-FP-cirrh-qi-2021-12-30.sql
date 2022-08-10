--------------- admissions -------------

SELECT TOP 10 
InpatientSID,
PatientSID, 
AdmitDateTime,
AdmitDiagnosis,
DischargeDateTime,
PrincipalDiagnosisICD10SID,
DischargeDRGSID,
inp.sta3n,
icd.ICD10Code
  FROM [CDWWork].[Inpat].[Inpatient] as inp
left join dim.ICD10 as icd
on inp.PrincipalDiagnosisICD10SID = icd.ICD10SID
  where inp.sta3n = 580
  and AdmitDateTime > '2021-05-01'

SELECT TOP 10 
InpatientSID,PatientSID, AdmitDateTime,AdmitDiagnosis,DischargeDateTime,PrincipalDiagnosisICD10SID
  FROM [CDWWork].[Inpat].[Inpatient] as inp
  where inp.sta3n = 580
  and AdmitDateTime > '2021-05-01'
  and AdmitDiagnosis like '%cirrh%'

SELECT 
count(*)
--TOP 10 
--InpatientSID,PatientSID, AdmitDateTime,AdmitDiagnosis,DischargeDateTime,PrincipalDiagnosisICD10SID
  FROM [CDWWork].[Inpat].[Inpatient] as inp
  where inp.sta3n = 580
  and AdmitDateTime > '2021-04-01'
  and AdmitDateTime < '2021-10-01'





-------------- LABS ------------

select * from dim.LabChemTest where sta3n = 580 and (LabChemTestName like 'sodi%' and LabChemTestName not like '%ur%' and LabChemTestName not like '%24%'
	 and LabChemTestName not like '%stoo%')
-- 1000062046 1000037338
-- sodium     sodium(bmt)

select * from dim.LabChemTest where sta3n = 580 and (LabChemTestName like 'cre%' and LabChemTestName not like '%ur%') order by LabChemTestName
-- LabChemTestSID	LabChemTestIEN	Sta3n	LabChemTestName
-- 1000041974	5194	580	CREATININE
-- 1000059886	1452	580	CREATININE(*SERUM*)
-- 1000032871	6702	580	CREATININE/EGFR
-- 1000023804	6704	580	CREATININE+EGFR(*SERUM*)

select TOP 10 * from dim.LabChemTest where sta3n = 580 and (LabChemTestName like 'INR%' and LabChemTestName not like '%(%') order by LabChemTestName
--1000055581	5343	580	INR
--1000034183	1793	580	INR-C

select TOP 500 * from dim.LabChemTest where sta3n = 580 and (LabChemTestName like '%bili%') order by LabChemTestName
-- 1000070045	6921	580	Bilirubin,Total-LC
-- 1000043163	5198	580	TOT. BILIRUBIN





-- THE WHOLE SET OF LABS
select top 100 
PatientSID, labchemtestsid, LabChemSpecimenDateTime, LabChemResultNumericValue, units, abnormal, refhigh, reflow
 from chem.LabChem where sta3n = 580 and LabChemSpecimenDateTime > '2021-05-01'
	and LabChemTestSID in (1000062046, 1000041974,1000059886, 1000032871, 1000023804, 1000055581, 1000034183, 1000070045, 1000043163)
	--                      sodium         creat     cre ser    cre egfr   cre egfr s    inr          inrc     bili-lc       totbili

select count(*)  --297755
 from chem.LabChem where sta3n = 580 and LabChemSpecimenDateTime > '2021-05-01'
	and LabChemTestSID in (1000062046, 1000041974,1000059886, 1000032871, 1000023804, 1000055581, 1000034183, 1000070045, 1000043163)




-- SODIUM. 102646 sodiums since May 1 2021.

-- CREAT total 102909
select 
top 100 PatientSID, labchemtestsid, LabChemSpecimenDateTime, LabChemResultNumericValue, units, abnormal, refhigh, reflow
 from chem.LabChem where sta3n = 580 and LabChemSpecimenDateTime > '2021-05-01'
	and LabChemTestSID in (1000041974, 1000059886, 1000032871, 1000023804) -- first sid "1974" is very common. "886" and others only 30 rows

-- INR total 21829
select top 100 PatientSID, labchemtestsid, LabChemSpecimenDateTime, LabChemResultNumericValue, units, abnormal, refhigh, reflow
 from chem.LabChem where sta3n = 580 and LabChemSpecimenDateTime > '2021-05-01'
	and LabChemTestSID in (1000055581, 1000034183) --zero hits for 2nd sid

-- BILI
select count(*) from chem.LabChem where sta3n = 580 and LabChemSpecimenDateTime > '2021-05-01' 	and LabChemTestSID = 1000070045 --105
select count(*) from chem.LabChem where sta3n = 580 and LabChemSpecimenDateTime > '2021-05-01' 	and LabChemTestSID = 1000043163 --70266




--most refined labs
select top 100 
PatientSID, labchemtestsid, LabChemSpecimenDateTime, LabChemResultNumericValue, units, abnormal, refhigh, reflow
 from chem.LabChem where sta3n = 580 and LabChemSpecimenDateTime > '2021-05-02' and LabChemSpecimenDateTime < '2021-05-08'
	and LabChemTestSID in (1000062046, 1000041974,  1000055581,  1000043163)
	--                      sodium         creat         inr    totbili

-- inr is most rare but still like 500 per day.
select top 100 
PatientSID, labchemtestsid, LabChemSpecimenDateTime, LabChemResultNumericValue, units, abnormal, refhigh, reflow
 from chem.LabChem where sta3n = 580 and LabChemSpecimenDateTime > '2021-05-03' and LabChemSpecimenDateTime < '2021-05-07'
	and LabChemTestSID in (1000055581)






-------- Explore some pts with cirrhosis AdmitDiagnosis -------
-- real IDs removed.

select top 100 
PatientSID, dim.LabChemTestName, lab.labchemtestsid, LabChemSpecimenDateTime, LabChemResultNumericValue, units, abnormal, refhigh, reflow
 from chem.LabChem as lab
 left join dim.LabChemTest as dim
 on lab.LabChemTestSID = dim.LabChemTestSID
 where
    lab.sta3n = 580 and LabChemSpecimenDateTime > '2021-05-01' and LabChemSpecimenDateTime < '2021-06-30'
	and
	lab.LabChemTestSID in (1000062046, 1000041974,  1000055581,  1000043163)
	--------------------na           cr            inr         bili
	and
	PatientSID = 123123123123123123123 
order by LabChemSpecimenDateTime

-- MELD-Na = MELD Score - Na - 0.025 x MELD x (140-Na) + 140


-- MELD(i) = 0.957 * ln(Cr) + 0.378 * ln(bilirubin) + 1.120 * ln(INR) + 0.643
--Then, round to the tenth decimal place and multiply by 10. 
--If MELD(i) > 11, perform additional MELD calculation as follows:
--MELD = MELD(i) + 1.32 * (137 - Na) -  [ 0.033 * MELD(i) * (137 – Na) ]
--Additional rules:
--All values in US units (Cr and bilirubin in mg/dL, Na in mEq/L, and INR unitless).
--If bilirubin, Cr, or INR is <1.0, use 1.0.
--If any of the following is true, use Cr 4.0:
--Cr >4.0.
-- >= 2 dialysis treatments within the prior 7 days.
--24 hours of continuous veno-venous hemodialysis (CVVHD) within the prior 7 days.
--If Na <125 mmol/L, use 125. If Na >137 mmol/L, use 137.
--Maximum MELD = 40.



/******* 2021-12-30, try to join admits and labs *************/

SELECT
InpatientSID, PatientSID, AdmitDateTime, AdmitDiagnosis, DischargeDateTime, DischargeFromService, LOSCumulative,
PrincipalDiagnosisICD10SID, AdmitWardLocationSID, dischargeFromSpecialtySID,  dischargeDRGSID, DischargeSpecialtySID
  FROM [CDWWork].[Inpat].[Inpatient] as inp
  where inp.sta3n = 580
  and AdmitDateTime > '2021-05-01'
  and AdmitDateTime < '2021-05-02'

SELECT
InpatientSID, inp.PatientSID, AdmitDateTime, AdmitDiagnosis, LabChemTestSID, LabChemSpecimenDateTime, LabChemResultNumericValue, refhigh, reflow
  FROM [CDWWork].[Inpat].[Inpatient] as inp
left join chem.labchem as lab
on inp.patientsid = lab.patientsid
  where inp.sta3n = 580
  and AdmitDateTime > '2021-05-01'
  and AdmitDateTime < '2021-05-02'
  and LabChemSpecimenDateTime > '2021-04-29' and LabChemSpecimenDateTime < '2021-05-08'
  and LabChemTestSID in (1000062046, 1000041974,  1000055581,  1000043163)
order by PatientSID, LabChemTestSID, LabChemSpecimenDateTime

---aggregate Na only

SELECT
inpatientsid, inp.PatientSID, AdmitDateTime, AdmitDiagnosis, avg(LabChemResultNumericValue) as na
  FROM [CDWWork].[Inpat].[Inpatient] as inp
left join chem.labchem as na
on inp.patientsid = na.patientsid
  where inp.sta3n = 580
  and AdmitDateTime > '2021-05-01'
  and AdmitDateTime < '2021-05-02'
  and LabChemSpecimenDateTime > '2021-04-29' and LabChemSpecimenDateTime < '2021-05-08'
  and LabChemTestSID  = 1000062046
group by inp.PatientSID, AdmitDateTime, AdmitDiagnosis, InpatientSID

-- better aggr, no group by
SELECT distinct
inpatientsid, inp.PatientSID, AdmitDateTime, AdmitDiagnosis, --labchemspecimendatetime,
first_value(LabChemResultNumericValue) over (partition by inp.patientsid order by LabChemSpecimenDateTime) as na
  FROM [CDWWork].[Inpat].[Inpatient] as inp
left join chem.labchem as na
on inp.patientsid = na.patientsid
  where inp.sta3n = 580
  and AdmitDateTime > '2021-05-01'
  and AdmitDateTime < '2021-05-02'
  and LabChemSpecimenDateTime > '2021-04-29' and LabChemSpecimenDateTime < '2021-05-08'
  and LabChemTestSID  = 1000062046
--group by inp.PatientSID, AdmitDateTime, AdmitDiagnosis, InpatientSID








--TEMP TABLES !!!   START HERE 2021-12-30.

if (OBJECT_ID('tempdb.dbo.#closest_na') is not null) drop table #closest_na
if (OBJECT_ID('tempdb.dbo.#closest_cr') is not null) drop table #closest_cr
if (OBJECT_ID('tempdb.dbo.#closest_inr') is not null) drop table #closest_inr
if (OBJECT_ID('tempdb.dbo.#closest_tb') is not null) drop table #closest_tb
if (OBJECT_ID('tempdb.dbo.#meld_output') is not null) drop table #meld_output

declare @adm_start datetime2(0) = '2021-05-01 00:00:00';
declare @adm_end datetime2(0) = '2021-10-30 23:59:59'; -- freddie really wants may to oct.
declare @lab_start datetime2(0) = '2021-04-01 23:59:59';
declare @lab_end datetime2(0) = '2021-11-30 23:59:59';

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

SELECT distinct inpatientsid,
first_value(LabChemResultNumericValue) over (partition by inp.inpatientsid 	order by abs(DATEDIFF(minute, admitdatetime, LabChemSpecimenDateTime)) asc)
as cr
INTO #closest_cr
FROM [CDWWork].[Inpat].[Inpatient] as inp left join chem.labchem as na on inp.patientsid = na.patientsid
WHERE inp.sta3n = 580  and AdmitDateTime > @adm_start  and AdmitDateTime < @adm_end  and LabChemSpecimenDateTime > @lab_start and LabChemSpecimenDateTime < @lab_end
  and LabChemTestSID  = 1000041974

SELECT distinct inpatientsid,
first_value(LabChemResultNumericValue) over (partition by inp.inpatientsid 	order by abs(DATEDIFF(minute, admitdatetime, LabChemSpecimenDateTime)) asc)
as inr
INTO #closest_inr
FROM [CDWWork].[Inpat].[Inpatient] as inp left join chem.labchem as na on inp.patientsid = na.patientsid
WHERE inp.sta3n = 580  and AdmitDateTime > @adm_start  and AdmitDateTime < @adm_end  and LabChemSpecimenDateTime > @lab_start and LabChemSpecimenDateTime < @lab_end
  and LabChemTestSID  =   1000055581

SELECT distinct inpatientsid,
first_value(LabChemResultNumericValue) over (partition by inp.inpatientsid 	order by abs(DATEDIFF(minute, admitdatetime, LabChemSpecimenDateTime)) asc)
as tb
INTO #closest_tb
FROM [CDWWork].[Inpat].[Inpatient] as inp left join chem.labchem as na on inp.patientsid = na.patientsid
WHERE inp.sta3n = 580  and AdmitDateTime > @adm_start  and AdmitDateTime < @adm_end  and LabChemSpecimenDateTime > @lab_start and LabChemSpecimenDateTime < @lab_end
  and LabChemTestSID  =   1000043163

--- hooray, demonstrate performing a function on these 4 cols.
-- basic source: https://optn.transplant.hrsa.gov/media/1575/policynotice_20151101.pdf

-- MELD-Na = MELD Score - Na - 0.025 x MELD x (140-Na) + 140 (don't use this formula, use the optn below)

-- MELD(i) = 0.957 * ln(Cr) + 0.378 * ln(bilirubin) + 1.120 * ln(INR) + 0.643
--Then, round to the tenth decimal place and multiply by 10. 
--If MELD(i) > 11, perform additional MELD calculation as follows:
--MELD = MELD(i) + 1.32 * (137 - Na) -  [ 0.033 * MELD(i) * (137 - Na) ]
--Additional rules:
--All values in US units (Cr and bilirubin in mg/dL, Na in mEq/L, and INR unitless).
--If bilirubin, Cr, or INR is <1.0, use 1.0.
--If any of the following is true, use Cr 4.0:
--Cr >4.0.
-- >= 2 dialysis treatments within the prior 7 days.
--24 hours of continuous veno-venous hemodialysis (CVVHD) within the prior 7 days.
--If Na <125 mmol/L, use 125. If Na >137 mmol/L, use 137.
--Maximum MELD = 40.

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

-- N = 7047 admits currently. 18 sec.

select m.*, s.PatientName, s.PatientSSN from #meld_output as m
left join SPatient.SPatient as s
on m.PatientSID = s.PatientSID
where meld >= 21 order by meld desc -- N = 821. 8 sec.

