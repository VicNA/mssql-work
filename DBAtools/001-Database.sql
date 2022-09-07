/*#################
# Create Database #
#################*/

DECLARE 
      @database     NVARCHAR(30)
    , @directory    NVARCHAR(255)
	, @pathToFile   NVARCHAR(255)
    , @debug        NVARCHAR(1)
    ;

/*
    @database   - Имя создаваемой БД
    @directory  - Путь к каталогу, где будет распологаться БД. Если значение не указано, будет использоваться путь по умолчанию для новых БД.
    @pathToFile - Полный путь к файлу БД
    @debug      - Режим запуска скрипта: режим отладки (Y) | режим выполнения (N)
*/

SELECT
      @database   = 'DBAtools'
    , @directory  = 'R:\Data'
    , @pathToFile = @directory + '\' + @database
    , @debug      = 'Y'
    ;
/*============================================================================================*/

DECLARE 
      @command  NVARCHAR(MAX)
    , @usedb    NVARCHAR(20)
    , @newline1 NVARCHAR(2)
    , @newline2 NVARCHAR(4)
    , @title    NVARCHAR(MAX)
    ;

SELECT
      @command  = ''
    , @newline1 = NCHAR(13) + NCHAR(10)
    , @newline2 = @newline1 + @newline1
    , @title    = '# The target database ' + @database + ' already exists #'
    ;


SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM sys.sysdatabases WHERE name = @database)
BEGIN
    PRINT REPLICATE('#', LEN(@title));
    PRINT @title;
    PRINT REPLICATE('#', LEN(@title));
    RETURN;
END

USE master;

SET @usedb = 'USE ' + DB_NAME() + ';';

/*
    Создаем каталог, в которой будет распологаться БД @database, если указано значение переменной @directory
*/
IF LEN(ISNULL(@directory, '')) > 0
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
        + 'EXEC sp_configure ''show advanced option'', 1;' + @newline1
        + 'RECONFIGURE WITH OVERRIDE;' + @newline1
        + 'EXEC sp_configure ''xp_cmdshell'', 1;' + @newline1
        + 'RECONFIGURE;' + @newline2
        + 'EXEC xp_cmdshell ''if not exist "' + @directory + '" ( mkdir ' + @directory + ' )'', no_output;' + @newline2
        + 'EXEC sp_configure ''xp_cmdshell'', 0;' + @newline1
        + 'RECONFIGURE;' + @newline1
        + 'EXEC sp_configure ''show advanced option'', 0;' + @newline1
        + 'RECONFIGURE WITH OVERRIDE;';

/*
    Создаем БД @database
*/
SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
    + N'CREATE DATABASE [' + @database + ']';

IF @directory IS NULL OR LEN(@directory) = 0
    SET @command += ';';
ELSE
    SET @command += @newline1 + 'ON PRIMARY'
        + @newline1 + '( NAME = N''' + @database + ''', FILENAME = N''' + @pathToFile  + '.mdf'', SIZE = 8192KB, FILEGROWTH = 65536KB )'
        + @newline1 + 'LOG ON'
        + @newline1 + '( NAME = N''' + @database + '_log'', FILENAME = N''' + @pathToFile  + '_log.ldf'', SIZE = 8192KB, FILEGROWTH = 65536KB );';

/*
    Настраиваем дополнительные параметры БД @database:
        - модель восстановление: SIMPLE
        - владелец БД: sa
*/
SET @command += @newline2 + 'ALTER DATABASE [' + @database + '] SET RECOVERY SIMPLE;' + @newline2
    + 'ALTER AUTHORIZATION ON DATABASE::' + @database +' TO [sa];';

IF @debug = 'Y'
BEGIN
    PRINT '################';
    PRINT '# DEBUG SCRIPT #';
    PRINT '################';
    PRINT @newline1 + @command;
END
ELSE IF @debug = 'N'
    EXEC sp_executesql @command;