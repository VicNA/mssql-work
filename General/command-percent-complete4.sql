--EXEC sp_who2

select session_id
     , start_time
     , command
     , DBName = DB_NAME(database_id)
     , status
     , percent_complete
     , wait_time
     , [wait_time(min)] = wait_time/1000./60.
     , estimated_completion_time
     , [estimated_completion_time(min)] = estimated_completion_time/1000./60.
from sys.dm_exec_requests
where command like '%DBCC%' or command like '%RESTORE%' or command like '%BACKUP%'
--where command = 'UNKNOWN TOKEN'
--where session_id = 222
--where database_id = 8
order by total_elapsed_time desc


--select session_id
--     , command
--     , a.text AS Query
--     , start_time
--     , percent_complete
--     , dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time
--FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
--where command like '%DBCC%' or command like '%RESTORE%' or command like '%BACKUP%'
----where command = 'UNKNOWN TOKEN'
----where session_id = 222
--order by start_time

--kill 92

--select *
--from sys.sysprocesses
--where nt_username = 'viktor-n'