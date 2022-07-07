DECLARE @dbname    SYSNAME
      , @statement VARCHAR(MAX)
      , @command   VARCHAR(MAX)
      ;

SET @statement = '
USE [{DBNAME}];

SELECT [DBName]         = ''[{DBNAME}]''
     , [FileName]       = name
     --, [Allocated(MB)]  = CONVERT(decimal(10, 2), size / 128.0)
     , [Allocated]      = CASE 
                            WHEN (size / 128 / 1024 / 1024) > 0
                                THEN CONVERT(varchar(20), CONVERT(decimal(10, 2), size / 128.0 / 1024 / 1024)) + '' Tb''
                            WHEN (size / 128 / 1024) > 0
                                THEN CONVERT(varchar(20), CONVERT(decimal(10, 2), size / 128.0 / 1024)) + '' Gb''
                            ELSE
                                CONVERT(varchar(20), CONVERT(decimal(10, 2), size / 128.0)) + '' Mb''
                          END
     , [Used(MB)]       = CONVERT(decimal(10, 2), FILEPROPERTY(name, ''SpaceUsed'') / 128.0)
     , [Used]           = CASE 
                            WHEN (FILEPROPERTY(name, ''SpaceUsed'') / 128 / 1024 / 1024) > 0
                                THEN CONVERT(varchar(20), CONVERT(decimal(10, 2), FILEPROPERTY(name, ''SpaceUsed'') / 128.0 / 1024 / 1024)) + '' Tb''
                            WHEN (FILEPROPERTY(name, ''SpaceUsed'') / 128 / 1024) > 0
                                THEN CONVERT(varchar(20), CONVERT(decimal(10, 2), FILEPROPERTY(name, ''SpaceUsed'') / 128.0 / 1024)) + '' Gb''
                            ELSE
                                CONVERT(varchar(20), CONVERT(decimal(10, 2), FILEPROPERTY(name, ''SpaceUsed'') / 128.0 )) + '' Mb''
                          END
     --, [Available(MB)]  = CONVERT(decimal(10, 2), size / 128.0 - (FILEPROPERTY(name, ''SpaceUsed'') / 128.0))
     , [Available]      = CASE
                            WHEN ((size / 128 - (FILEPROPERTY(name, ''SpaceUsed'') / 128)) / 1024 / 1024) > 0
                                THEN CONVERT(varchar(20), CONVERT(decimal(10, 2), (size / 128.0 - (FILEPROPERTY(name, ''SpaceUsed'') / 128.0)) / 1024 / 1024)) + '' Tb''
                            WHEN ((size / 128 - (FILEPROPERTY(name, ''SpaceUsed'') / 128)) / 1024) > 0
                                THEN CONVERT(varchar(20), CONVERT(decimal(10, 2), (size / 128.0 - (FILEPROPERTY(name, ''SpaceUsed'') / 128.0)) / 1024 )) + '' Gb''
                            ELSE
                                CONVERT(varchar(20), CONVERT(decimal(10, 2), (size / 128.0 - (FILEPROPERTY(name, ''SpaceUsed'') / 128.0)))) + '' Mb''
                          END
     , PercentUsed      = CONVERT(decimal(10, 2), (FILEPROPERTY(name, ''SpaceUsed'') / 128.0) / (size / 128.0) * 100)
FROM sys.database_files
ORDER BY file_id DESC
';

PRINT @statement

DECLARE curDB CURSOR 
FORWARD_ONLY STATIC 
FOR 
    SELECT [name] 
    FROM master..sysdatabases
    -- список выбранных БД
    -- WHERE [name] IN (
    --     'DBAtools'
    --   , 'TranscryptDataStorage'
    --   , 'tcryptapi_new'

    -- )
    -- список исключающих БД
    WHERE [name] NOT IN ('master', 'tempdb', 'msdb', 'model', 'Baseline', 'DBAtools')
    ORDER BY [name]
    
OPEN curDB 

FETCH NEXT FROM curDB INTO @dbname 

WHILE @@FETCH_STATUS = 0 
BEGIN
    SET @command = REPLACE(@statement, '{DBNAME}', @dbname);

    EXEC (@command);

    FETCH NEXT FROM curDB INTO @dbname;

END

CLOSE curDB 
DEALLOCATE curDB;