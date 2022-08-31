DECLARE 
	  @database		NVARCHAR(30)
	, @login		NVARCHAR(20)
    , @password		NVARCHAR(20)
    , @sid			NVARCHAR(MAX)
	, @user			NVARCHAR(20)
	, @cred         NVARCHAR(20)
	, @creduser		NVARCHAR(20)
    , @domain       NVARCHAR(20)
    , @credpass     NVARCHAR(20)
    , @serverRole   NVARCHAR(20)
    , @databaseRole NVARCHAR(20)
    , @debug		NVARCHAR(1)
    , @viewSID		NVARCHAR(1)
    ;

SELECT
	  @database		= 'DBAtools'
	, @login		= 'sqljob'
	, @password		= 'HcRGTxAec8DYjxmUu5LY'
	, @sid     		= NULL
	, @user         = @login
	, @creduser     = @login
    , @domain       = 'OFFICE'
    , @credpass     = 'Bf066eo'
    , @serverRole   = 'job_executor'
    , @databaseRole = @serverRole
	, @debug   	    = 'Y'
	, @viewSID 	    = 'N'
	;
/*====================================================*/

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

IF EXISTS (SELECT 1 FROM sys.sysdatabases WHERE name = @database)
BEGIN

    USE master;

    SET @usedb = @newline1 + 'USE master;'; -- Отступ присутствует из-за сообщений "Configuration option ..."

    /* 
        Создаем логин @login типа SQL, если он отсутствует 
    */
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @login AND type = 'S')
    BEGIN
        SET @command += @usedb + @newline2
			+ 'CREATE LOGIN [' + @login + '] WITH PASSWORD = N''' + @password + ''''
			+ CASE WHEN @sid IS NULL THEN ';' ELSE ', SID = ' + @sid + ';' END;
    END

    /* 
        Добавляем логин @login в серверную роль @serverRole, если роль существует и логин еще не является членом этой роли 
    */
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @serverRole AND type = 'R')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.server_principals r
                            JOIN sys.server_role_members m ON m.role_principal_id = r.principal_id
                            JOIN sys.server_principals l   ON l.principal_id = m.member_principal_id
                       WHERE l.name = @login and r.name = @serverRole)
        BEGIN
            SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
				+ 'ALTER SERVER ROLE [' + @serverRole + '] ADD MEMBER [' + @login + '];';
        END
    END

    /* 
        Создаем пользователя @user в БД master, если он отсутствует, или привязываем существуещего пользовеля @user к логину @login 
    */
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @user and type = 'S')
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE USER [' + @user + '] FOR LOGIN [' + @user + '];';
    END
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.syslogins l JOIN sys.sysusers u ON u.sid = l.sid WHERE l.name = @login)
        BEGIN
            SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
								 WHEN LEN(@command) = 0                THEN @usedb + @newline2
								 ELSE @newline2 + @usedb + @newline2
                            END
				+ 'ALTER USER [' + @user + '] WITH LOGIN = [' + @login + '];'
        END
    END

    /* 
        Добавляем пользователя @user в роль @databaseRole БД master, если роль существует и пользователь еще не является членом этой роли 
    */
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
        
        INSERT @cmdout (string)
        EXEC sp_executesql N'EXEC master..xp_cmdshell ''wmic.exe ComputerSystem get PartOfDomain'';';

        EXEC sp_configure 'xp_cmdshell', 0;
        RECONFIGURE;
        EXEC sp_configure 'show advanced option', 0;
        RECONFIGURE WITH OVERRIDE;

        IF (SELECT CONVERT(bit, REPLACE(REPLACE(string, '  ', ''), NCHAR(13), '')) FROM @cmdout WHERE id = 2) != 0
            SET @cred =  @domain + '\' + @creduser;
        ELSE
            SET @cred = @creduser;

        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE CREDENTIAL [' + @login + '] WITH IDENTITY = N''' + @cred + ''', SECRET = N''' + @credpass + ''';';
    END


    USE DBAtools;   -- Изменить контекст выполнения БД на значение из переменной @database

    SET @usedb = 'USE ' + @database + ';';

    /* 
        Создаем пользователя @user в БД @database, если он отсутствует, или привязываем существуещего пользовеля @user к логину @login 
    */
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @user and type = 'S')
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE USER [' + @user + '] FOR LOGIN [' + @user + '];';
    END
    ELSE
        IF NOT EXISTS (SELECT 1 FROM sys.syslogins l JOIN sys.sysusers u ON u.sid = l.sid WHERE l.name = @login)
        BEGIN
            SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                 WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                 ELSE @newline2 + @usedb + @newline2
                            END
				+ 'ALTER USER [' + @user + '] WITH LOGIN = [' + @login + '];'
        END

    /*
        Добавляем пользователя @user в роли БД @database @databaseRole, если роль существует, и "db_datawriter", 
        если пользователь еще не является членоми этих ролей 
    */
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
        DECLARE
	  @database     NVARCHAR(30)
	, @serverRole   NVARCHAR(20)
    , @databaseRole NVARCHAR(20)
    , @debug        NVARCHAR(1) 
    ;

/*
    @database     - Имя ранее созданной БД в скрипте 001-Create-Database.sql
    @serverRole   - Наименование серверной роли
    @databaseRole - Наименование роли базы данных
    @debug        - Режим запуска скрипта: режим отладки (Y) | режим выполнения (N)
*/

SELECT
	  @database		= 'DBAtools'
	, @serverRole	= 'job_executor'
	, @databaseRole = @serverRole
	, @debug		= 'Y'
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

    USE master;

    SET @usedb = 'USE master;';
    
    /*
        Создаем роль @databaseRole в БД master, если она отстутствует
    */
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE ROLE [' + @databaseRole + '];';

    /*
        Создаем серверную роль @serverRole, если она отстутствует. Применимо начинай SQL Server 2012
    */
    IF @version > 10
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @serverRole AND type = 'R')
            SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
				+ 'CREATE SERVER ROLE [' + @serverRole + '] AUTHORIZATION [sa];';
    END

    
    USE DBAtools;   -- Изменить контекст выполнения БД на значение из переменной @database

    SET @usedb = 'USE ' + @database + ';';

    /*
        Создаем роль @databaseRole в БД @database, если она отстутствует
    */
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE ROLE [' + @databaseRole + '];';

    /*
        Добавляем роль @databaseRole в роль "db_datawriter" в БД @database
    */
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

    /*
        Создаем роль @databaseRole в БД msdb, если она отстутствует
    */
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE ROLE [' + @databaseRole + '];';
    
    /*
        Добавляем роль @databaseRole в роль "db_datareader" в БД msdb
    */
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

    /*
        Добавляем роль @databaseRole в роль "SQLAgentUserRole" в БД msdb
    */
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
        BEGIN
        PRINT '################';
        PRINT '# DEBUG SCRIPT #';
        PRINT '################';
        PRINT @command;
    END
    ELSE IF @debug = 'N'
        EXEC sp_executesql @command;

END
    ELSE IF @debug = 'N'
        EXEC sp_executesql @command;

    IF @viewSID = 'Y'
        SELECT name, sid
        FROM sys.syslogins
        WHERE name = @login;

END