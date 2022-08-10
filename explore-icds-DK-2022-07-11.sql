SELECT TOP 100 *
  FROM [CDWWork].[Dim].[ICD10]
  where sta3n = 580 and ICD10Code like 'K7%'


declare @adm_start datetime2(0) = '2021-07-10 00:00:59';

select top 10 * from Inpat.InpatientDischargeDiagnosis
where  AdmitDateTime > @adm_start
and sta3n = 580


select top 10 * from con.Consult