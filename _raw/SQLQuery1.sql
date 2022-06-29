 --System Memory Usage

SELECT EventTime
     , [Type]               = record.value('(/Record/ResourceMonitor/Notification)[1]', 'varchar(max)')
     , [IndicatorsProcess]  = record.value('(/Record/ResourceMonitor/IndicatorsProcess)[1]', 'int')
     , [IndicatorsSystem]   = record.value('(/Record/ResourceMonitor/IndicatorsSystem)[1]', 'int')
     , [Avail Phys Mem, Kb] = record.value('(/Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint')
     , [Avail VAS, Kb]      = record.value('(/Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint')
FROM (
    SELECT EventTime = DATEADD (ss, (-1 * ((cpu_ticks / CONVERT (float, ( cpu_ticks / ms_ticks ))) - [timestamp])/1000), GETDATE())
         , record    = CONVERT (xml, record)
    FROM sys.dm_os_ring_buffers
    CROSS JOIN sys.dm_os_sys_info
    WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
    ) AS tab
ORDER BY EventTime DESC; 

--SELECT ring_buffer_type, COUNT(*) AS [Events]
--FROM sys.dm_os_ring_buffers
--GROUP BY ring_buffer_type
--ORDER BY ring_buffer_type