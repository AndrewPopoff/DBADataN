
CREATE PROCEDURE [adm].[spProcessEvent] (@xml xml)
AS
BEGIN
-- на входе xml EVENTDATA()
-- надо заполнить три таблицы: первое это собственно то, что событие произошло
-- второе: это зафиксировать изменение в таблицах
-- третье: зафиксировать изменение в столбцах

SET NOCOUNT ON

DECLARE @tEventUID			TABLE (EventUID UNIQUEIDENTIFIER)
DECLARE @EventUID			UNIQUEIDENTIFIER
DECLARE @ServerName			NVARCHAR(128)
DECLARE @LoginName			NVARCHAR(128)
DECLARE @UserName			NVARCHAR(128)
DECLARE @DatabaseName		NVARCHAR(128)
DECLARE @SchemaName			NVARCHAR(128)
DECLARE @ObjectName			NVARCHAR(128)
DECLARE @NewObjectName		NVARCHAR(128)
DECLARE @TargetObjectName	NVARCHAR(128)
DECLARE @EventType			NVARCHAR(128)
DECLARE @ObjectType			NVARCHAR(128)
DECLARE @TSQLCommand		NVARCHAR(1024)
DECLARE @tCols				TABLE(ColumnName NVARCHAR(128)) -- список столбцов при ALTER TABLE
DECLARE @ColumnName			NVARCHAR(128)
DECLARE @PrevRecUID			UNIQUEIDENTIFIER
DECLARE	@ObjectID			INT
DECLARE	@ColumnEventType	NVARCHAR(128)

DECLARE @PrevView           TABLE -- структура view до изменений
(
RecUID                      UNIQUEIDENTIFIER,
ColumnName                  NVARCHAR(255),
DataType                    NVARCHAR(255),
DefaultValue                NVARCHAR(255),
IsNullable                  TINYINT
)

DECLARE @CurrView           TABLE --  структура view после изменений (текущая)
(
ColumnName                  NVARCHAR(255),
DataType                    NVARCHAR(255),
DefaultValue                NVARCHAR(255),
IsNullable                  TINYINT
)

DECLARE @tmpColumnName      NVARCHAR(255)
DECLARE @tmpInt             INT
DECLARE @tmpDataType        NVARCHAR(255)
DECLARE @tmpDefaultValue    NVARCHAR(255)
DECLARE @tmpIsNullable      TINYINT

-- разберем входящий xml	
SELECT  
	@ServerName =  @xml.value('(/EVENT_INSTANCE/ServerName)[1]', 'nvarchar(128)'),
	@LoginName = @xml.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(128)'),
	@UserName = @xml.value('(/EVENT_INSTANCE/UserName)[1]', 'nvarchar(128)'),
	@DatabaseName = @xml.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(128)'),
	@SchemaName = @xml.value('(/EVENT_INSTANCE/SchemaName)[1]', 'nvarchar(128)'),
	@ObjectName = @xml.value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(128)'),
	@NewObjectName = @xml.value('(/EVENT_INSTANCE/NewObjectName)[1]', 'nvarchar(128)'),
	@TargetObjectName = @xml.value('(/EVENT_INSTANCE/TargetObjectName)[1]', 'nvarchar(128)'),
	@EventType = @xml.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(128)'),
	@ObjectType = @xml.value('(/EVENT_INSTANCE/ObjectType)[1]', 'nvarchar(128)'),
    @TSQLCommand = @xml.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'nvarchar(1024)')

SET @ObjectID = OBJECT_ID(@DatabaseName + '.' + @SchemaName + '.' + @ObjectName) -- NULL при DROP TABLE/VIEW

-- запишем, что событие произошло
INSERT INTO adm.EventsLog
(
EventType,
EventDate,
ServerName,
LoginName,
UserName,
DatabaseName,
SchemaName,
ObjectName,
NewObjectName,
ObjectType,
TSQLCommand,
PlainEventdata
)
OUTPUT inserted.EventUID INTO @tEventUID
VALUES
(
ISNULL(@EventType,''),
GETDATE(),
ISNULL(@ServerName,''),
ISNULL(@LoginName,''),
ISNULL(@UserName,''),
ISNULL(@DatabaseName,''),
ISNULL(@SchemaName,''),
ISNULL(@ObjectName,''),
ISNULL(@NewObjectName,''),
ISNULL(@ObjectType,''),
ISNULL(@TSQLCommand,''),
@xml
)
-- идентификатор, добавленной записи
SET @EventUID = (SELECT TOP 1 EventUID FROM @tEventUID)

-- при создании таблицы или представления получим все колонки этих объектов ---------------------------------------------------------------
IF @EventType = 'CREATE_VIEW' OR @EventType = 'CREATE_TABLE'
BEGIN
	EXEC adm.spInsertTablesLog @EventUID, @ObjectID
	EXEC adm.spInsertColumnsLog @EventUID, 'CREATE', @ObjectID
END

