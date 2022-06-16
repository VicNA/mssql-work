SELECT session_id
     , start_time
     , command
     , DBName = DB_NAME(database_id)
     , status
     , percent_complete
     , wait_time
     , [wait_time(min)] = wait_time/1000./60.
     , estimated_completion_time
     , [estimated_completion_time(min)] = estimated_completion_time/1000./60.
FROM sys.dm_exec_requests
WHERE command LIKE '%DBCC%' 
     OR command LIKE '%RESTORE%' 
     OR command LIKE '%BACKUP%'