
CREATE PROCEDURE [adm].[spInsertColumnsLog] (@EventUID UNIQUEIDENTIFIER, @EventType NVARCHAR(128), @ObjectID INT = NULL, @ColumnName NVARCHAR(128) = NULL, @PrevRecUID UNIQUEIDENTIFIER = NULL)
AS
BEGIN

SET NOCOUNT ON

INSERT INTO adm.ColumnsLog
(
ObjectID,
ColumnName,
Pos,
DefaultValue,
IsNullable,
DataType,
EventUID,
PrevRecUID,
EventType,
BranchUID
)
SELECT 
	scol.[object_id] ObjectID,
	scol.[name] ColumnName,
	scol.column_id Pos,
	ISNULL(sdefaults.[definition],'') DefaultValue,
	scol.is_nullable IsNullable,
	CASE
	WHEN scol.user_type_id IN (165, 167, 173,175) -- varbinary, varchar, binary, char
	THEN stypes.[name] + '(' + CASE scol.[max_length] WHEN -1 THEN 'MAX' ELSE CONVERT(VARCHAR(10), scol.[max_length]) END + ')' -- max_length: 1 - 8000, -1 = MAX
	WHEN scol.[user_type_id] IN (231, 239) -- nvarchar, nchar
	THEN stypes.[name] + '(' + CASE scol.[max_length] WHEN -1 THEN 'MAX' ELSE CONVERT(VARCHAR(10), (scol.[max_length] / 2)) END + ')' -- max_length: (2 - 8000)/2, -1 = MAX
	WHEN scol.[user_type_id] IN (41, 42, 43) -- time, datetime2, datetimeoffset
	THEN stypes.[name] + '(' + CONVERT(VARCHAR(10), scol.[scale]) + ')' -- scale: 1 - 7
	WHEN scol.[user_type_id] IN (106, 108) -- decimal, numeric
	THEN stypes.[name] + '(' + CONVERT(VARCHAR(10), scol.[precision]) + ', ' + CONVERT(VARCHAR(10), scol.[scale]) + ')' -- prec. & scale
	ELSE stypes.[name]
	END  [DataType],
	@EventUID EventUID ,
	@PrevRecUID,
    @EventType,
	CASE 
	WHEN @PrevRecUID IS NULL THEN NEWID()
	ELSE (SELECT CL.BranchUID FROM adm.ColumnsLog CL WHERE CL.RecUID = @PrevRecUID)
	END BranchUID
	--scol.is_rowguidcol,  -- на всякий случай для будущего
	--scol.is_identity,
	--scol.is_computed,
	--scol.is_sparse,
	--scol.is_xml_document,
	--scol.collation_name
FROM 
	[sys].[columns] scol
	JOIN [sys].[types] stypes ON stypes.user_type_id = scol.user_type_id
	LEFT JOIN [sys].[default_constraints] sdefaults ON sdefaults.[object_id] = scol.default_object_id 
	JOIN [sys].[objects] sobj ON sobj.object_id = scol.object_id AND sobj.type IN ('U','V') -- только user-таблицы (без системных)
WHERE
	1 = 1
	AND (@ObjectID IS NULL OR (@ObjectID IS NOT NULL AND scol.object_id = @ObjectID))
	AND (@ColumnName IS NULL OR (@ColumnName IS NOT NULL AND scol.[name] = @ColumnName))


END