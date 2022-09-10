/*#######################
# Create database roles #
#######################*/

DECLARE
	  @database NVARCHAR(30)
    , @role     NVARCHAR(20)
    , @debug    NVARCHAR(1) 
    ;

/*
    @database   - Имя ранее созданной БД в скрипте 001-Create-Database.sql
    @role       - Наименование роли базы данных
    @debug      - Режим запуска скрипта: режим отладки (Y) | режим выполнения (N)
*/

SELECT
	  @database	= 'DBAtools'
	, @role     = 'job_executor'
	, @debug	= 'Y'
    ;
/*============================================================================================*/

DECLARE 
      @command  NVARCHAR(MAX)
    , @newline1 NVARCHAR(2)
    , @newline2 NVARCHAR(4)
    , @usedb    NVARCHAR(20)
	, @sysrole  NVARCHAR(20)
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
    Создаем роль @role в БД master, если она отстутствует
*/
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @role and type = 'R')
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
		+ 'CREATE ROLE [' + @role + '];';

    
USE DBAtools;   -- Изменить контекст выполнения БД на значение из переменной @database

SET @usedb = 'USE ' + DB_NAME() + ';';

/*
    Создаем роль @role в БД @database, если она отстутствует
*/
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @role and type = 'R')
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
		+ 'CREATE ROLE [' + @role + '];';

/*
    Добавляем роль @role в роль "db_datawriter" в БД @database
*/
SET @sysrole = 'db_datawriter';

IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                    JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                    JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                WHERE u.name = @role and r.name = @sysrole)
BEGIN
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END;

    IF @version > 10
        SET @command += 'ALTER ROLE [' + @sysrole + '] ADD MEMBER [' + @role + '];';
    ELSE
        SET @command += 'EXEC sp_addrolemember ''' + @sysrole + ''', ''' + @role + ''';';
END

/* 
    Добавляем разрешение 'VIEW DATABASE STATE' в роль @role, если этого разрешения еще нет
    (Для выполнения задач конкретно проверок целостности БД)
*/
SET @perm = 'VIEW DATABASE STATE';

IF NOT EXISTS (SELECT 1 FROM sys.database_principals pr
                    JOIN DBAtools.sys.database_permissions per ON per.grantee_principal_id = pr.principal_id
                WHERE pr.name = @role AND per.permission_name = @perm)
BEGIN
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
        + 'GRANT ' + @perm + ' TO [' + @role + '];';
END


USE msdb;

SET @usedb = 'USE ' + DB_NAME() + ';';

/*
    Создаем роль @role в БД msdb, если она отстутствует
*/
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @role and type = 'R')
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @usedb + @newline2 ELSE @usedb + @newline2 END
		+ 'CREATE ROLE [' + @role + '];';
    
/*
    Добавляем роль @role в роль "db_datareader" в БД msdb
*/
SET @sysrole = 'db_datareader';

IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                    JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                    JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                WHERE u.name = @role and r.name = @sysrole)
BEGIN
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END;

    IF @version > 10
        SET @command += 'ALTER ROLE [' + @sysrole + '] ADD MEMBER [' + @role + '];';
    ELSE
        SET @command += 'EXEC sp_addrolemember ''' + @sysrole + ''', ''' + @role + ''';';
END

/*
    Добавляем роль @role в роль "SQLAgentUserRole" в БД msdb
*/
SET @sysrole = 'SQLAgentUserRole';

IF NOT EXISTS (SELECT 1 FROM sys.database_principals r
                    JOIN sys.database_role_members m ON m.role_principal_id = r.principal_id
                    JOIN sys.database_principals u   ON u.principal_id = m.member_principal_id
                WHERE u.name = @role and r.name = @sysrole)
BEGIN
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END;

    IF @version > 10
        SET @command += 'ALTER ROLE [' + @sysrole + '] ADD MEMBER [' + @role + '];';
    ELSE
        SET @command += 'EXEC sp_addrolemember ''' + @sysrole + ''', ''' + @role + ''';';
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