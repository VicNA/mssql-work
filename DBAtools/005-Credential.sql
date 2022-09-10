DECLARE 
	  @database		NVARCHAR(30)
	, @login		NVARCHAR(20)
	, @cred         NVARCHAR(20)
	, @creduser		NVARCHAR(20)
    , @credpass     NVARCHAR(20)
    , @debug		NVARCHAR(1)
    ;

SELECT
	  @database		= 'DBAtools'
	, @login		= 'sqljob'
	, @creduser     = @login
    , @credpass     = ''
	, @debug   	    = 'Y'
	;
/*====================================================*/

DECLARE 
	  @command  NVARCHAR(MAX)
    , @usedb    NVARCHAR(20)
    , @newline1 NVARCHAR(2)
    , @newline2 NVARCHAR(4)
    , @domain   NVARCHAR(20)
    , @cmdline  NVARCHAR(MAX)
    ;

SELECT
	  @command  = ''
    , @newline1 = NCHAR(13) + NCHAR(10)
    , @newline2 = @newline1 + @newline1
    , @cmdline = 'powershell -command "(Get-CimInstance -ClassName CIM_System).DomainName"';
    ;

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM sys.sysdatabases WHERE name = @database)
BEGIN

    USE master;

    SET @usedb = 'USE ' + DB_NAME() + ';'; -- Отступ присутствует из-за сообщений "Configuration option ..."

    /* 
        Создаем учетные данные внутри SQL Server, которая идентифицируется с учетной записью домена или локальной машины 
    */
    IF NOT EXISTS (SELECT * FROM sys.credentials WHERE name = @login)
    BEGIN
        DECLARE @cmdout TABLE (id INT IDENTITY(1,1), string NVARCHAR(15));

        EXEC sp_configure 'show advanced option', 1;
        RECONFIGURE WITH OVERRIDE;
        EXEC sp_configure 'xp_cmdshell', 1;
        RECONFIGURE;

        SELECT 
              @cmdline = 'powershell -command "(Get-CimInstance -ClassName CIM_System).DomainName"'
            , @cmdline = 'EXEC master..xp_cmdshell ''' + @cmdline + ''';';

        INSERT @cmdout (string)
        EXEC sp_executesql @cmdline;

        EXEC sp_configure 'xp_cmdshell', 0;
        RECONFIGURE;
        EXEC sp_configure 'show advanced option', 0;
        RECONFIGURE WITH OVERRIDE;

        SELECT @domain = string
        FROM @cmdout
        WHERE id = 1;

        SET @cred = CASE WHEN @domain IS NULL THEN @creduser ELSE @domain + '\' + @creduser END;

        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE CREDENTIAL [' + @login + '] WITH IDENTITY = N''' + @cred + ''', SECRET = N''' + @credpass + ''';';
    END
   
    IF @debug = 'Y'
    BEGIN
        PRINT '################';
        PRINT '# DEBUG SCRIPT #';
        PRINT '################';
        PRINT @newline1 + @command;
    END
    ELSE IF @debug = 'N'
        EXEC sp_executesql @command;

END