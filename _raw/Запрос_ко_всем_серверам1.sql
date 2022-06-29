DECLARE @serverRole NVARCHAR(20)  = 'monitoringsql'
      , @command    NVARCHAR(MAX)
      , @debug      NVARCHAR(1)   = 'Y'
      ;

SELECT @command = '
USE [master];

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = ''' + @serverRole + ''' AND type = ''R'')
BEGIN
    SELECT * FROM sys.server_principals WHERE name = ''' + @serverRole + ''' AND type = ''R'';

    IF ''Y'' = ''' + @debug + '''
        DROP SERVER ROLE [' + @serverRole + '];
END
'

EXEC sp_executesql @command;
--PRINT @command;
--EXEC sp_MSforeachdb @command 

--IF NOT EXISTS (SELECT 1 FROM sys.server_principals pr
--                    JOIN sys.server_permissions pe ON pr.principal_id = pe.grantee_principal_id
--                WHERE pr.name = @serverRole1 AND pe.permission_name = 'VIEW ANY DATABASE')
--        BEGIN
--            SELECT @command += CASE WHEN LEN(@command) > 0 THEN @newline2 ELSE @usedb + @newline2 END
--                 , @command += 'GRANT VIEW ANY DATABASE TO [' + @serverRole1 + '];';
--        END
