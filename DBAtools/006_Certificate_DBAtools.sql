/*===================================================*/
DECLARE @certName  NVARCHAR(20)  = 'sysadmincert'
      , @pwdtools  NVARCHAR(MAX) = '00YqQmcqqLiFrMEcKvkC'
      , @pwdmaster NVARCHAR(MAX) = '4rbdmW409GHh7SNQuyHO'
      , @pwdmsdb   NVARCHAR(MAX) = 'fa8ZCXZHZPitADYn76PF'
      , @logincert NVARCHAR(20)  = 'sqladmincert'
      , @fileCert  NVARCHAR(255) = 'C:\ProgramAdmin\sysadmincert'
      , @debug     NVARCHAR(1)   = 'y'
      ;
/*===================================================*/

DECLARE @cursor   CURSOR
      , @objName  NVARCHAR(50)
      , @command  NVARCHAR(MAX)
      , @stmt     NVARCHAR(MAX)
      , @usedb    NVARCHAR(20)
      , @flag     BIT
      , @newline1 NVARCHAR(2)
      , @newline2 NVARCHAR(4)
      , @newline3 NVARCHAR(8)
      ;

SELECT @command  = ''
     , @stmt     = ''
     , @newline1 = NCHAR(13) + NCHAR(10)
     , @newline2 = @newline1 + @newline1
     , @newline3 = @newline1 + SPACE(4)
     ;
/*===================================================*/

DECLARE @listObject TABLE ( objName NVARCHAR(50) );

SET NOCOUNT ON;

INSERT @listObject
VALUES ('CommandExecute')
     , ('DatabaseBackup')
     , ('IndexOptimize')
     , ('usp_JobSwitch')
     ;


