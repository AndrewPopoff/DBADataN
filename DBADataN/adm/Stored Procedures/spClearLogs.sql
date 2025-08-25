

CREATE PROCEDURE [adm].[spClearLogs] (@BorderDate DATETIME)
AS
BEGIN

SET NOCOUNT ON
-- порядок удаление важен: вначале поля, потом таблицы, потом события

-- удаление из лога полей при условии, что поле было удалено 
DELETE 
    bCL
FROM 
    adm.EventsLog EL
    JOIN adm.ColumnsLog CL ON CL.EventUID = EL.EventUID
    JOIN adm.ColumnsLog bCL ON bCL.BranchUID = CL.BranchUID
WHERE
    EL.EventDate < @BorderDate
    AND CL.EventType = 'DROP'

-- удаление из лога полей, при условии удаления таблицы
DELETE 
    CL
FROM
    adm.EventsLog EL
    JOIN adm.TablesLog TL ON TL.EventUID = EL.EventUID
    JOIN adm.TablesLog bTL ON bTL.BranchUID = TL.BranchUID
    JOIN adm.ColumnsLog CL ON CL.EventUID = bTL.EventUID AND CL.ObjectID = TL.ObjectID
WHERE
    EL.EventDate < @BorderDate
    AND EL.EventType IN ('DROP_TABLE', 'DROP_VIEW')

-- удаление из лога таблиц, при условии удаления таблицы
DELETE 
    bTL
FROM
    adm.EventsLog EL
    JOIN adm.TablesLog TL ON TL.EventUID = EL.EventUID
    JOIN adm.TablesLog bTL ON bTL.BranchUID = TL.BranchUID
WHERE
    EL.EventDate < @BorderDate
    AND EL.EventType IN ('DROP_TABLE', 'DROP_VIEW')
    AND NOT EXISTS (SELECT 1 FROM adm.ColumnsLog CL WHERE CL.EventUID = TL.EventUID AND CL.ObjectID = TL.ObjectID) -- в целом, ненужная строка, на всякий пожарный

--  удаление из лога полей ----------------------------------------------------
DELETE
    CL
FROM
    (
    SELECT
        CL.RecUID,
        ROW_NUMBER() OVER(PARTITION BY CL.BranchUID ORDER BY CL.BranchUID, EL.EventDate DESC) Cnt,
        EL.EventDate
    FROM
        adm.EventsLog EL
        JOIN adm.ColumnsLog CL ON CL.EventUID = EL.EventUID
    ) T
    JOIN adm.ColumnsLog CL ON CL.RecUID = T.RecUID
WHERE
    T.EventDate < @BorderDate
    AND T.Cnt > 2

--  удаление из лога таблиц ----------------------------------------------------
DELETE
    TL
FROM
    (
    SELECT
        TL.RecUID,
        ROW_NUMBER() OVER(PARTITION BY TL.BranchUID ORDER BY TL.BranchUID, EL.EventDate DESC) Cnt,
        EL.EventDate
    FROM
        adm.EventsLog EL
        JOIN adm.TablesLog TL ON TL.EventUID = EL.EventUID
    ) T
    JOIN adm.TablesLog TL ON TL.RecUID = T.RecUID
WHERE
    T.EventDate < @BorderDate
    AND T.Cnt > 2
    AND NOT EXISTS (SELECT 1 FROM adm.ColumnsLog CL WHERE CL.EventUID = TL.EventUID AND CL.ObjectID = TL.ObjectID) -- в целом, ненужная строка, на всякий пожарный


-- удаление из лога событий ----------------------------------------------------
DELETE
    EL
FROM
    adm.EventsLog EL
WHERE
    El.EventDate < @BorderDate
    AND NOT EXISTS (SELECT 1 FROM adm.TablesLog TL WHERE TL.EventUID = EL.EventUID)
    AND NOT EXISTS (SELECT 1 FROM adm.ColumnsLog CL WHERE CL.EventUID = EL.EventUID)

END