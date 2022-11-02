/*CREATE TABLE table11 (
       [Timestamp_v] VARCHAR(max),
	   [Timestamp_w] VARCHAR(max),
	   ResultName_v VARCHAR(max),
	   ResultName_w VARCHAR(max),
	   [Value] VARCHAR(max),
	   [Wavelength] VARCHAR(max)
)
;
*/

DECLARE @RowNo_w int =1;
DECLARE @RowNo_v int =1;
WITH cte_split_w(ROWNO_w, [Timestamp_w], ResultName_w, split_wavelengths, [Wavelengths]) AS
(
   
   -- anchor member
   SELECT 
       @RowNo_w as ROWNO_w,
	   [Timestamp],
       ResultName,
	   LEFT([Wavelengths], CHARINDEX(';', [Wavelengths] + ';') - 1),
	   STUFF([Wavelengths], 1, CHARINDEX(';', [Wavelengths] + ';'), '')
   FROM InProcess.dbo.VSpectra
   
   

   UNION ALL

   -- recursive member 
   SELECT
        ROWNO_w+1,
		[Timestamp_w],
        ResultName_w,
        LEFT([Wavelengths], CHARINDEX(';', [Wavelengths] + ';') - 1),
        STUFF([Wavelengths], 1, CHARINDEX(';', [Wavelengths] + ';'), '')
    FROM cte_split_w
	WHERE split_wavelengths > ''
	
)
,

cte_split_v(ROWNO_v, [Timestamp_v], ResultName_v, split_values, [Values]) AS
(
   
   -- anchor member
   SELECT
       @RowNo_v as ROWNO_v,
	   [Timestamp],
       VSpectra.ResultName,
	   LEFT(CONVERT(VARCHAR(MAX), [Values]), CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';') - 1),
	   STUFF(CONVERT(VARCHAR(MAX), [Values]), 1, CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';'), '')
   FROM InProcess.dbo.VSpectra
   

   UNION ALL

   -- recursive member 
   SELECT
        ROWNO_v+1,
		[Timestamp_v],
        ResultName_v,
		LEFT(CONVERT(VARCHAR(MAX), [Values]), CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';') - 1),
	   STUFF(CONVERT(VARCHAR(MAX), [Values]), 1, CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';'), '')
    FROM cte_split_v
	WHERE CONVERT(VARCHAR(MAX), [split_values]) <> ''
)


INSERT INTO table11
SELECT cte_split_v.Timestamp_v,
       cte_split_w.Timestamp_w,
       cte_split_v.ResultName_v, 
	   cte_split_w.ResultName_w,
       cte_split_v.split_values,
	   cte_split_w.split_wavelengths
FROM cte_split_v INNER JOIN cte_split_w on ROWNO_v=ROWNO_w
WHERE split_values <> ''
AND split_wavelengths <> ''
AND [Timestamp_v]='2022-10-20 03:12:29.253'
AND [Timestamp_w]=[Timestamp_v]
AND ResultName_v='Transmission of Sample'
AND ResultName_v=ResultName_w
ORDER BY split_wavelengths
option (maxrecursion 0);


