
CREATE PROCEDURE [adm].[spReportLog] (@StartDate DATETIME, @EndDate DATETIME, @LoginName NVARCHAR(128) = NULL)
AS
BEGIN
SET NOCOUNT ON

SELECT
    T.EventType,
    T.EventDate,
    T.ServerName,
    T.LoginName,
    T.UserName,
    T.DatabaseName,
    T.SchemaName,
    T.ObjectName,
    T.NewObjectName,
    T.ObjectType,
    T.TSQLCommand,
    T.TableCreateDate,
    T.TableModifyDate,
    T.ColumnName,
    T.ColumnEventType,
    T.Pos,
    T.DefaultValue,
    T.IsNullable,
    T.DataType,
    T.PrevPos,
    T.PrevDefaultValue,
    T.PrevIsNullable,
    T.PrevDataType
FROM
    (
    SELECT
        EL.EventType,
        EL.EventDate,
        EL.ServerName,
        EL.LoginName,
        EL.UserName,
        EL.DatabaseName,
        EL.SchemaName,
        TL.TableName ObjectName, -- EL.ObjectName
        EL.NewObjectName, -- заполнено только для типа ObjectType = RENAME
        CASE TL.TableType --EL.ObjectType,
        WHEN 1 THEN 'TABLE'
        WHEN 2 THEN 'VIEW'
        ELSE 'UNKNOWN' 
        END ObjectType,
        EL.TSQLCommand,
        TL.CreateDate TableCreateDate,
        TL.ModifyDate TableModifyDate,
        CL.ColumnName,
        CL.EventType ColumnEventType,
        CL.Pos,
        CL.DefaultValue,
        CL.IsNullable,
        CL.DataType,
        prevCL.Pos PrevPos,
        prevCL.DefaultValue PrevDefaultValue,
        prevCL.IsNullable PrevIsNullable,
        prevCL.DataType PrevDataType
    FROM
        adm.EventsLog EL
        JOIN adm.TablesLog TL ON TL.EventUID = EL.EventUID
        LEFT JOIN adm.ColumnsLog CL ON CL.EventUID = EL.EventUID AND CL.ObjectID = TL.ObjectID
        LEFT JOIN adm.ColumnsLog prevCL ON prevCL.RecUID = CL.PrevRecUID
    WHERE
        EL.EventDate >= @StartDate
        AND EL.EventDate < DATEADD(dd, 1, @EndDate)
        AND ((@LoginName IS NULL) OR (@LoginName IS NOT NULL AND EL.LoginName LIKE '%' + @LoginName + '%'))
    UNION ALL -- добавим информацию по переименованию полей
    SELECT
        EL.EventType,
        EL.EventDate,
        EL.ServerName,
        EL.LoginName,
        EL.UserName,
        EL.DatabaseName,
        EL.SchemaName,
        EL.ObjectName,
        EL.NewObjectName, -- заполнено 
        EL.ObjectType,
        EL.TSQLCommand,
        NULL TableCreateDate,
        NULL TableModifyDate,
        CL.ColumnName,
        CL.EventType ColumnEventType,
        CL.Pos,
        CL.DefaultValue,
        CL.IsNullable,
        CL.DataType,
        prevCL.Pos PrevPos,
        prevCL.DefaultValue PrevDefaultValue,
        prevCL.IsNullable PrevIsNullable,
        prevCL.DataType PrevDataType
    FROM
        adm.EventsLog EL
        JOIN adm.ColumnsLog CL ON CL.EventUID = EL.EventUID
        LEFT JOIN adm.ColumnsLog prevCL ON prevCL.RecUID = CL.PrevRecUID -- можно и не смотреть
    WHERE
        EL.EventDate >= @StartDate
        AND EL.EventDate < DATEADD(dd, 1, @EndDate)
        AND EL.EventType = 'RENAME'
        AND EL.ObjectType = 'COLUMN'
        AND ((@LoginName IS NULL) OR (@LoginName IS NOT NULL AND EL.LoginName LIKE '%' + @LoginName + '%'))
    ) T
ORDER BY 
   T.EventDate DESC

END