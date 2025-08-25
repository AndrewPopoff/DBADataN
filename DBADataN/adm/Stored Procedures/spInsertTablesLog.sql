

CREATE PROCEDURE [adm].[spInsertTablesLog] (@EventUID UNIQUEIDENTIFIER, @ObjectID INT = NULL, @PrevRecUID UNIQUEIDENTIFIER = NULL)
AS
BEGIN

SET NOCOUNT ON

INSERT INTO adm.TablesLog
(
ObjectID,
DBName,
TableSchema,
TableName,
TableType,
EventUID,
CreateDate,
ModifyDate,
PrevRecUID,
BranchUID
)	
SELECT
	sobj.object_id,
	DB_NAME() DBName,
	SCHEMA_NAME(sobj.schema_id) TableSchema,
	sobj.[name] TableName,
	CASE sobj.type
	WHEN 'U' THEN 1
	WHEN 'V' THEN 2
	ELSE 0
	END TableType,
	@EventUID,
	sobj.create_date CreateDate,
	sobj.modify_date ModifyDate,
	@PrevRecUID,
	CASE 
	WHEN @PrevRecUID IS NULL THEN NEWID()
	ELSE (SELECT TL.BranchUID FROM adm.TablesLog TL WHERE TL.RecUID = @PrevRecUID)
	END BranchUID
FROM
	[sys].[objects] sobj
WHERE
	sobj.type IN ('U','V')
	AND (@ObjectID IS NULL OR (@ObjectID IS NOT NULL AND sobj.object_id = @ObjectID))

END