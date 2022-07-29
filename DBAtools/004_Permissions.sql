/*====================================================*/
DECLARE @login NVARCHAR(20) = 'sqljob'
      , @debug NVARCHAR(1)  = 'Y'
      ;
/*====================================================*/

/*====================================================*/
DECLARE @user         NVARCHAR(20)
      , @serverRole   NVARCHAR(20)
      , @databaseRole NVARCHAR(20)
      ;

SELECT @user         = @login
     , @serverRole   = 'job_executor'
     , @databaseRole = @serverRole
     ;
/*====================================================*/

DECLARE @command  NVARCHAR(MAX)
      , @usedb    NVARCHAR(20)
      , @version  INT
      , @newline1 NVARCHAR(2)
      , @newline2 NVARCHAR(4)
      ;

SELECT @command  = ''
     , @version  = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'))
     , @newline1 = NCHAR(13) + NCHAR(10)
     , @newline2 = @newline1 + @newline1
     ;

/* 
    Для выполнения задач по обслуживанию БД вцелом необходимы права:
    - VIEW ANY DATABASE

    Для выполнения задач конкретно проверок целостности БД:
    - VIEW SERVER STATE
    - VIEW DATABASE STATE (DBAtools)
*/
BEGIN TRY
    
    USE master;

    SET @usedb = 'USE master;';

    IF @version > 10
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @serverRole AND type = 'R')
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.server_principals pr
                                JOIN sys.server_permissions pe ON pr.principal_id = pe.grantee_principal_id
                           WHERE pr.name = @serverRole AND pe.permission_name = 'VIEW ANY DATABASE')
            BEGIN
                SELECT @command += @usedb + @newline2
                     , @command += 'GRANT VIEW ANY DATABASE TO [' + @serverRole + '];';
            END
        END

        IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @serverRole AND type = 'R')
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.server_principals pr
                                JOIN sys.server_permissions pe ON pr.principal_id = pe.grantee_principal_id
                           WHERE pr.name = @serverRole AND pe.permission_name = 'VIEW SERVER STATE')
            BEGIN
                SELECT @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
                     , @command += 'GRANT VIEW SERVER STATE TO [' + @serverRole + '];';
            END
        END
    END
    ELSE
    BEGIN
        IF EXISTS(SELECT 1 FROM sys.server_principals WHERE name = @login AND type = 'S')
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.server_principals pr
                                JOIN sys.server_permissions pe ON pr.principal_id = pe.grantee_principal_id
                           WHERE pr.name = @login AND pe.permission_name = 'VIEW ANY DATABASE')
            BEGIN
                SELECT @command += @usedb + @newline2
                     , @command += 'GRANT VIEW ANY DATABASE TO [' + @login + '];';
            END

            IF NOT EXISTS (SELECT 1 FROM sys.server_principals pr
                                JOIN sys.server_permissions pe ON pr.principal_id = pe.grantee_principal_id
                           WHERE pr.name = @login AND pe.permission_name = 'VIEW SERVER STATE')
            BEGIN
                SELECT @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
                     , @command += 'GRANT VIEW SERVER STATE TO [' + @login + '];';
            END
        END
    END


    USE DBAtools;

    SET @usedb = 'USE DBAtools;';

    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @databaseRole and type = 'R')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.database_principals pr
                            JOIN DBAtools.sys.database_permissions per ON per.grantee_principal_id = pr.principal_id
                       WHERE pr.name = @databaseRole AND per.permission_name = 'VIEW DATABASE STATE')
        BEGIN
            SELECT @command += CASE WHEN @command LIKE '%' + @usedb + '%' THEN @newline2
                                    WHEN LEN(@command) = 0                THEN @usedb + @newline2
                                    ELSE @newline2 + @usedb + @newline2
                               END
                 , @command += 'GRANT VIEW DATABASE STATE TO [' + @databaseRole + '];';
        END
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

    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
END CATCH