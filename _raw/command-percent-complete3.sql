SELECT spid
     , sp.[status]
     , loginame [Login]
     , hostname
     , blocked BlkBy
     , sd.name DBName 
     , cmd Command
     , cpu CPUTime
     , physical_io DiskIO
     , last_batch LastBatch
     , [program_name] ProgramName   
FROM sysprocesses sp 
     LEFT JOIN sysdatabases sd ON sp.dbid = sd.dbid
ORDER BY spid 