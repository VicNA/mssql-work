DECLARE 
      @database  NVARCHAR(30)
    , @directory NVARCHAR(255)
	, @dbfile    NVARCHAR(255)
    , @debug     NVARCHAR(1)
    ;

SELECT
      @database  = 'DBAtools'					-- Имя создаваемой БД
    , @directory = 'R:\Data'					-- Путь к каталогу, где будет распологаться БД
    , @dbfile    = @directory + '\' + @database	-- Полный путь к файлу БД
    , @debug     = 'Y'							-- Режим запуска скрипта: режим отладки (Y) | режим выполнения (N)
    ;
/*================================================*/

DECLARE 
      @command  NVARCHAR(MAX)
    , @usedb    NVARCHAR(20)
    , @newline1 NVARCHAR(2)
    , @newline2 NVARCHAR(4)
    ;

SELECT
      @command  = ''
    , @newline1 = NCHAR(13) + NCHAR(10)
    , @newline2 = @newline1 + @newline1
    
    ;

SET NOCOUNT ON;

USE master;

IF NOT EXISTS (SELECT 1 FROM sys.sysdatabases WHERE name = @database)
BEGIN
    SET @usedb = 'USE master;';

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
    
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
        + N'CREATE DATABASE [' + @database + ']';

    IF @directory IS NULL OR LEN(@directory) = 0
        SET @command += ';';
    ELSE
        SET @command += @newline1 + 'ON PRIMARY'
            + @newline1 + '( NAME = N''' + @database + ''', FILENAME = N''' + @dbfile  + '.mdf'', SIZE = 8192KB, FILEGROWTH = 65536KB )'
            + @newline1 + 'LOG ON'
            + @newline1 + '( NAME = N''' + @database + '_log'', FILENAME = N''' + @dbfile  + '_log.ldf'', SIZE = 8192KB, FILEGROWTH = 65536KB );';

    SET @command += @newline2 + 'ALTER DATABASE [' + @database + '] SET RECOVERY SIMPLE;' + @newline2
        + 'ALTER AUTHORIZATION ON DATABASE::' + @database +' TO [sa];';
    
    IF @debug = 'Y'
        PRINT @command;
    ELSE IF @debug = 'N'
        EXEC sp_executesql @command;
END