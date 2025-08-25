CREATE TABLE [adm].[TablesLog] (
    [RecUID]      UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL,
    [ObjectID]    INT              NOT NULL,
    [DBName]      NVARCHAR (255)   NOT NULL,
    [TableSchema] NVARCHAR (255)   NOT NULL,
    [TableName]   NVARCHAR (255)   NOT NULL,
    [TableType]   TINYINT          DEFAULT ((1)) NOT NULL,
    [EventUID]    UNIQUEIDENTIFIER NOT NULL,
    [CreateDate]  DATETIME         NOT NULL,
    [ModifyDate]  DATETIME         DEFAULT (getdate()) NOT NULL,
    [PrevRecUID]  UNIQUEIDENTIFIER NULL,
    [BranchUID]   UNIQUEIDENTIFIER DEFAULT (newid()) NULL,
    CONSTRAINT [TablesLog_pk] PRIMARY KEY CLUSTERED ([RecUID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Сквозной id для всех изменений одной таблицы', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'BranchUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Дата создания таблицы/представления', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'CreateDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'База данных', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'DBName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'GUID события ', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'EventUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Дата изменения таблицы/представления', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'ModifyDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'OBJECT_ID() таблицы или представления', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'ObjectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ссылка на предыдущее изменение', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'PrevRecUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Идентификатор записи', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'RecUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Таблица или представление', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'TableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Схема таблицы', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'TableSchema';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'1 - таблица
2 - представление
0 - неизвестно', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog', @level2type = N'COLUMN', @level2name = N'TableType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Изменения CREATE, ALTER, DROP TABLE/VIEW', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'TablesLog';

