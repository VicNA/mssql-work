/*
********************************************
*********** ИНДЕКСЫ И СТАТИСТИКА ***********
********************************************
*/

/*
    Task:
        DBA: Database index optimize
    Step 1:
        Index optimization
*/

-- Версия для экземпляра с кластером --

USE DBAtools;

EXECUTE dbo.IndexOptimize
  @AvailabilityGroups = 'CryptAG'
, @FragmentationLevel1 = 15
, @UpdateStatistics = 'ALL'
, @OnlyModifiedStatistics = 'Y'
, @LogToTable = 'Y'

-- Версия для обычного экземпляра --

USE DBAtools;

EXECUTE dbo.IndexOptimize
  @Databases = 'USER_DATABASES'
, @FragmentationLevel1 = 15
, @UpdateStatistics = 'ALL'
, @OnlyModifiedStatistics = 'Y'
, @LogToTable = 'Y'


/*
    Task:
        DBA: Update statistics
    Step 1:
        Statistics update
*/

-- Версия для экземпляра с кластером --

USE DBAtools;

EXECUTE dbo.IndexOptimize
  @AvailabilityGroups = 'CryptAG'
, @FragmentationLow = NULL
, @FragmentationMedium = NULL
, @FragmentationHigh = NULL
, @UpdateStatistics = 'ALL'
, @OnlyModifiedStatistics = 'Y'
, @LogToTable = 'Y'

-- Версия для обычного экземпляра --

USE DBAtools;

EXECUTE dbo.IndexOptimize
  @Databases = 'USER_DATABASES'
, @FragmentationLow = NULL
, @FragmentationMedium = NULL
, @FragmentationHigh = NULL
, @UpdateStatistics = 'ALL'
, @OnlyModifiedStatistics = 'Y'
, @LogToTable = 'Y'


/*
    Task:
        DBA: SystemDB index optimize
    Step 1:
        Index optimization
*/

USE DBAtools;

EXECUTE dbo.IndexOptimize
  @Databases = 'SYSTEM_DATABASES'
, @FragmentationLevel1 = 15
, @UpdateStatistics = 'ALL'
, @OnlyModifiedStatistics = 'Y'
, @LogToTable = 'Y'