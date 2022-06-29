USE tcryptapi_new;

DECLARE @execute BIT = 'false';

IF @execute = 'false'
BEGIN

    SELECT [DBName] = 'TranscryptDataStorage'
         , [Row]    = COUNT(1)
    FROM [TranscryptDataStorage].[dbo].Data d
        LEFT JOIN FilesContent fc               ON fc.DataStorageId = d.DataId
        LEFT jOIN RoutingWorkflowDocuments rd   ON rd.DataStorageId = d.DataId
        LEFT JOIN RoutingWorkflowSignatures rs  ON rs.DataStorageId = d.DataId
        LEFT JOIN EmployeeShelfAccess esa       ON esa.DataStorageId = d.DataId
    WHERE fc.Id IS NULL
        AND rd.Id IS NULL
        AND rs.Id IS NULL
        AND esa.EmployeeId IS NULL

    UNION ALL

    SELECT [DBName] = 'FilesContent'
         , [Row]    = COUNT(1)
    FROM Drafts d
        JOIN FilesContent fs                            ON fs.Id = d.Id
        LEFT JOIN [TranscryptDataStorage].[dbo].Data dt ON dt.DataId = fs.DataStorageId
    WHERE d.UpdateDateTime < '2021-01-01'

    UNION ALL

    --подписи к файлам транзакций
    SELECT [DBName] = 'Signatures'
         , [Row]    = COUNT(1)
    FROM Transactions t 
       JOIN Files f                                     ON f.TransactionId = t.id
       JOIN Signatures s                                ON f.Id = s.FileId
       JOIN FilesContent fs                             ON s.Id = fs.Id
       LEFT JOIN [TranscryptDataStorage].[dbo].Data dt  ON dt.DataId = fs.DataStorageId
    WHERE t.CreateDate < '2021-01-01'

    UNION ALL

    --файлы транзакций
    SELECT [DBName] = 'Files'
         , [Row]    = COUNT(1)
    FROM Transactions t 
       JOIN Files f                                     ON f.TransactionId = t.id
       JOIN FilesContent fs                             ON fs.Id = f.Id
       LEFT JOIN [TranscryptDataStorage].[dbo].Data dt  ON dt.DataId = fs.DataStorageId
    WHERE t.CreateDate < '2021-01-01';

END
ELSE
BEGIN

    DECLARE @row   int
          , @count int
          , @start datetime;

    SELECT @row   = 25000
         , @start = GETDATE();

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

    WHILE @count > 0 AND (GETDATE() < DATEADD(HOUR, 6, @start))
    BEGIN
       DELETE FROM [TranscryptDataStorage].[dbo].Data 
       WHERE DataId IN (
           SELECT TOP (@row) d.DataId
           FROM [TranscryptDataStorage].[dbo].Data d 
               LEFT JOIN FilesContent fc              on fc.DataStorageId = d.DataId 
               LEFT jOIN RoutingWorkflowDocuments rd  on rd.DataStorageId = d.DataId
               LEFT JOIN RoutingWorkflowSignatures rs on rs.DataStorageId = d.DataId
               LEFT JOIN EmployeeShelfAccess esa      on esa.DataStorageId = d.DataId
       WHERE fc.Id IS NULL 
           AND rd.Id IS NULL 
           AND rs.Id IS NULL 
           AND esa.EmployeeId IS NULL
           )

       SET @count -= @row;
    END

    SELECT @count = COUNT(1)
    FROM Drafts d
        JOIN FilesContent fs                            ON fs.Id = d.Id
        LEFT JOIN [TranscryptDataStorage].[dbo].Data dt ON dt.DataId = fs.DataStorageId
    WHERE d.UpdateDateTime < '2021-01-01';

    WHILE @count > 0 AND (GETDATE() < DATEADD(HOUR, 6, @start))
    BEGIN
        DELETE FROM FilesContent
        WHERE Id IN (
            SELECT TOP(@row) fs.Id
            FROM Drafts d 
            JOIN FilesContent fs                            ON fs.Id = d.Id
            LEFT JOIN [TranscryptDataStorage].[dbo].Data dt ON dt.DataId = fs.DataStorageId
            WHERE d.UpdateDateTime < '2021-01-01'
            );

        SET @count -= @row;
    END

    DELETE FROM Signatures
    WHERE Id IN (
        SELECT s.Id
        FROM Transactions t 
            JOIN Files f                                    ON f.TransactionId=t.id
            JOIN Signatures s                               ON f.Id=s.FileId
            JOIN FilesContent fs                            ON s.Id= fs.Id
            LEFT JOIN [TranscryptDataStorage].[dbo].Data dt ON dt.DataId=fs.DataStorageId
        WHERE t.CreateDate < '2021-01-01'
        );

    DELETE Files
    WHERE Id IN (
        SELECT f.Id
        FROM Transactions t 
            JOIN Files f                                    ON f.TransactionId=t.id
            JOIN FilesContent fs                            ON fs.Id= f.Id
            LEFT JOIN [TranscryptDataStorage].[dbo].Data dt ON dt.DataId=fs.DataStorageId
        WHERE t.CreateDate < '2021-01-01'
        );

END