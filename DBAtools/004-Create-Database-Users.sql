/*######################
# Create database user #
######################*/

DECLARE 
	  @database	NVARCHAR(30)
	, @login	NVARCHAR(20)
	, @user		NVARCHAR(20)
    , @role     NVARCHAR(20)
    , @debug	NVARCHAR(1)
    ;

/*
    @database   - Имя ранее созданной БД в скрипте 001-Create-Database.sql
    
    @role       - Наименование роли базы данных
    @debug      - Режим запуска скрипта: режим отладки (Y) | режим выполнения (N)
*/

SELECT
	  @database	= 'DBAtools'
	, @login	= 'sqljob'
	, @user     = @login
    , @role     = 'job_executor'
	, @debug   	= 'Y'
	;
/*
    =====================================================================
*/

DECLARE 
	  @command  NVARCHAR(MAX)
    , @newline1 NVARCHAR(2)
    , @newline2 NVARCHAR(4)
    , @usedb    NVARCHAR(20)
    , @version  INT
    , @title    NVARCHAR(MAX)
    ;

SELECT
	  @command  = ''
    , @newline1 = NCHAR(13) + NCHAR(10)
    , @newline2 = @newline1 + @newline1
    , @version  = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'))
    , @title    = '# The target database ' + @database + ' does not exist #'
    ;


IF NOT EXISTS (SELECT 1 FROM sys.sysdatabases WHERE name = @database)
BEGIN
    PRINT REPLICATE('#', LEN(@title));
    PRINT @title;
    PRINT REPLICATE('#', LEN(@title));
    RETURN;
END

USE master;

SET @usedb = 'USE ' + DB_NAME() + ';';

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
    Добавляем пользователя @user в роль @role БД master, если роль существует и пользователь еще не является членом этой роли 
*/
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @role and type = 'R')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                        JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                        JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                    WHERE u.name = @user and r.name = @role)
    BEGIN
        SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                             WHEN LEN(@command) = 0                THEN @usedb + @newline2
                             ELSE @newline2 + @usedb + @newline2
                        END;
        
        IF @version > 10
            SET @command += 'ALTER ROLE [' + @role + '] ADD MEMBER [' + @user + '];';
        ELSE
            SET @command += 'EXEC sp_addrolemember ''' + @role + ''', ''' + @user + ''';';
    END
END


/*
=====================================================================
*/

USE DBAtools;   -- Изменить контекст выполнения БД на значение из переменной @database

SET @usedb = 'USE ' + DB_NAME() + ';';

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
    Проверяем существует ли роль @role в БД @database
*/
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @role and type = 'R')
BEGIN
    
    /*
        Добавляем пользователя @user в роль @role БД @database, если пользователь еще не является членоми этой роли
    */
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                        JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                        JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                    WHERE u.name = @user and r.name = @role)
    BEGIN
        SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                             WHEN LEN(@command) = 0                THEN @usedb + @newline2
                             ELSE @newline2 + @usedb + @newline2
                        END;

        IF @version > 10
            SET @command += 'ALTER ROLE [' + @role + '] ADD MEMBER [' + @user + '];';
        ELSE
            SET @command += 'EXEC sp_addrolemember ''' + @role + ''', ''' + @user + ''';';
    END

END


/*
=====================================================================
*/

USE msdb;

SET @usedb = 'USE msdb;';

/*
    Создаем пользователя @user в БД msdb, если он отсутствует, или привязываем существуещего пользовеля @user к логину @login 
*/
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

/*
    Проверяем существует ли роль @role в БД msdb
*/
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @role and type = 'R')
BEGIN

    /*
        Добавляем пользователя @user в роль @role БД msdb, если пользователь еще не является членоми этой роли
    */
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                        JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                        JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                    WHERE u.name = @user and r.name = @role)
    BEGIN
        SET @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                ELSE @newline2 + @usedb + @newline2
                        END;

        IF @version > 10
            SET @command += 'ALTER ROLE [' + @role + '] ADD MEMBER [' + @user + '];';
        ELSE
            SET @command += 'EXEC sp_addrolemember ''' + @role + ''', ''' + @user + ''';';
    END

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