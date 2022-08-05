DECLARE
	  @database     NVARCHAR(30)
	, @serverRole   NVARCHAR(20)
    , @databaseRole NVARCHAR(20)
    , @debug        NVARCHAR(1) 
    ;

SELECT
	  @database		= 'DBAtools'
	, @serverRole	= 'job_executor'	-- Наименование серверной роли
	, @databaseRole = @serverRole	    -- Наименование роли базы данных
	, @debug		= 'Y'				-- Режим запуска скрипта: режим отладки (Y) | режим выполнения (N)
/*===============================================*/

DECLARE 
	  @sysrole  NVARCHAR(20)
    , @usedb    NVARCHAR(20)
    , @version  INT
    , @command  NVARCHAR(MAX)
    , @newline1 NVARCHAR(2)
    , @newline2 NVARCHAR(4)
    ;

SELECT 
       @version  = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'))
	 , @command  = ''
     , @newline1 = NCHAR(13) + NCHAR(10)
     , @newline2 = @newline1 + @newline1
     ;

IF EXISTS (SELECT 1 FROM sys.sysdatabases WHERE name = @database)
BEGIN

BEGIN TRY
    
    USE master;

    SET @usedb = 'USE master;';
        
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE ROLE [' + @databaseRole + '];';

    IF @version > 10
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @serverRole AND type = 'R')
            SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
				+ 'CREATE SERVER ROLE [' + @serverRole + '] AUTHORIZATION [sa];';
    END

    
    USE DBAtools;

    SET @usedb = 'USE ' + @database + ';';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE ROLE [' + @databaseRole + '];';

    SET @sysrole = 'db_datawriter';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                        JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                        JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                   WHERE u.name = @databaseRole and r.name = @sysrole)
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END;

        IF @version > 10
            SET @command += 'ALTER ROLE [' + @sysrole + '] ADD MEMBER [' + @databaseRole + '];';
        ELSE
            SET @command += 'EXEC sp_addrolemember ''' + @sysrole + ''', ''' + @databaseRole + ''';';
    END


    USE msdb;

    SET @usedb = 'USE msdb;';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE ROLE [' + @databaseRole + '];';
    
    SET @sysrole = 'db_datareader';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                        JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                        JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                   WHERE u.name = @databaseRole and r.name = @sysrole)
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END;

        IF @version > 10
            SET @command += 'ALTER ROLE [' + @sysrole + '] ADD MEMBER [' + @databaseRole + '];';
        ELSE
            SET @command += 'EXEC sp_addrolemember ''' + @sysrole + ''', ''' + @databaseRole + ''';';
    END

    SET @sysrole = 'SQLAgentUserRole';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                        JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                        JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                   WHERE u.name = @databaseRole and r.name = @sysrole)
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END;

        IF @version > 10
            SET @command += 'ALTER ROLE [' + @sysrole + '] ADD MEMBER [' + @databaseRole + '];';
        ELSE
            SET @command += 'EXEC sp_addrolemember ''' + @sysrole + ''', ''' + @databaseRole + ''';';
    END

    IF @debug = 'Y'
        PRINT @command;
    ELSE IF @debug = 'N'
        EXEC sp_executesql @command;

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage  NVARCHAR(4000)
		  , @ErrorSeverity INT
		  , @ErrorState	   INT;

    SELECT @ErrorMessage  = ERROR_MESSAGE()
         , @ErrorSeverity = ERROR_SEVERITY()
         , @ErrorState    = ERROR_STATE();

    RAISERROR (@ErrorMessage,	-- Message text.
               @ErrorSeverity,	-- Severity.
               @ErrorState		-- State.
               );
END CATCH

END