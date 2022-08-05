DECLARE 
      @dbname  NVARCHAR(30)
    , @dbfile  NVARCHAR(30)
    , @dbsize  INT
    , @shrink  NVARCHAR(30)
    , @command NVARCHAR(MAX)
    , @newline NVARCHAR(2)
    , @debug   NVARCHAR(1)
    ;

SELECT
      @dbname = 'tcryptapi_new'         -- Имя базы данных, файл которого будем сжимать
    , @dbfile = 'tcryptapi'             -- Имя конкретного файла БД, которую будет сжимать
    , @dbsize = 399360                  -- Целевой размер до которого нужно учесь файл БД, в мегабайтах
    , @shrink = 'SHRINK'                -- Виды операции усечения: NOTRUNCATE | TRUNCATEONLY | EMPTYFILE | SHRINK to size
    , @debug  = 'Y'                     -- Режим запуска скрипта: режим отладки (Y) | режим выполнения (N)
    ;

-- Составление динамисеской команды для запуска процедуры сжатия/усечения
SELECT
      @newline = NCHAR(13) + NCHAR(10)
    , @command = @newline + 'USE [' + @dbname + '];'
    ;

-- Перемещает данные из конца файла в начало и усекает файл до указанного размера
IF @shrink = 'SHRINK' AND @dbsize IS NOT NULL
BEGIN
    PRINT '######################';
    PRINT '# RUN SHRINK to size #';
    PRINT '######################';

    SET @command += @newline
        + 'DBCC SHRINKFILE (' + @dbfile + ', ' + CONVERT(NVARCHAR, @dbsize) + ');'
        ;
END

-- Перемещает данные из конца файла в начало, при наличии свободного места в начале файла
IF @shrink = 'NOTRUNCATE'
BEGIN
    PRINT '#########################';
    PRINT '# RUN SHRINK NOTRUNCATE #';
    PRINT '#########################';

    SET @command += @newline
        + 'DBCC SHRINKFILE (' + @dbfile + ', NOTRUNCATE);'
        ;
END

-- Усекает файл из свободного в конце файла пространства
IF @shrink = 'TRUNCATEONLY'
BEGIN
    PRINT '###########################';
    PRINT '# RUN SHRINK TRUNCATEONLY #';
    PRINT '###########################';

    SET @command += @newline
        + 'DBCC SHRINKFILE (' + @dbfile + ', TRUNCATEONLY);'
        ;
END

-- Переносит все данные из указанного файла в другие файлы в той же файловой группе
IF @shrink = 'EMPTYFILE'
BEGIN
    PRINT '########################';
    PRINT '# RUN SHRINK EMPTYFILE #';
    PRINT '########################';

    SET @command += @newline
        + 'DBCC SHRINKFILE (' + @dbfile + ', EMPTYFILE);'
        ;
END

IF @debug = 'Y'
    PRINT @command;
ELSE IF @debug = 'N'
    EXEC sp_executesql @command;