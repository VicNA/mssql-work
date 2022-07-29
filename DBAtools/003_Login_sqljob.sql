SET NOCOUNT ON;

/*====================================================*/
DECLARE @login    NVARCHAR(20)  = 'sqljob'
      , @password NVARCHAR(20)  = 'HcRGTxAec8DYjxmUu5LY'
      , @sid      NVARCHAR(MAX) = NULL
      , @debug    NVARCHAR(1)   = 'Y'
      , @viewSID  NVARCHAR(1)   = 'N'
      ;
/*====================================================*/

/*====================================================*/

DECLARE @user         NVARCHAR(20)
      , @cred         NVARCHAR(20)
      , @domain       NVARCHAR(20)
      , @credpass     NVARCHAR(20)
      , @serverRole   NVARCHAR(20)
      , @databaseRole NVARCHAR(20)
      ;

SELECT @user         = @login
     , @domain       = 'OFFICE'
     , @credpass     = 'Bf066eo'
     , @serverRole   = 'job_executor'
     , @databaseRole = 'job_executor'
     ;
/*====================================================*/

DECLARE @command  NVARCHAR(MAX)
      , @usedb    NVARCHAR(20)
      , @newline1 NVARCHAR(2)
      , @newline2 NVARCHAR(4)
      ;

SELECT @command  = ''
     , @newline1 = NCHAR(13) + NCHAR(10)
     , @newline2 = @newline1 + @newline1
     ;