BEGIN TRY
    
    USE DBAtools;

    SELECT @usedb = 'USE DBAtools;'
         , @stmt  = @usedb;
    

    /* DROP CERTIFICATE and SIGNATURE */

    IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = @certName)
    BEGIN
        SET @cursor = CURSOR 
        LOCAL FORWARD_ONLY FAST_FORWARD 
        FOR
            SELECT o.name
            FROM sys.crypt_properties cp
                JOIN sys.objects o      ON o.object_id = cp.major_id
                JOIN sys.certificates c ON c.thumbprint = cp.thumbprint
            WHERE c.name = @certName;

        OPEN @cursor  
  
        FETCH NEXT FROM @cursor   
        INTO @objName
  
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @stmt += CASE WHEN @stmt LIKE '%DROP SIGNATURE%' THEN @newline1
                                 ELSE @newline2
                            END
                 , @stmt += 'DROP SIGNATURE FROM dbo.' + @objName + ' BY CERTIFICATE ' + @certName + ';';

            FETCH NEXT FROM @cursor   
            INTO @objName
        END

        CLOSE @cursor;  
        DEALLOCATE @cursor;

        SELECT @stmt += @newline2 
             , @stmt += 'DROP CERTIFICATE ' + @certName + ';';
    END
    

    /* CREATE CERTIFICATE and ADD SIGNATURE */

    SELECT @stmt += @newline2
            , @stmt += 'CREATE CERTIFICATE [' + @certName + ']'
            + @newline3 + 'ENCRYPTION BY PASSWORD = ''' + @pwdtools + ''''
            + @newline3 + 'WITH SUBJECT = ''sysadmin privilege'';';

    SET @cursor = CURSOR 
    LOCAL FORWARD_ONLY FAST_FORWARD
    FOR
        SELECT name
        FROM sys.objects
        WHERE name IN (SELECT objName FROM @listObject);

    OPEN @cursor  
  
    FETCH NEXT FROM @cursor   
    INTO @objName
  
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @stmt += CASE WHEN @stmt LIKE '%ADD SIGNATURE%' THEN @newline1
                                ELSE @newline2
                        END
                , @stmt += 'ADD SIGNATURE TO ' + @objName + ' BY CERTIFICATE ' + @certName + ' WITH PASSWORD = ''' + @pwdtools + ''';';

        FETCH NEXT FROM @cursor   
        INTO @objName
    END

    CLOSE @cursor;  
    DEALLOCATE @cursor;
    
    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @stmt ELSE @stmt END;

    /* BACKUP CERTIFICATE */

    SELECT @usedb = 'USE master;'
         , @stmt  = @usedb;

    SELECT @stmt += @newline2
         , @stmt += 'EXEC sp_configure ''show advanced option'', 1;' + @newline1
         , @stmt += 'RECONFIGURE WITH OVERRIDE;' + @newline1
         , @stmt += 'EXEC sp_configure ''xp_cmdshell'', 1;' + @newline1
         , @stmt += 'RECONFIGURE;'
         , @stmt += @newline2
         , @stmt += 'EXEC xp_cmdshell ''if exist "' + @fileCert + '.*" ( del ' + @fileCert + '.* )'', no_output;'
         , @stmt += @newline2
         , @stmt += 'USE DBAtools;'
         , @stmt += @newline2
         , @stmt += 'BACKUP CERTIFICATE ' + @certName + ' TO FILE = ''' + @fileCert + '.cer'''
	        + @newline3 + 'WITH PRIVATE KEY (FILE = ''' + @fileCert + '.pvk'' ,'
	        + @newline3 + 'ENCRYPTION BY PASSWORD = ''wpl22mkJr5GwuBpYMAQF'','
            + @newline3 + 'DECRYPTION BY PASSWORD = ''' + @pwdtools + ''');';

    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @stmt ELSE @stmt END;


    /* CREATE CERTIFICATE from file to database master */

    USE master;

    SELECT @usedb = 'USE master;'
         , @stmt  = @usedb;

    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @logincert and type = 'C')
    BEGIN
        SELECT @stmt += @newline2
             , @stmt += 'DROP LOGIN ' + @logincert + ';';
    END

    IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = @certName)
    BEGIN
        SELECT @stmt += @newline2
             , @stmt += 'DROP CERTIFICATE ' + @certName + ';';
    END

    SELECT @stmt += @newline2
         , @stmt += 'CREATE CERTIFICATE ' + @certName + ' FROM FILE = ''' + @fileCert + '.cer'''
	        + @newline3 + 'WITH PRIVATE KEY (FILE = ''' + @fileCert + '.pvk'' ,'
	        + @newline3 + 'DECRYPTION BY PASSWORD = ''wpl22mkJr5GwuBpYMAQF'','
            + @newline3 + 'ENCRYPTION BY PASSWORD = ''' + @pwdmaster + ''');';

    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @stmt ELSE @stmt END;
    
    /* CREATE CERTIFICATE from file to database msdb */

    USE msdb;

    SELECT @usedb = 'USE msdb;'
         , @stmt  = @usedb;

    IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = @certName)
    BEGIN
        SET @cursor = CURSOR 
        LOCAL FORWARD_ONLY FAST_FORWARD 
        FOR
            SELECT o.name
            FROM sys.crypt_properties cp
                JOIN sys.objects o      ON o.object_id = cp.major_id
                JOIN sys.certificates c ON c.thumbprint = cp.thumbprint
            WHERE c.name = @certName;

        OPEN @cursor  
  
        FETCH NEXT FROM @cursor   
        INTO @objName
  
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @stmt += CASE WHEN @stmt LIKE '%DROP SIGNATURE%' THEN @newline1
                                 ELSE @newline2
                            END
                 , @stmt += 'DROP SIGNATURE FROM dbo.' + @objName + ' BY CERTIFICATE ' + @certName + ';';

            FETCH NEXT FROM @cursor   
            INTO @objName
        END

        CLOSE @cursor;  
        DEALLOCATE @cursor;

        SELECT @stmt += @newline2
             , @stmt += 'DROP CERTIFICATE ' + @certName + ';';
    END

    --SELECT @stmt += @newline2
    --     , @stmt += 'CREATE CERTIFICATE ' + @certName + ' FROM FILE = ''' + @fileCert + '.cer'''
	   --     + @newline3 + 'WITH PRIVATE KEY (FILE = ''' + @fileCert + '.pvk'' ,'
	   --     + @newline3 + 'DECRYPTION BY PASSWORD = ''wpl22mkJr5GwuBpYMAQF'','
    --        + @newline3 + 'ENCRYPTION BY PASSWORD = ''' + @pwdmsdb + ''');';

    --SET @cursor = CURSOR 
    --LOCAL FORWARD_ONLY FAST_FORWARD
    --FOR
    --    SELECT name
    --    FROM sys.objects
    --    WHERE name IN ('sp_update_job');

    --OPEN @cursor  
  
    --FETCH NEXT FROM @cursor   
    --INTO @objName
  
    --WHILE @@FETCH_STATUS = 0
    --BEGIN
    --    SELECT @stmt += CASE WHEN @stmt LIKE '%ADD SIGNATURE%' THEN @newline1
    --                            ELSE @newline2
    --                    END
    --            , @stmt += 'ADD SIGNATURE TO ' + @objName + ' BY CERTIFICATE ' + @certName + ' WITH PASSWORD = ''' + @pwdmsdb + ''';';

    --    FETCH NEXT FROM @cursor   
    --    INTO @objName
    --END

    --CLOSE @cursor;  
    --DEALLOCATE @cursor;

    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @stmt ELSE @stmt END;

    
    /* Delete file certificate on system */

    SELECT @usedb = 'USE master;'
         , @stmt  = @usedb;

    SELECT @stmt += @newline2
         , @stmt += 'EXEC xp_cmdshell ''del ' + @fileCert + '.*'', no_output;'
         , @stmt += @newline2
         , @stmt += 'EXEC sp_configure ''xp_cmdshell'', 0;' + @newline1
         , @stmt += 'RECONFIGURE;' + @newline1
         , @stmt += 'EXEC sp_configure ''show advanced option'', 0;' + @newline1
         , @stmt += 'RECONFIGURE WITH OVERRIDE;'
         , @stmt += @newline2
         , @stmt += 'CREATE LOGIN ' + @logincert + ' FROM CERTIFICATE ' + @certName + ';'
         , @stmt += @newline2;
    
    IF SERVERPROPERTY('ProductMajorVersion') > 10
        SET @stmt += 'ALTER SERVER ROLE sysadmin ADD MEMBER ' + @logincert + ';';
    ELSE
        SET @stmt += 'EXEC sp_addsrvrolemember @loginame = ''' + @logincert + ''', @rolename = N''sysadmin'';';

    SET @command += CASE WHEN LEN(@command) > 0 THEN @newline2 + @stmt ELSE @stmt END;

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