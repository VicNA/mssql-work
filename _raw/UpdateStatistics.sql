DECLARE @dbname  SYSNAME
      , @command VARCHAR(MAX) 

DECLARE curDB CURSOR 
FORWARD_ONLY STATIC 
FOR 
   SELECT [name] 
   FROM master..sysdatabases
   WHERE [name] IN ('tcryptapi_new')
   --WHERE [name] IN ('tcryptapi_new', 'TranscryptDataStorage')
   --where [name] not in ('Baseline', 'DBAtools', 'master', 'model', 'msdb', 'tempdb')
   ORDER BY [name]
    
OPEN curDB 

FETCH NEXT FROM curDB INTO @dbname 

WHILE @@FETCH_STATUS = 0 
BEGIN 
    SELECT @command = 'USE [' + @dbname + ']' + CHAR(13) + 'EXEC sp_updatestats' + CHAR(13);
       
    PRINT @command;
       
    EXEC (@command);
       
    FETCH NEXT FROM curDB INTO @dbname 
END 
   
CLOSE curDB 
DEALLOCATE curDB