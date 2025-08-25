
CREATE PROCEDURE [adm].[spFillBranchID_CL] 
AS
BEGIN

SET NOCOUNT ON
-- первоначальное значение BranchID
UPDATE 
	CL
SET
	CL.BranchUID = NEWID()
FROM 
	adm.ColumnsLog CL 
WHERE 
	CL.BranchUID IS NULL
	AND CL.PrevRecUID IS NULL

-- найти значение branchUID у родителя
DECLARE @RecID		UNIQUEIDENTIFIER
DECLARE @PrevRecUID UNIQUEIDENTIFIER
DECLARE @BranchUID	UNIQUEIDENTIFIER

DECLARE curT CURSOR 
FOR 
SELECT 
    CL.RecUID, 
    CL.PrevRecUID 
FROM 
    adm.ColumnsLog CL 
WHERE 
    CL.PrevRecUID IS NOT NULL 
    AND CL.BranchUID IS NULL

OPEN curT
FETCH NEXT FROM curT INTO @RecID , @PrevRecUID
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC adm.spFindBranchID_CL @RecID, @BranchUID OUTPUT
    IF @BranchUID IS NOT NULL 
        UPDATE 
            CL
        SET 
            CL.BranchUID = @BranchUID
        FROM 
            adm.ColumnsLog CL 
        WHERE 
            CL.RecUID = @RecID
    FETCH NEXT FROM curT INTO @RecID , @PrevRecUID
END
CLOSE curT
DEALLOCATE curT

END