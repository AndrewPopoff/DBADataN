
CREATE PROCEDURE [adm].[spFillBranchID_TL] 
AS
BEGIN

SET NOCOUNT ON
-- первоначальное значение BranchID
UPDATE 
	TL
SET
	TL.BranchUID = NEWID()
FROM 
	adm.TablesLog TL 
WHERE 
	TL.BranchUID IS NULL
	AND TL.PrevRecUID IS NULL

-- найти значение branchUID у родителя
DECLARE @RecID		UNIQUEIDENTIFIER
DECLARE @PrevRecUID UNIQUEIDENTIFIER
DECLARE @BranchUID	UNIQUEIDENTIFIER

DECLARE curT CURSOR 
FOR 
SELECT 
    TL.RecUID, 
    TL.PrevRecUID 
FROM 
    adm.TablesLog TL 
WHERE 
    TL.PrevRecUID IS NOT NULL 
    AND TL.BranchUID IS NULL

OPEN curT
FETCH NEXT FROM curT INTO @RecID , @PrevRecUID
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC adm.spFindBranchID_TL @RecID, @BranchUID OUTPUT
    IF @BranchUID IS NOT NULL 
        UPDATE 
            TL
        SET 
            TL.BranchUID = @BranchUID
        FROM 
            adm.TablesLog TL 
        WHERE 
            TL.RecUID = @RecID
    FETCH NEXT FROM curT INTO @RecID , @PrevRecUID
END
CLOSE curT
DEALLOCATE curT

END