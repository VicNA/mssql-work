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
      @login	= 'sqljob'
	, @password	= ''
	, @sid     	= ''
	, @database	= 'DBAtools'
	, @role	    = 'job_executor'
	, @debug	= 'Y'
/*===============================================*/

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

IF EXISTS (SELECT 1 FROM sys.sysdatabases WHERE name = @database)
BEGIN

    USE master;

    SET @usedb = 'USE master;';
    
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
        Добавляем логин @login в серверную роль @role, если роль существует и логин еще не является членом этой роли 
    */
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @role AND type = 'R')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.server_principals r
                            JOIN sys.server_role_members m ON m.role_principal_id = r.principal_id
                            JOIN sys.server_principals l   ON l.principal_id = m.member_principal_id
                       WHERE l.name = @login and r.name = @role)
        BEGIN
            SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
				+ 'ALTER SERVER ROLE [' + @role + '] ADD MEMBER [' + @login + '];';
        END
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