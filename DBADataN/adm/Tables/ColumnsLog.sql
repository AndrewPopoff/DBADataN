CREATE TABLE [adm].[ColumnsLog] (
    [RecUID]       UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL,
    [ObjectID]     INT              NOT NULL,
    [ColumnName]   NVARCHAR (255)   NOT NULL,
    [Pos]          INT              NOT NULL,
    [DefaultValue] NVARCHAR (255)   NULL,
    [IsNullable]   TINYINT          DEFAULT ((0)) NOT NULL,
    [DataType]     NVARCHAR (255)   NOT NULL,
    [EventUID]     UNIQUEIDENTIFIER NOT NULL,
    [ModifyDate]   DATETIME         DEFAULT (getdate()) NOT NULL,
    [PrevRecUID]   UNIQUEIDENTIFIER NULL,
    [EventType]    NVARCHAR (128)   NOT NULL,
    [BranchUID]    UNIQUEIDENTIFIER DEFAULT (newid()) NULL,
    CONSTRAINT [ColumnsLog_pk] PRIMARY KEY CLUSTERED ([RecUID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Сквозной id для всех изменений одного поля', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'BranchUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Наименование столбца', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'ColumnName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Тип данных', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'DataType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Значение default ', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'DefaultValue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Тип события: CREATE, ALTER, DROP', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'EventType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'UID события, которое привело к изменениям', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'EventUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'- 0 NOT NULL
- 1 NULL', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'IsNullable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Дата изменения', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'ModifyDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'OBJECT_ID() Таблицы или представления', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'ObjectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Позиция по порядку', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'Pos';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ссылка на предыдущее изменение', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'PrevRecUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Идентификатор записи', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'ColumnsLog', @level2type = N'COLUMN', @level2name = N'RecUID';

