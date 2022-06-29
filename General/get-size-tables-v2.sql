USE tcryptapi_new;

SELECT [Database]      = DB_NAME()
     , [TableName]     = t.Name
     , [SchemaName]    = s.Name
     , [RowCounts]     = p.Rows
     , [TotalSpaceKB]  = SUM(a.total_pages) * 8
	 , [TotalSpace]    = CASE 
                             WHEN (SUM(a.total_pages) * 8) / 1024 / 1024 > 0 
							     THEN CONVERT(varchar(20), CONVERT(decimal(10,2), (SUM(a.total_pages) * 8) / 1024. / 1024.)) + ' Gb'
                             WHEN (SUM(a.total_pages) * 8) / 1024 > 0
                                 THEN CONVERT(varchar(20), CONVERT(decimal(10,2), (SUM(a.total_pages) * 8) / 1024.)) + ' Mb'
                             ELSE CONVERT(varchar(20), CONVERT(decimal(10,2), (SUM(a.total_pages) * 8))) + ' Kb'
                         END
     --, [UsedSpaceKB]   = SUM(a.used_pages) * 8
     , [UsedSpace]     = CASE 
                             WHEN (SUM(a.used_pages) * 8) / 1024 / 1024 > 0 
							     THEN CONVERT(varchar(20), CONVERT(decimal(10,2), (SUM(a.used_pages) * 8) / 1024. / 1024.)) + ' Gb'
                             WHEN (SUM(a.used_pages) * 8) / 1024 > 0
                                 THEN CONVERT(varchar(20), CONVERT(decimal(10,2), (SUM(a.used_pages) * 8) / 1024.)) + ' Mb'
                             ELSE CONVERT(varchar(20), CONVERT(decimal(10,2), (SUM(a.used_pages) * 8))) + ' Kb'
                         END
     --, [UnusedSpaceKB] = (SUM(a.total_pages) - SUM(a.used_pages)) * 8
     , [UnusedSpace]   = CASE 
                             WHEN ((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024 / 1024 > 0 
							     THEN CONVERT(varchar(20), CONVERT(decimal(10,2), ((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024. / 1024.)) + ' Gb'
                             WHEN ((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024 > 0
                                 THEN CONVERT(varchar(20), CONVERT(decimal(10,2), ((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.)) + ' Mb'
                             ELSE CONVERT(varchar(20), CONVERT(decimal(10,2), ((SUM(a.total_pages) - SUM(a.used_pages)) * 8))) + ' Kb'
                         END
FROM sys.tables t
    JOIN sys.indexes i            ON t.object_id = i.object_id
    JOIN sys.partitions p         ON i.object_id = p.object_id AND i.index_id = p.index_id
    JOIN sys.allocation_units a   ON p.partition_id = a.container_id
    LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0 AND i.object_id > 255
GROUP BY t.Name, s.Name, p.Rows
ORDER BY TotalSpaceKB desc;