-- при изменении VIEW смотрим колонки ----------------------------------------------------------------------------
IF @EventType = 'ALTER_VIEW' 
BEGIN
	SET @PrevRecUID = 
	(
	SELECT TOP 1
		TL.RecUID
	FROM
		adm.TablesLog TL
	WHERE 
		TL.ObjectID = @ObjectID
	ORDER BY
		TL.ModifyDate DESC
	)

    EXEC adm.spInsertTablesLog @EventUID, @ObjectID, @PrevRecUID

    -- далее разбираемся какие данные добавить в adm.ColumnsLog
    -- получим структуру View, которая была ранее
    INSERT INTO @PrevView
    (
    RecUID,
    ColumnName,
    DataType,
    DefaultValue,
    IsNullable
    )
    SELECT
        CL.RecUID,
        CL.ColumnName,
        CL.DataType,
        CL.DefaultValue,
        CL.IsNullable
    FROM
	    (SELECT -- здесь берем последние изменения по колонке 
		    CL.ColumnName,
            MAX(CL.ModifyDate) MaxDate
	    FROM
		    adm.ColumnsLog CL
	    WHERE
		    CL.ObjectID = @ObjectID
	    GROUP BY
		    CL.ColumnName) T
        JOIN adm.ColumnsLog CL ON CL.ObjectID = @ObjectID AND CL.ColumnName = T.ColumnName AND CL.ModifyDate = T.MaxDate
    WHERE
        CL.EventType <> 'DROP' -- не смотрим удаленные ранее

    -- получим структуру View, которая стала сейчас
    INSERT INTO @CurrView
    (
    ColumnName,
    DefaultValue,
    IsNullable,
    DataType
    )
    SELECT 
	    scol.[name] ColumnName,
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
	    END  [DataType]
    FROM 
	    [sys].[columns] scol
	    JOIN [sys].[types] stypes ON stypes.user_type_id = scol.user_type_id
	    LEFT JOIN [sys].[default_constraints] sdefaults ON sdefaults.[object_id] = scol.default_object_id 
    WHERE
	    scol.object_id = @ObjectID	

    -- смотрим новую структуру и ищем такое же поле в старой
    -- если оно есть, значит поле было изменено
    -- если его нет, значит добавлено
    DECLARE curView CURSOR FOR 
    SELECT 
        ColumnName,
        DataType,
        DefaultValue,
        IsNullable
    FROM 
        @CurrView
    OPEN curView
    FETCH NEXT FROM curView INTO @tmpColumnName, @tmpDataType, @tmpDefaultValue, @tmpIsNullable
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @PrevRecUID = (SELECT CL.RecUID FROM @PrevView CL WHERE	CL.ColumnName = @tmpColumnName)
        IF @PrevRecUID IS NULL
        BEGIN
            SET @ColumnEventType = 'CREATE' 
            EXEC adm.spInsertColumnsLog @EventUID, @ColumnEventType, @ObjectID, @tmpColumnName, @PrevRecUID
        END
        ELSE
        BEGIN
            SET @ColumnEventType = 'ALTER' 
            -- если ничего не изменилось (3 параметра), то не будем писать изменения
            SET @tmpInt = (SELECT 1 FROM @PrevView CL WHERE CL.ColumnName = @tmpColumnName AND CL.DataType = @tmpDataType AND CL.DefaultValue = @tmpDefaultValue AND CL.IsNullable = @tmpIsNullable)
            SET @tmpInt = ISNULL(@tmpInt,0)
            IF @tmpInt = 0 
               EXEC adm.spInsertColumnsLog @EventUID, @ColumnEventType, @ObjectID, @tmpColumnName, @PrevRecUID
        END
        
        FETCH NEXT FROM curView INTO @tmpColumnName, @tmpDataType, @tmpDefaultValue, @tmpIsNullable
    END
    CLOSE curView
    DEALLOCATE curView

    -- смотрим старую структуру View
    -- если в новой стуктуре нет такого поля, значит оно было удалено
    DECLARE curView CURSOR FOR SELECT RecUID, ColumnName FROM @PrevView
    OPEN curView
    FETCH NEXT FROM curView INTO @PrevRecUID, @tmpColumnName
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @tmpInt = ISNULL((SELECT 1 FROM @CurrView CL WHERE	CL.ColumnName = @tmpColumnName),0)
        IF @tmpInt = 0
        BEGIN
            SET @ColumnEventType = 'DROP' 
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
	                    @ObjectID,
	                    @tmpColumnName,
	                    CL.Pos,
	                    CL.DefaultValue,
	                    CL.IsNullable,
	                    CL.DataType,
	                    @EventUID EventUID,
	                    @PrevRecUID,
                        @ColumnEventType,
						CL.BranchUID
                    FROM 
                        adm.ColumnsLog CL 
                    WHERE
                        CL.RecUID = @PrevRecUID
        END
    
        FETCH NEXT FROM curView INTO @PrevRecUID, @tmpColumnName
    END
    CLOSE curView
    DEALLOCATE curView

END

