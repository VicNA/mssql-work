/* 
-- Original logic from http://www.sqlsoldier.com/wp/sqlserver/transferring-logins-to-a-database-mirror

-- Sync Logins to AlwaysOn Replicas
-- Inputs: @PartnerServer -- Target Instance (InstName or Machine\NamedInst or Instname,port)
-- Output: All Statements to create logins with SID and Password for both Windows and SQL logins
	      Will also add logins to server roles

-- Person executing this must be sysadmin
-- Ad Hoc Distributed Queries must be enabled for this to work without setting up a linked server
*/

-- Turn on Ad Hoc Distributed Queries so we donТt have to set up a linked server
sp_configure 'show advanced options', 1
GO
reconfigure with override
go
sp_configure 'Ad Hoc Distributed Queries', 1
GO
reconfigure with override
go

Use master;
Go

Declare @MaxID int
      , @CurrID int
      , @PartnerServer sysname
      , @SQL nvarchar(max)
      , @LoginName sysname
      , @IsDisabled int
      , @Type char(1)
      , @SID varbinary(85)
      , @SIDString nvarchar(100)
      , @PasswordHash varbinary(256)
      , @PasswordHashString nvarchar(300)
      , @RoleName sysname
      , @Machine sysname
      , @PermState nvarchar(60)
      , @PermName sysname
      , @Class tinyint
      , @MajorID int
      , @ErrNumber int
      , @ErrSeverity int
      , @ErrState int
      , @ErrProcedure sysname
      , @ErrLine int
      , @ErrMsg nvarchar(2048);
 
SET @PartnerServer = 'InstanceName' -- подставл€ем им€ сервера другого узла

Declare @Logins Table (
      LoginID int identity(1, 1) not null primary key
    , [Name] sysname not null
    , [SID] varbinary(85) not null
    , IsDisabled int not null
    , [Type] char(1) not null
    , PasswordHash varbinary(256) null
    );

Declare @Roles Table (
      RoleID int identity(1, 1) not null primary key
    , RoleName sysname not null
    , LoginName sysname not null
    );

Declare @Perms Table (
      PermID int identity(1, 1) not null primary key
    , LoginName sysname not null
    , PermState nvarchar(60) not null
    , PermName sysname not null
    , Class tinyint not null
    , ClassDesc nvarchar(60) not null
    , MajorID int not null
    , SubLoginName sysname null
    , SubEndPointName sysname null
    ); 

SET NOCOUNT ON;

