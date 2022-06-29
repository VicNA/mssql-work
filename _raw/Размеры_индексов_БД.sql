use TranscryptDataStorage;
--use tcryptapi_new;
--use roaming;
--use roaming_mark;
--use updateservice;
go

SELECT [TableName]     = OBJECT_NAME(i.object_id)
     , [IndexName]     = ISNULL(i.name, 'HEAP')
     , [IndexID]       = i.index_id
     , [Indexsize(KB)] = SUM(a.used_pages) * 8
     , [Indexsize]     = CASE 
                             WHEN (SUM(a.used_pages) * 8) / 1024 / 1024 > 0 
							     THEN CONVERT(varchar(20), CONVERT(decimal(10,2), (SUM(a.used_pages) * 8) / 1024. / 1024.)) + ' Gb'
                             WHEN (SUM(a.used_pages) * 8) / 1024 > 0
                                 THEN CONVERT(varchar(20), CONVERT(decimal(10,2), (SUM(a.used_pages) * 8) / 1024.)) + ' Mb'
                             ELSE CONVERT(varchar(20), CONVERT(decimal(10,2), (SUM(a.used_pages) * 8))) + ' Kb'
                         END
FROM sys.indexes i
    JOIN sys.partitions p       ON p.object_id = i.object_id AND p.index_id = i.index_id
    JOIN sys.allocation_units a ON a.container_id = p.partition_id
GROUP BY i.OBJECT_ID, i.index_id, i.name
ORDER BY [Indexsize(KB)] desc