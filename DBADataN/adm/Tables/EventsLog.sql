CREATE TABLE [adm].[EventsLog] (
    [EventUID]       UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL,
    [EventType]      NVARCHAR (128)   NOT NULL,
    [EventDate]      DATETIME         DEFAULT (getdate()) NOT NULL,
    [ServerName]     NVARCHAR (128)   NOT NULL,
    [LoginName]      NVARCHAR (128)   NOT NULL,
    [UserName]       NVARCHAR (128)   NOT NULL,
    [DatabaseName]   NVARCHAR (128)   NOT NULL,
    [SchemaName]     NVARCHAR (128)   NOT NULL,
    [ObjectName]     NVARCHAR (128)   NOT NULL,
    [NewObjectName]  NVARCHAR (128)   NOT NULL,
    [ObjectType]     NVARCHAR (128)   NOT NULL,
    [TSQLCommand]    NVARCHAR (1024)  NOT NULL,
    [PlainEventdata] XML              NULL,
    CONSTRAINT [EventsLog_pk] PRIMARY KEY CLUSTERED ([EventUID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Имя БД', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'DatabaseName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Дата события', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'EventDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Тип события', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'EventType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Код события', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'EventUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Логин', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'LoginName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Новое имя объекта', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'NewObjectName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Объект', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'ObjectName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Тип объекта', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'ObjectType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'xml, возвращаемый EVENTDATA()', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'PlainEventdata';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Схема', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'SchemaName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Сервер', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'ServerName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Код TSQL', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'TSQLCommand';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Пользователь', @level0type = N'SCHEMA', @level0name = N'adm', @level1type = N'TABLE', @level1name = N'EventsLog', @level2type = N'COLUMN', @level2name = N'UserName';

