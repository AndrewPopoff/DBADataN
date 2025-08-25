
CREATE PROCEDURE [adm].[spReportLogFP] (@StartDate DATETIME, @EndDate DATETIME, @FPName NVARCHAR(128) = NULL)
AS
BEGIN
SET NOCOUNT ON

SELECT
    EL.EventType,
    EL.EventDate,
    EL.ServerName,
    EL.LoginName,
    EL.UserName,
    EL.DatabaseName,
    EL.SchemaName,
    EL.ObjectName,
    EL.NewObjectName, -- заполнено только для RENAME
    EL.ObjectType,
    EL.TSQLCommand
FROM
    adm.EventsLog EL
WHERE
    EL.EventDate >= @StartDate
    AND EL.EventDate < DATEADD(dd, 1, @EndDate)
    AND EL.ObjectType IN ('PROCEDURE', 'FUNCTION')
    AND ((@FPName IS NULL) OR (@FPName IS NOT NULL AND EL.ObjectName LIKE '%' + @FPName + '%'))
ORDER BY 
    EL.EventDate DESC

END