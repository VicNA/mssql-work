USE tcryptapi_new;
GO

DECLARE @execute BIT = 'false';

IF @execute = 'false'
BEGIN

    SELECT COUNT(1)
    FROM [TranscryptDataStorage].[dbo].Data d 
        LEFT JOIN FilesContent fc               ON fc.DataStorageId = d.DataId 
        LEFT jOIN RoutingWorkflowDocuments rd   ON rd.DataStorageId = d.DataId
        LEFT JOIN RoutingWorkflowSignatures rs  ON rs.DataStorageId = d.DataId
        LEFT JOIN EmployeeShelfAccess esa       ON esa.DataStorageId = d.DataId
    WHERE fc.Id IS NULL 
        AND rd.Id IS NULL 
        AND rs.Id IS NULL 
        AND esa.EmployeeId IS NULL;

END
ELSE
BEGIN

    DECLARE @row   INT
          , @count INT
          , @time  INT
          , @start DATETIME
          , @end   DATETIME;

    SELECT @count = COUNT(1)
    FROM [TranscryptDataStorage].[dbo].Data d 
        LEFT JOIN FilesContent fc               ON fc.DataStorageId = d.DataId 
        LEFT jOIN RoutingWorkflowDocuments rd   ON rd.DataStorageId = d.DataId
        LEFT JOIN RoutingWorkflowSignatures rs  ON rs.DataStorageId = d.DataId
        LEFT JOIN EmployeeShelfAccess esa       ON esa.DataStorageId = d.DataId
    WHERE fc.Id IS NULL 
        AND rd.Id IS NULL 
        AND rs.Id IS NULL 
        AND esa.EmployeeId IS NULL;

    SELECT @start = GETDATE()                       -- время запуска задачи
         , @time  = 6                               -- длительность работы скрипта
         , @end   = DATEADD(HOUR, @time, @start)    -- время завершения задачи
         , @row   = 25000;                          -- количество строк на итерацию

    WHILE @count > 0 AND (GETDATE() < @end)
    BEGIN
        DELETE FROM [TranscryptDataStorage].[dbo].Data 
        WHERE DataId IN (
            SELECT TOP (@row) d.DataId
            FROM [TranscryptDataStorage].[dbo].Data d 
                LEFT JOIN FilesContent fc               ON fc.DataStorageId = d.DataId 
                LEFT jOIN RoutingWorkflowDocuments rd   ON rd.DataStorageId = d.DataId
                LEFT JOIN RoutingWorkflowSignatures rs  ON rs.DataStorageId = d.DataId
                LEFT JOIN EmployeeShelfAccess esa       ON esa.DataStorageId = d.DataId
            WHERE fc.Id IS NULL 
                AND rd.Id IS NULL 
                AND rs.Id IS NULL 
                AND esa.EmployeeId IS NULL
            )

        SET @count -= @row;
    END

END