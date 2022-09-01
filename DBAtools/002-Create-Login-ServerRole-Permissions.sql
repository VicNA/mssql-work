/*##############################################################################################
# Creating a login and server role, adding a participant to the role and assigning permissions #
##############################################################################################*/
/* 
    Для выполнения задач по обслуживанию БД вцелом необходимы права:
    - VIEW ANY DATABASE

    Для выполнения задач конкретно проверок целостности БД:
    - VIEW SERVER STATE
    - VIEW DATABASE STATE (DBAtools)
*/

DECLARE
	  @database NVARCHAR(30)
    , @login	NVARCHAR(20)
    , @password	NVARCHAR(20)
    , @sid		NVARCHAR(MAX)
	, @role     NVARCHAR(20)
    , @debug    NVARCHAR(1) 
    ;

/*
    @database   - Имя ранее созданной БД в скрипте 001-Create-Database.sql
    @login      - Имя создаваемого логина
    @password   - Пароль для создаваемого логина
    @sid        - Присваемый идентификатор логина. Требуется для режимов отказоустойчивости
    @role       - Наименование серверной роли
    @debug      - Режим запуска скрипта: режим отладки (Y) | режим выполнения (N)
*/

SELECT
	  @database	= 'DBAtools'
    , @login	= 'sqljob'
	, @password	= ''
	, @sid     	= ''
	, @role	    = 'job_executor'
	, @debug	= 'Y'
/*===============================================*/

DECLARE 
      @command  NVARCHAR(MAX)
    , @newline1 NVARCHAR(2)
    , @newline2 NVARCHAR(4)
	, @usedb    NVARCHAR(20)
    , @perm     NVARCHAR(20)
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
    Создаем логин @login типа SQL, если он отсутствует 
*/
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @login AND type = 'S')
BEGIN
    SET @command += @usedb + @newline2
        + 'CREATE LOGIN [' + @login + '] WITH PASSWORD = N''' + @password + ''''
        + CASE WHEN @sid IS NULL THEN ';' ELSE ', SID = ' + @sid + ';' END;
END

/*
    Создаем серверную роль @role, если она отстутствует. Применимо начинай SQL Server 2012
*/
IF @version > 10
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @role AND type = 'R')
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
			+ 'CREATE SERVER ROLE [' + @role + '] AUTHORIZATION [sa];';
    /* 
        Добавляем логин @login в серверную роль @role, если логин не является членом этой роли 
    */
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals r
                        JOIN sys.server_role_members m ON m.role_principal_id = r.principal_id
                        JOIN sys.server_principals l   ON l.principal_id = m.member_principal_id
                    WHERE l.name = @login and r.name = @role)
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
            + 'ALTER SERVER ROLE [' + @role + '] ADD MEMBER [' + @login + '];';
    END

    SET @perm = 'VIEW ANY DATABASE';
    
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals pr
                            JOIN sys.server_permissions pe ON pr.principal_id = pe.grantee_principal_id
                        WHERE pr.name = @role AND pe.permission_name = @perm)
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
            + 'GRANT ' + @perm + ' TO [' + @role + '];';
    END
    
    SET @perm = 'VIEW SERVER STATE';

    IF NOT EXISTS (SELECT 1 FROM sys.server_principals pr
                        JOIN sys.server_permissions pe ON pr.principal_id = pe.grantee_principal_id
                    WHERE pr.name = @role AND pe.permission_name = @perm)
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
            + 'GRANT ' + @perm + ' TO [' + @role + '];';
    END

END
ELSE
BEGIN
    
    SET @perm = 'VIEW ANY DATABASE';

    IF NOT EXISTS (SELECT 1 FROM sys.server_principals pr
                        JOIN sys.server_permissions pe ON pr.principal_id = pe.grantee_principal_id
                    WHERE pr.name = @login AND pe.permission_name = @perm)
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
            + 'GRANT ' + @perm + ' TO [' + @login + '];';
    END

    SET @perm = 'VIEW SERVER STATE';

    IF NOT EXISTS (SELECT 1 FROM sys.server_principals pr
                        JOIN sys.server_permissions pe ON pr.principal_id = pe.grantee_principal_id
                    WHERE pr.name = @login AND pe.permission_name = @perm)
    BEGIN
        SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
            + 'GRANT ' + @perm + ' TO [' + @login + '];';
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