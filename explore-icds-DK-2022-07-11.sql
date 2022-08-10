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

declare @adm_start datetime2(0) = '2021-07-10 00:00:59';

select top 10 * from Inpat.InpatientDischargeDiagnosis
where  AdmitDateTime > @adm_start
and sta3n = 580


select top 10 * from con.Consult