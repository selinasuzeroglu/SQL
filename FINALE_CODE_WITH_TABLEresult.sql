DECLARE @RowNo_w int =1;
DECLARE @RowNo_v int =1;
WITH cte_split_w(ROWNO_w, ResultName, split_wavelengths, [Wavelengths]) AS
(
   
   -- anchor member
   SELECT 
       @RowNo_w as ROWNO_w,
       ResultName,
	   LEFT([Wavelengths], CHARINDEX(';', [Wavelengths] + ';') - 1),
	   STUFF([Wavelengths], 1, CHARINDEX(';', [Wavelengths] + ';'), '')
   FROM InProcess.dbo.VSpectra
   WHERE ResultName='Transmission of Sample'
   

   UNION ALL

   -- recursive member 
   SELECT
        ROWNO_w+1,
        ResultName,
        LEFT([Wavelengths], CHARINDEX(';', [Wavelengths] + ';') - 1),
        STUFF([Wavelengths], 1, CHARINDEX(';', [Wavelengths] + ';'), '')
    FROM cte_split_w
	WHERE ResultName='Transmission of Sample'
	AND
    split_wavelengths > ''
	
)
,

cte_split_v(ROWNO_v, ResultName, split_values, [Values]) AS
(
   
   -- anchor member
   SELECT
       @RowNo_v as ROWNO_v,
       VSpectra.ResultName,
	   LEFT(CONVERT(VARCHAR(MAX), [Values]), CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';') - 1),
	   STUFF(CONVERT(VARCHAR(MAX), [Values]), 1, CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';'), '')
   FROM InProcess.dbo.VSpectra
   WHERE VSpectra.ResultName='Transmission of Sample'
 
   UNION ALL

   -- recursive member 
   SELECT
        ROWNO_v+1,
        ResultName,
		LEFT(CONVERT(VARCHAR(MAX), [Values]), CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';') - 1),
	   STUFF(CONVERT(VARCHAR(MAX), [Values]), 1, CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';'), '')
    FROM cte_split_v
	WHERE ResultName='Transmission of Sample'
    AND
    CONVERT(VARCHAR(MAX), [split_values]) <> ''
)


INSERT INTO result
SELECT cte_split_v.ResultName, 
       cte_split_v.split_values,
	   cte_split_w.split_wavelengths
FROM cte_split_v INNER JOIN cte_split_w on ROWNO_v=ROWNO_w
WHERE split_values <> ''
AND split_wavelengths <> ''
ORDER BY split_wavelengths
option (maxrecursion 0);

SELECT * FROM result 