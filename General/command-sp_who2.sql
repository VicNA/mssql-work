SELECT [SPID]        = spid
     , [Status]      = sp.status
     , [Login]       = loginame
     , [Hostname]    = hostname
     , [BlkBy]       = blocked
     , [DBName]      = sd.name 
     , [Command]     = cmd
     , [CPUTime]     = cpu
     , [DiskIO]      = physical_io
     , [LastBatch]   = last_batch
     , [ProgramName] = program_name
FROM sysprocesses sp 
     LEFT JOIN sysdatabases sd ON sp.dbid = sd.dbid
ORDER BY spid 