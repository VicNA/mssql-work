/*
********************************************
*********** �������� ����������� ***********
********************************************
*/

/*
    Task:
        DBA: Database CHECKDB
    Step 1:
        Check database
*/

-- ������ ��� ���������� � ��������� --

USE DBAtools;

EXECUTE dbo.DatabaseIntegrityCheck 
  @Databases = 'roaming, roaming_mark, updateservice'
, @CheckCommands = 'CHECKDB'
, @AvailabilityGroupReplicas = 'PRIMARY'
, @LogToTable = 'Y'

-- ������ ��� �������� ���������� --

USE DBAtools;

EXECUTE DBAtools.dbo.DatabaseIntegrityCheck 
  @Databases = 'USER_DATABASES'
, @CheckCommands = 'CHECKDB'
, @LogToTable = 'Y'


/*
    Task:
        DBA: SystemDB CHECKDB
    Step 1:
        Check database
*/

USE DBAtools;

EXECUTE dbo.DatabaseIntegrityCheck 
  @Databases = 'SYSTEM_DATABASES'
, @CheckCommands = 'CHECKDB'
, @LogToTable = 'Y'