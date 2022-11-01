/*Given our InProcess Data results, we need to transpone and seperate our csv of interest (wavelengths, values) for each measurement category (transmission, reflection, absorptance)

To separate the string data into individual rows, we create two recursive CTEs, one for the wavelength string and one for the value string for each measurement.
 */ 

DECLARE @RowNo_w int =1; -- initial value for recursive CTE
DECLARE @RowNo_v int =1;


--recursive CTE for separation of wavelength data string & definition of row number:
WITH cte_split_w(ROWNO_w, ResultName, split_wavelengths, [Wavelengths]) AS
(
   
   -- 1) anchor member:initial query that defines the start result set of the CTE
   SELECT 
       @RowNo_w as ROWNO_w, -- row number CTE anchor ROWNO=1
       ResultName, -- listed, because now we can choose to only get wavelengths/values for one measurement result (see below)
	   LEFT([Wavelengths], CHARINDEX(';', [Wavelengths] + ';') - 1), --LEFT(string to be modified, number of chars after which string ends), here: String ending after 1st ','
	   STUFF([Wavelengths], 1, CHARINDEX(';', [Wavelengths] + ';'), '') --STUFF(string to be modified, starting chars number of string to be modified, number of chars to delete from string, string which will be directly inserted adjacent to remaining string)
   FROM InProcess.dbo.VSpectra --referencing original string data
   WHERE ResultName='Absorptance' --ResultName can be modified to desired measurement result: Transmission/Reflection/Absorptnace/...
   
   --3) Repeating the ongoing cycle of query steps, which are all referencing to their previous result set, as long as condition is fulfilled
   UNION ALL 

   -- 2) recursive member: subsequent query which defines the following induction step by referencing the initial query. 
   SELECT
        ROWNO_w+1, -- row number CTE recursion ROWNO=previous_ROWNO+1
        ResultName,
        LEFT([Wavelengths], CHARINDEX(';', [Wavelengths] + ';') - 1), --same procedure as before but always referencing to the previous result, which, in the beginning, is the anchor result and after that always the recursive result until ending condition fulfilled.
        STUFF([Wavelengths], 1, CHARINDEX(';', [Wavelengths] + ';'), '')
    FROM cte_split_w -- referencing previously modified string data
	WHERE ResultName='Absorptance'
	AND
    split_wavelengths > ''
	-- 4) condition: all single wavelengths have to be bigger than NULL, thus query ends when no value in wavelength string data is left. 
)

, --connection of CTEs via ','

--recursive CTE for value string:
cte_split_v(ROWNO_v, ResultName, split_values, [Values]) AS
(
   
   -- anchor member
   SELECT
       @RowNo_v as ROWNO_v,
       VSpectra.ResultName,
	   LEFT(CONVERT(VARCHAR(MAX), [Values]), CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';') - 1),
	   STUFF(CONVERT(VARCHAR(MAX), [Values]), 1, CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';'), '')
   FROM InProcess.dbo.VSpectra
   WHERE VSpectra.ResultName='Absorptance'
 
   UNION ALL

   -- recursive member 
   SELECT
        ROWNO_v+1,
        ResultName,
		LEFT(CONVERT(VARCHAR(MAX), [Values]), CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';') - 1),
	   STUFF(CONVERT(VARCHAR(MAX), [Values]), 1, CHARINDEX(';', CONVERT(VARCHAR(MAX), [Values]) + ';'), '')
    FROM cte_split_v
	WHERE ResultName='Absorptance'
    AND
    CONVERT(VARCHAR(MAX), [split_values]) <> ''
)

SELECT cte_split_v.ResultName, 
       cte_split_v.split_values,
	   cte_split_w.split_wavelengths
FROM cte_split_v INNER JOIN cte_split_w on ROWNO_v=ROWNO_w --without listing the complete set of values for each individual wavelength, we need to create row numbers and make the condition that each of the rownumbers for 'wavelength' and 'value' are the same when joining our CTEs.
WHERE split_values <> '' -- no NULL values
AND split_wavelengths <> '' -- no NULL values
ORDER BY split_wavelengths -- appropiate ordering 
option (maxrecursion 0); --doesn't work without, because otherwise too many values
