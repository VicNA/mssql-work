DECLARE @dbfile NVARCHAR(30)
      , @dbsize INT
      , @shrink NVARCHAR(30)
      ;

SELECT @dbfile = 'TranscryptDataStorage'    -- имя конкретного файла БД
     , @dbsize = NULL                       -- целевой размер до которого нужно учесь файл БД, в мегабайтах
     , @shrink = 'NOTRUNCATE'               -- виды операции усечения: NOTRUNCATE | TRUNCATEONLY | EMPTYFILE | SHRINK to size

IF @shrink = 'SHRINK' AND @dbsize IS NOT NULL   -- перемещает данные из конца файла в начало и усекает файл до указанного размера
BEGIN
    PRINT 'RUN SHRINK to size';
    DBCC SHRINKFILE (@dbfile, @dbsize);
END

IF @shrink = 'NOTRUNCATE'                       -- перемещает данные из конца файла в начало, при наличии свободного места в начале файла
BEGIN
    PRINT 'RUN SHRINK NOTRUNCATE';
    DBCC SHRINKFILE (@dbfile, NOTRUNCATE);
END

IF @shrink = 'TRUNCATEONLY'                     -- усекает файл из свободного в конце файла пространства
BEGIN
    PRINT 'RUN SHRINK TRUNCATEONLY';
    DBCC SHRINKFILE (@dbfile, TRUNCATEONLY);
END

IF @shrink = 'EMPTYFILE'                        -- переносит все данные из указанного файла в другие файлы в той же файловой группе
BEGIN
    PRINT 'RUN SHRINK EMPTYFILE';
    DBCC SHRINKFILE (@dbfile, EMPTYFILE);
END