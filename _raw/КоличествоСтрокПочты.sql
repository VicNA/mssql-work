SELECT o.name, p.[rows]
FROM msdb.sys.objects o
JOIN msdb.sys.partitions p ON o.[object_id] = p.[object_id]
WHERE o.name LIKE 'sysmail%'
    AND o.[type] = 'U'
    AND p.[rows] > 0


--select *
--from msdb.dbo.sysmail_mailitems

----select *
----from msdb.dbo.sysmail_log


--USE msdb;

--DECLARE @DateBefore DATETIME 
--SET @DateBefore = DATEADD(DAY, -7, GETDATE())

--EXEC sysmail_delete_mailitems_sp @sent_before = @DateBefore
--EXEC sysmail_delete_log_sp @logged_before = @DateBefore