If CharIndex('\', @PartnerServer) > 0 -- Check for Named Instance
    Set @Machine = LEFT(@PartnerServer, CharIndex('\', @PartnerServer) - 1);
Else If CharIndex(',', @PartnerServer) > 0 -- Check for Instance with port in connection string
    Set @Machine = LEFT(@PartnerServer, CharIndex(',', @PartnerServer) - 1);
Else
    Set @Machine = @PartnerServer;


-- Get all Windows logins from principal server using OPENROWSET and Windows Authentication
set @SQL = '
Select P.name, P.sid, P.is_disabled, P.type, L.password_hash
From master.sys.server_principals P
    Left Join master.sys.sql_logins L On L.principal_id = P.principal_id
Where P.type In (''''U'''', ''''G'''', ''''S'''') And P.name <> ''''sa''''
    And P.name Not Like ''''##%'''' And CharIndex(''''' + @Machine + '\'''', P.name) = 0
';

Set @SQL = 'Select a.* From OPENROWSET (''SQLNCLI'', ''Server=' + @PartnerServer + ';Trusted_Connection=yes;'', ''' + @SQL + ''') as a;';

--print char(13) + @SQL + char(13);

Insert Into @Logins (Name, SID, IsDisabled, Type, PasswordHash)
Exec sp_executesql @SQL;


-- Get all roles from principal server using OPENROWSET and Windows Authentication
set @SQL = '
Select RoleP.name as RoleName, LoginP.name as LoginName
From master.sys.server_role_members RM
    Inner Join master.sys.server_principals RoleP  On RoleP.principal_id = RM.role_principal_id
    Inner Join master.sys.server_principals LoginP On LoginP.principal_id = RM.member_principal_id
Where LoginP.type In (''''U'''', ''''G'''', ''''S'''') And LoginP.name <> ''''sa''''
    And LoginP.name Not Like ''''##%'''' And RoleP.type = ''''R''''
    And CharIndex(''''' + @Machine + '\'''', LoginP.name) = 0
';

Set @SQL = 'Select a.* From OPENROWSET (''SQLNCLI'', ''Server=' + @PartnerServer + ';Trusted_Connection=yes;'', ''' + @SQL + ''') as a;';

--print @SQL + char(13);

Insert Into @Roles (RoleName, LoginName)
Exec sp_executesql @SQL;


-- Get all explicitly granted permissions using OPENROWSET and Windows Authentication
set @SQL = '
Select P.name Collate database_default, SP.state_desc, SP.permission_name, SP.class, SP.class_desc, SP.major_id
     , SubP.name Collate database_default, SubEP.name Collate database_default
From master.sys.server_principals P
    Inner Join master.sys.server_permissions SP On SP.grantee_principal_id = P.principal_id
    Left Join master.sys.server_principals SubP On SubP.principal_id = SP.major_id And SP.class = 101
    Left Join master.sys.endpoints SubEP        On SubEP.endpoint_id = SP.major_id And SP.class = 105
Where P.type In (''''U'''', ''''G'''', ''''S'''') And P.name <> ''''sa'''' And P.name Not Like ''''##%''''
And CharIndex(''''' + @Machine + '\'''', P.name) = 0
';

Set @SQL = 'Select a.* From OPENROWSET (''SQLNCLI'', ''Server=' + @PartnerServer + ';Trusted_Connection=yes;'', ''' + @SQL + ''') as a;';

--print @SQL + char(13);

Insert Into @Perms (LoginName, PermState, PermName, Class, ClassDesc, MajorID, SubLoginName, SubEndPointName)
Exec sp_executesql @SQL;

print '';

Select @MaxID = Max(LoginID), @CurrID = 1
From @Logins;

While @CurrID <= @MaxID
Begin
    Select @LoginName = Name
         , @IsDisabled = IsDisabled
         , @Type = [Type]
         , @SID = [SID]
         , @PasswordHash = PasswordHash
    From @Logins
    Where LoginID = @CurrID;

    If Not Exists (Select 1 From sys.server_principals Where name = @LoginName)
    Begin
        Set @SQL = 'Create Login ' + quotename(@LoginName)
        
        If @Type In ('U', 'G')
            Set @SQL = @SQL + ' From Windows;'
        Else
        Begin
            Set @PasswordHashString = '0x' +
                Cast('' As XML).value('xs:hexBinary(sql:variable(''@PasswordHash''))', 'nvarchar(300)');

            Set @SQL = @SQL + ' With Password = ' + @PasswordHashString + ' HASHED, ';
            
            Set @SIDString = '0x' +
                Cast('' As XML).value('xs:hexBinary(sql:variable(''@SID''))', 'nvarchar(100)');
            
            Set @SQL = @SQL + 'SID = ' + @SIDString + ';';
        End

        Print @SQL;
        
        If @IsDisabled = 1
        Begin
            Set @SQL = 'Alter Login ' + quotename(@LoginName) + ' Disable;'
            
            Print @SQL;
        End
    End

    Set @CurrID = @CurrID + 1;
End

Select @MaxID = Max(RoleID), @CurrID = 1
From @Roles;

While @CurrID <= @MaxID
Begin
    Select @LoginName = LoginName
         , @RoleName = RoleName
    From @Roles
    Where RoleID = @CurrID;

    If Not Exists (
            Select 1 
            From sys.server_role_members RM
                Inner Join sys.server_principals RoleP  On RoleP.principal_id = RM.role_principal_id
                Inner Join sys.server_principals LoginP On LoginP.principal_id = RM.member_principal_id
            Where LoginP.type In ('U', 'G', 'S') And RoleP.type = 'R' And RoleP.name = @RoleName
                And LoginP.name = @LoginName
            )
    Begin
        Print 'Exec sp_addsrvrolemember @rolename = ''' + @RoleName + ''', @loginame = ''' + @LoginName + ''';';
    End

    Set @CurrID = @CurrID + 1;
End

Select @MaxID = Max(PermID), @CurrID = 1
From @Perms;

While @CurrID <= @MaxID
Begin
    Select @PermState = PermState
         , @PermName = PermName
         , @Class = Class
         , @LoginName = LoginName
         , @MajorID = MajorID
         , @SQL = PermState + space(1) + PermName + SPACE(1) + Case Class 
            When 101 Then 'On Login::' + QUOTENAME(SubLoginName)
            When 105 Then 'On ' + ClassDesc + '::' + QUOTENAME(SubEndPointName)
            Else '' End + ' To ' + QUOTENAME(LoginName) + ';'
    From @Perms
    Where PermID = @CurrID;
    
    If Not Exists (
            Select 1 
            From sys.server_principals P
                Inner Join sys.server_permissions SP On SP.grantee_principal_id = P.principal_id
            Where SP.state_desc = @PermState And SP.permission_name = @PermName
                And SP.class = @Class And P.name = @LoginName And SP.major_id = @MajorID
            )
    Begin
        Print @SQL;
    End

    Set @CurrID = @CurrID + 1;
End

print '';

SET NOCOUNT OFF;
GO

-- Turn off Ad Hoc Distributed Queries
sp_configure 'Ad Hoc Distributed Queries', 0
GO
reconfigure with override
go
sp_configure 'show advanced options', 0
GO
reconfigure with override
go