-- при удалении VIEW/TABLE не смотрим колонки --------------------------------------------------------------------
IF @EventType = 'DROP_VIEW' OR @EventType = 'DROP_TABLE'
BEGIN
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
    SELECT TOP 1
	    TL.ObjectID,
	    @DatabaseName,
	    @SchemaName,
	    @ObjectName,
	    TL.TableType,
	    @EventUID,
	    TL.CreateDate,
	    GETDATE(),
	    TL.RecUID,
		TL.BranchUID
	FROM
		adm.TablesLog TL
	WHERE 
		TL.DBName = @DatabaseName
        AND TL.TableSchema = @SchemaName
        AND TL.TableName = @ObjectName
	ORDER BY
		TL.ModifyDate DESC
END

-- при изменении таблицы получим список колонок, которые изменились ---------------------------------------------------
IF @EventType = 'ALTER_TABLE' 
BEGIN
	SET @PrevRecUID = 
	(
	SELECT TOP 1
		TL.RecUID
	FROM
		adm.TablesLog TL
	WHERE 
		TL.ObjectID = @ObjectID
	ORDER BY
		TL.ModifyDate DESC
	)

	EXEC [adm].[spInsertTablesLog] @EventUID, @ObjectID, @PrevRecUID

	-- список вновь создаваемых столбцов
	INSERT INTO @tCols (ColumnName)
	SELECT 
		t.c.value(N'(./text())[1]', N'sysname') ColumnName
	FROM   
		@xml.nodes(N'/EVENT_INSTANCE/AlterTableActionList/Create/Columns/Name') t(c)
	IF @@ROWCOUNT <> 0 SET @ColumnEventType = 'CREATE'

	-- список изменяемых столбцов
	INSERT INTO @tCols (ColumnName)
	SELECT 
		t.c.value(N'(./text())[1]', N'sysname') ColumnName
	FROM   
		@xml.nodes(N'/EVENT_INSTANCE/AlterTableActionList/Alter/Columns/Name') t(c)
	IF @@ROWCOUNT <> 0 SET @ColumnEventType = 'ALTER'

	-- список удаляемых столбцов
	INSERT INTO @tCols (ColumnName)
	SELECT 
		t.c.value(N'(./text())[1]', N'sysname') AS [ColumnName]
	FROM   
		@xml.nodes(N'/EVENT_INSTANCE/AlterTableActionList/Drop/Columns/Name') t(c);
	IF @@ROWCOUNT <> 0 SET @ColumnEventType = 'DROP'

	-- в курсоре добавим инфу о столбцах
	DECLARE curCols CURSOR FOR SELECT ColumnName FROM @tCols
	OPEN curCols
	FETCH NEXT FROM curCols INTO @ColumnName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @PrevRecUID =  
		(
		SELECT TOP 1
			CL.RecUID
		FROM
			adm.ColumnsLog CL
		WHERE
			CL.ObjectID = @ObjectID
			AND CL.ColumnName = @ColumnName
		ORDER BY
			CL.ModifyDate DESC -- последние изменения этого столбца
		)

		IF @ColumnEventType = 'CREATE' OR @ColumnEventType = 'ALTER'
			EXEC adm.spInsertColumnsLog @EventUID, @ColumnEventType, @ObjectID, @ColumnName, @PrevRecUID

		IF @ColumnEventType = 'DROP'
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
	            @ObjectID,
	            @ColumnName,
	            CL.Pos,
	            CL.DefaultValue,
	            CL.IsNullable,
	            CL.DataType,
	            @EventUID EventUID,
	            @PrevRecUID,
                @ColumnEventType,
				CL.BranchUID
            FROM 
                adm.ColumnsLog CL 
            WHERE
                CL.RecUID = @PrevRecUID
		
		FETCH NEXT FROM curCols INTO @ColumnName
	END
	CLOSE curCols
	DEALLOCATE curCols
END

-- Переименование таблиц/представлений и колонок ------------------------------------------
IF @EventType = 'RENAME' 
BEGIN
    IF @ObjectType = 'TABLE'
    BEGIN
	    SET @PrevRecUID = 
	    (
	    SELECT TOP 1
		    TL.RecUID
	    FROM
		    adm.TablesLog TL
	    WHERE 
            TL.DBName = @DatabaseName
            AND TL.TableName = @ObjectName
            AND TL.TableSchema = @SchemaName
	    ORDER BY
		    TL.ModifyDate DESC
	    )
        SET @ObjectID = OBJECT_ID(@DatabaseName + '.' + @SchemaName + '.' + @NewObjectName)
        EXEC adm.spInsertTablesLog @EventUID, @ObjectID, @PrevRecUID
    END

    IF @ObjectType = 'COLUMN'
    BEGIN
        SET @ObjectID = OBJECT_ID(@DatabaseName + '.' + @SchemaName + '.' + @TargetObjectName)
		SET @PrevRecUID =  
		(
		SELECT TOP 1
			CL.RecUID
		FROM
			adm.ColumnsLog CL
		WHERE
			CL.ObjectID = @ObjectID
			AND CL.ColumnName = @ObjectName
		ORDER BY
			CL.ModifyDate DESC -- последние изменения этого столбца
		)

		SET @ColumnEventType = 'RENAME'
        EXEC adm.spInsertColumnsLog @EventUID, @ColumnEventType, @ObjectID, @NewObjectName, @PrevRecUID
        
    END
END

END