BEGIN TRY
    
    USE master;

    SET @usedb = @newline1 + 'USE master;';

    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @login and type = 'S')
    BEGIN
        SET @command += @usedb + @newline2;

        IF @sid IS NULL
            SET @command += 'CREATE LOGIN [' + @login + '] WITH PASSWORD = N''' + @password + ''';';
        ELSE
            SET @command += 'CREATE LOGIN [' + @login + '] WITH PASSWORD = N''' + @password + ''', SID = ' + @sid + ';';
    END

    IF EXISTS(SELECT 1 FROM sys.server_principals WHERE name = @serverRole AND type = 'R')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.server_principals r
                            JOIN sys.server_role_members m ON m.role_principal_id = r.principal_id
                            JOIN sys.server_principals l   ON l.principal_id = m.member_principal_id
                       WHERE l.name = @login and r.name = @serverRole)
        BEGIN
            SELECT @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
                 , @command += 'ALTER SERVER ROLE [' + @serverRole + '] ADD MEMBER [' + @login + '];';
        END
    END

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @user and type = 'S')
    BEGIN
        SELECT @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
             , @command += 'CREATE USER [' + @user + '] FOR LOGIN [' + @user + '];';
    END
    ELSE
        IF NOT EXISTS (SELECT 1 FROM sys.syslogins l JOIN sys.sysusers u ON u.sid = l.sid WHERE l.name = @login)
        BEGIN
            SELECT @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                    WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                    ELSE @newline2 + @usedb + @newline2
                               END
                 , @command += 'ALTER USER [' + @user + '] WITH LOGIN = [' + @login + '];'
        END

    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                            JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                            JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                       WHERE u.name = @user and r.name = @databaseRole)
        BEGIN
            SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                 WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                 ELSE @newline2 + @usedb + @newline2
                            END;

            IF CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) > 10
                SET @command += 'ALTER ROLE [' + @databaseRole + '] ADD MEMBER [' + @user + '];';
            ELSE
                SET @command += 'EXEC sp_addrolemember ''' + @databaseRole + ''', ''' + @user + ''';';
        END
    END

    IF NOT EXISTS (SELECT * FROM sys.credentials WHERE name = @login)
    BEGIN
        DECLARE @cmdout TABLE (id INT IDENTITY(1,1), string NVARCHAR(MAX));

        EXEC sp_configure 'show advanced option', 1;
        RECONFIGURE WITH OVERRIDE;
        EXEC sp_configure 'xp_cmdshell', 1;
        RECONFIGURE;
        
        INSERT @cmdout (string)
        EXEC sp_executesql N'EXEC master..xp_cmdshell ''wmic.exe ComputerSystem get PartOfDomain'';';

        EXEC sp_configure 'xp_cmdshell', 0;
        RECONFIGURE;
        EXEC sp_configure 'show advanced option', 0;
        RECONFIGURE WITH OVERRIDE;

        IF (SELECT CONVERT(bit, REPLACE(REPLACE(string, '  ', ''), NCHAR(13), '')) FROM @cmdout WHERE id = 2) != 0
            SET @cred =  @domain + '\' + @login;
        ELSE
            SET @cred = @login;

        SELECT @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
             , @command += 'CREATE CREDENTIAL [' + @login + '] WITH IDENTITY = N''' + @cred + ''', SECRET = N''' + @credpass + ''';';
    END


    USE DBAtools;

    SET @usedb = 'USE DBAtools;';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @user and type = 'S')
    BEGIN
        SELECT @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
             , @command += 'CREATE USER [' + @user + '] FOR LOGIN [' + @user + '];';
    END
    ELSE
        IF NOT EXISTS (SELECT 1 FROM sys.syslogins l JOIN sys.sysusers u ON u.sid = l.sid WHERE l.name = @login)
        BEGIN
            SELECT @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                    WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                    ELSE @newline2 + @usedb + @newline2
                               END
                 , @command += 'ALTER USER [' + @user + '] WITH LOGIN = [' + @login + '];'
        END

    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                            JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                            JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                       WHERE u.name = @user and r.name = @databaseRole)
        BEGIN
            SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                 WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                 ELSE @newline2 + @usedb + @newline2
                            END;

            IF CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) > 10
                SET @command += 'ALTER ROLE [' + @databaseRole + '] ADD MEMBER [' + @user + '];';
            ELSE
                SET @command += 'EXEC sp_addrolemember ''' + @databaseRole + ''', ''' + @user + ''';';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                            JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                            JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                       WHERE u.name = @databaseRole and r.name = 'db_datawriter')
        BEGIN
            SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                 WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                 ELSE @newline2 + @usedb + @newline2
                            END;

            IF CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) > 10
                SET @command += 'ALTER ROLE [' + @databaseRole + '] ADD MEMBER [' + @user + '];';
            ELSE
                SET @command += 'EXEC sp_addrolemember ''db_datareader'', ''' + @databaseRole + ''';';
        END
    END

    
    USE msdb;

    SET @usedb = 'USE msdb;';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @user and type = 'S')
    BEGIN
        SELECT @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
             , @command += 'CREATE USER [' + @user + '] FOR LOGIN [' + @user + '];';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.syslogins l JOIN sys.sysusers u ON u.sid = l.sid WHERE l.name = @login)
    BEGIN
        SELECT @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                ELSE @newline2 + @usedb + @newline2
                           END
             , @command += 'ALTER USER [' + @user + '] WITH LOGIN = [' + @login + '];'
    END

    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                            JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                            JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                       WHERE u.name = @user and r.name = @databaseRole)
        BEGIN
            SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                 WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                 ELSE @newline2 + @usedb + @newline2
                            END;

            IF CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) > 10
                SET @command += 'ALTER ROLE [' + @databaseRole + '] ADD MEMBER [' + @user + '];';
            ELSE
                SET @command += 'EXEC sp_addrolemember ''' + @databaseRole + ''', ''' + @user + ''';';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                            JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                            JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                       WHERE u.name = @databaseRole and r.name = 'db_datareader')
        BEGIN
            SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                 WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                 ELSE @newline2 + @usedb + @newline2
                            END;

            IF CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) > 10
                SET @command += 'ALTER ROLE [' + @databaseRole + '] ADD MEMBER [' + @user + '];';
            ELSE
                SET @command += 'EXEC sp_addrolemember ''db_datareader'', ''' + @databaseRole + ''';';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                            JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                            JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                       WHERE u.name = @databaseRole and r.name = 'SQLAgentUserRole')
        BEGIN
            SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                 WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                 ELSE @newline2 + @usedb + @newline2
                            END;

            IF CONVERT(int, SERVERPROPERTY('ProductMajorVersion')) > 10
                SET @command += 'ALTER ROLE [' + @databaseRole + '] ADD MEMBER [' + @user + '];';
            ELSE
                SET @command += 'EXEC sp_addrolemember ''SQLAgentUserRole'', ''' + @databaseRole + ''';';
        END
    END

    IF @debug = 'Y'
        PRINT @command;
    ELSE IF @debug = 'N'
        EXEC sp_executesql @command;

    IF @viewSID = 'Y'
        SELECT name, sid
        FROM sys.syslogins
        WHERE name = @login;

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage  NVARCHAR(4000)
		  , @ErrorSeverity INT
		  , @ErrorState	   INT;

    SELECT @ErrorMessage  = ERROR_MESSAGE()
         , @ErrorSeverity = ERROR_SEVERITY()
         , @ErrorState    = ERROR_STATE();

    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
END CATCH